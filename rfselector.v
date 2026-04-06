// ============================================================
// rfselector.v  (Q1.7 version)
// Receptive Field Selector for LeNet-5 Hardware Accelerator
//
// Extracts 5x5 receptive field patches from a feature map
// stored in BRAM, one element per cycle (serial output).
//
// Data format : Q1.7 signed fixed-point (8-bit)
// BRAM type   : Xilinx Simple Dual-Port, synchronous read,
//               1-cycle read latency
// Padding     : Zero-padding (configurable via PADDING param)
//
// Inner loop order: ch_idx fastest, then kj, then ki
// (matches convunit accumulation order in convlayer)
//
// Instantiation:
//   Conv1: IMG_W=101, IMG_H=40,  PADDING=2, IN_CHANNELS=1
//   Conv2: IMG_W=50,  IMG_H=20,  PADDING=0, IN_CHANNELS=6
//
// Output behaviour:
//   - patch_valid pulses high with each valid patch element
//   - patch_done  pulses high after all KERNEL*KERNEL*IN_CH
//                 elements of one output position are sent
//   - next_patch  must be pulsed by caller to advance position
//   - all_done    pulses when all OUT_H*OUT_W positions done
// ============================================================

module rfselector #(
    parameter IMG_W      = 101, // 50 for L2
    parameter IMG_H      = 40,  // 20 for L2
    parameter IN_CHANNELS= 1,   // 6 for L2
    parameter PADDING    = 2,   // 0 for L2
    parameter KERNEL     = 5,
    parameter DATA_WIDTH = 8,    // Q1.7
    parameter ADDR_WIDTH = $clog2(IMG_W * IMG_H * IN_CHANNELS),          // 12 for L1, 13 for L2
    parameter OUT_W      = IMG_W + PADDING*2 - KERNEL + 1,               // 101 for L1, 46 for L2
    parameter OUT_H      = IMG_H + PADDING*2 - KERNEL + 1,               // 40 for L1, 16 for L2
    parameter OUT_ROW_W  = $clog2(OUT_H),                                // 6 for L1, 5 for L2
    parameter OUT_COL_W  = $clog2(OUT_W),                                // 7 for L1, 6 for L2
    parameter CH_W       = (IN_CHANNELS > 1) ? $clog2(IN_CHANNELS) : 1   // 1 for L1, 4 for L2
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire        next_patch,

    // BRAM read port
    // Address layout: ch * IMG_H * IMG_W + row * IMG_W + col
    output reg  [ADDR_WIDTH-1:0]  bram_addr,
    input  wire [DATA_WIDTH-1:0]  bram_dout,

    // Patch output (serial)
    output reg  [DATA_WIDTH-1:0]  patch_data,
    output reg                    patch_valid,
    output reg                    patch_done,

    // Current output position
    output reg  [OUT_ROW_W-1:0]   out_row,
    output reg  [OUT_COL_W-1:0]   out_col,
    output reg  [CH_W-1:0]        channel,

    output reg                    all_done
);

// ============================================================
// Derived parameters
// ============================================================
localparam KW       = $clog2(KERNEL);
localparam IN_ROW_W = $clog2(IMG_H);
localparam IN_COL_W = $clog2(IMG_W);

// ============================================================
// State machine
// ============================================================
localparam IDLE      = 3'd0;
localparam LOAD_ADDR = 3'd1;  // Compute address, assert bram_en
localparam WAIT_READ = 3'd2;  // 1-cycle BRAM latency
localparam OUPUT     = 3'd3;  // Assert patch_valid, advance indices
localparam PATCH_END = 3'd4;  // Assert patch_done, wait for next_patch
localparam ALL_FINISH= 3'd5;

reg [2:0] state;

// ============================================================
// Kernel and channel indices
// ============================================================
reg [KW-1:0]   ki, kj;
reg [CH_W-1:0] ch_idx;

// Absolute pixel coordinates in original (unpadded) image
wire signed [7:0] abs_row = $signed({1'b0, out_row}) + $signed({1'b0, ki}) - 8'(PADDING); //-2 to 42  / 0 to 13
wire signed [7:0] abs_col = $signed({1'b0, out_col}) + $signed({1'b0, kj}) - 8'(PADDING); //-2 to 102 / 0 to 43

// Padding zone detection
wire is_pad = (abs_row < 0) || (abs_row >= IMG_H) || (abs_col < 0) || (abs_col >= IMG_W); // -2, -1, or 40, 41 / 101,102

// BRAM address for valid pixel
wire [ADDR_WIDTH-1:0] pixel_addr = is_pad ? '0 :
    ch_idx * (IMG_H * IMG_W) +                // channel offset
    ADDR_WIDTH'(unsigned'(abs_row)) * IMG_W + // row offset
    ADDR_WIDTH'(unsigned'(abs_col));          // column offset

// ============================================================
// FSM
// ============================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state       <= IDLE;
        out_row     <= 0; out_col  <= 0; channel <= 0;
        ki          <= 0; kj       <= 0; ch_idx  <= 0;
        bram_addr   <= 0; 
        patch_data  <= 0; patch_valid <= 0;
        patch_done  <= 0; all_done    <= 0;
    end else begin
        patch_valid <= 0;
        patch_done  <= 0;
        all_done    <= 0;

        case (state)

            IDLE: begin
                if (start) begin
                    out_row <= 0; out_col <= 0; channel <= 0;
                    ki <= 0;      kj <= 0;      ch_idx <= 0;
                    state <= LOAD_ADDR;
                end
            end

            LOAD_ADDR: begin
                if (is_pad) begin
                    state <= OUPUT;   // Skip BRAM, output zero
                end else begin
                    bram_addr <= pixel_addr;
                    state     <= WAIT_READ;
                end
            end

            WAIT_READ: begin
                state <= OUPUT;
            end

            OUPUT: begin
                patch_data  <= is_pad ? {DATA_WIDTH{1'b0}} : bram_dout;
                patch_valid <= 1;
                channel     <= ch_idx;

                // Advance: ch_idx (fastest) → kj → ki
                if (ch_idx == IN_CHANNELS - 1) begin // if last channel
                    ch_idx <= 0;
                    if (kj == KERNEL - 1) begin      // if last column of kernel
                        kj <= 0;
                        if (ki == KERNEL - 1) begin  // if last row of kernel
                            ki    <= 0;
                            state <= PATCH_END;      
                        end else begin               // if not last row of kernel
                            ki    <= ki + 1;         // go to the next row
                            state <= LOAD_ADDR;
                        end
                    end else begin                   // if not last column
                        kj    <= kj + 1;             // go to next column
                        state <= LOAD_ADDR;
                    end
                end else begin                        // if not last channel
                    ch_idx <= ch_idx + 1;             // go to next channel 
                    state  <= LOAD_ADDR;
                end
            end

            PATCH_END: begin
                patch_done <= 1;
                if (next_patch) begin // until received, stays in PATCH_END
                    channel <= 0;
                    // Advance output position: col → row → all done
                    if (out_col == OUT_W - 1) begin      // if in last column
                        out_col <= 0;
                        if (out_row == OUT_H - 1) begin  // if in last row
                            out_row <= 0;
                            state   <= ALL_FINISH;       // finish
                        end else begin                   // if not in last row
                            out_row <= out_row + 1;      // go to next row
                            state   <= LOAD_ADDR;
                        end
                    end else begin                       // if not in last column
                        out_col <= out_col + 1;          // go to next column
                        state   <= LOAD_ADDR;
                    end
                end
            end

            ALL_FINISH: begin
                all_done <= 1;
                if (start) begin
                    out_row <= 0; out_col <= 0; channel <= 0;
                    ki <= 0; kj <= 0; ch_idx <= 0;
                    state <= LOAD_ADDR;
                end
            end

            default: state <= IDLE;
        endcase
    end
end

endmodule
