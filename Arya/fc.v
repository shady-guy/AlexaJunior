module fc
  (
    input clk, input clr, input start,
    input signed [15:0] x [0:5],
    input signed [15:0] w [0:5][0:3],
    output reg signed [31:0] output_vec [0:3],
    output reg finished
  );
  
  reg signed [15:0] input_vec [0:5];
  reg signed [15:0] weights [0:5][0:3];
  reg signed [31:0] acc;
  reg [2:0] in_idx, out_idx;
  integer i, j;
  
  parameter idle=3'b000, init_out=3'b001, mac=3'b010, next_in=3'b011, store=3'b100, next_out=3'b101, done=3'b110; //FSM States
  reg [2:0] cur, nxt; //State
  
  always@(posedge clk or negedge clr) //FSM operation
    cur <= !clr ? idle : nxt;
  
  always@(*) begin //NSD
    case(cur)
      idle    : nxt = start ? init_out : idle;
      init_out: nxt = mac;
      mac     : nxt = next_in;
      next_in : nxt = in_idx<=5 ? mac : store;
      store   : nxt = next_out;
      next_out: nxt = out_idx<=3 ? init_out : done;
      done    : nxt = idle;
    endcase
  end
  
  always@(posedge clk or negedge clr) begin //OD
    if(!clr) begin
      finished<=1'b0;
      acc<=0;
      in_idx<=0;
      out_idx<=0;
      {output_vec[0], output_vec[1], output_vec[2], output_vec[3]} <= 128'b0;
      for(i=0;i<6;i=i+1) input_vec[i] <= 0;
      for(i=0;i<6;i=i+1) for(j=0;j<4;j=j+1) weights[i][j] <= 0;
    end
    else begin
      case(cur)
        idle    : begin 
          for (i=0;i<6;i=i+1) input_vec[i] <= x[i];
          for(i=0;i<6;i=i+1) for(j=0;j<4;j=j+1) weights[i][j] <= w[i][j]; 
          finished<=0; in_idx<=0; out_idx<=0; 
        end
        init_out: begin acc<=0; in_idx<=0; end
        mac     : begin acc <= acc + input_vec[in_idx]*weights[in_idx][out_idx]; in_idx<=in_idx+1; end
        store   : begin output_vec[out_idx]<=acc; out_idx<=out_idx+1; end
        done    : finished<=1;
      endcase
    end
  end

endmodule
