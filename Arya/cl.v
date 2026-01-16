module cl
  (
    input clk, input clr, input start,
    input signed [15:0] x [0:7],
    input signed [15:0] k [0:2],
    output reg signed [31:0] output_vec [0:5],
    output reg finished
  );
  
  reg signed [15:0] input_vec [0:7];
  reg signed [15:0] kernel [0:2];
  reg signed [31:0] acc;
  reg [2:0] k_idx, out_idx;
  integer i;
  
  parameter idle=3'b000, init=3'b001, mac=3'b010, next_k=3'b011, store=3'b100, next_out=3'b101, done=3'b110; //FSM States
  reg [2:0] cur, nxt; //State
  
  always@(posedge clk or negedge clr) //FSM operation
    cur <= !clr ? idle : nxt;
  
  always@(*) begin //NSD
    case(cur)
      idle    : nxt = start ? init : idle;
      init    : nxt = mac;
      mac     : nxt = next_k;
      next_k  : nxt = k_idx<3 ? mac : store;
      store   : nxt = next_out;
      next_out: nxt = out_idx<6 ? init : done;
      done    : nxt = idle;
    endcase
  end
  
  always@(posedge clk or negedge clr) begin //OD
    if(!clr) begin
      finished<=1'b0;
      acc<=0;
      k_idx<=0;
      out_idx<=0;
      {output_vec[0], output_vec[1], output_vec[2], output_vec[3], output_vec[4], output_vec[5]} <= 196'b0;
      for(i=0;i<8;i=i+1) input_vec[i] <= 0;
      for(i=0;i<3;i=i+1) kernel[i] <= 0;
    end
    else begin
      case(cur)
        idle    : begin 
          for(i=0;i<8;i=i+1) input_vec[i] <= x[i];
          for(i=0;i<3;i=i+1) kernel[i] <= k[i];
          finished<=0; out_idx<=0;
        end
        init    : begin acc<=0; k_idx<=0; end
        mac     : begin acc <= acc + input_vec[out_idx + k_idx] * kernel[k_idx]; k_idx<=k_idx+1; end
        store   : begin output_vec[out_idx]<=acc; out_idx<=out_idx+1; end
        done    : finished<=1;
      endcase
    end
  end
  
endmodule
