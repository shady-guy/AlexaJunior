module fc_layer (input clock , input reset , input reg signed [15:0] vector [0:5] , input reg signed [15:0] weights [0:5][0:3] , output reg done , output reg signed [31:0] result [0:3] ) ;
  
  reg [1:0] curr_state , next_state ;
  localparam [1:0] S0 = 2'd0 , S1 = 2'd1 , S2 = 2'd2 , S3 = 2'd3 ;
  reg [2:0] i , j ;
  reg signed [31:0] acc ;
  
  always @(posedge clock ) begin
    if(reset) curr_state <= S0 ;
    else curr_state <= next_state ;
  end 
  
  
  always @(*) begin
    next_state = curr_state ;
    case(curr_state) 
      S0 : next_state = S1 ;
      S1 : next_state = S2 ;
      S2 : if(j<3'd6) next_state = S1 ;
           else next_state = S3;
      S3 : if(i<3'd3) next_state = S1 ;
           else next_state = S0 ;
      default next_state = S0 ;
    endcase 
  end 
  
  
  always @(posedge clock) begin
    case(curr_state)
      S0 :begin i<= 3'd0 ;
                j<= 3'd0 ;
              done <= 1'b0 ;
        result[0] <= 32'd0 ;
        result[1] <= 32'd0 ;
        result[2] <= 32'd0 ;
        result[3] <= 32'd0 ;
        acc <= 32'd0 ;
      end
      S1 : if(j<3'd6) acc <= acc + vector[j] * weights [j][i] ;
      S2 : j <= j+ 1;
      S3 : begin 
        j <= 3'd0 ;
        i <= i+1 ;
        result[i] <= acc ;
        acc <= 32'd0 ;
        if(i==3'd3) done <= 1'b1 ;
      end
    endcase
  end
  
endmodule
