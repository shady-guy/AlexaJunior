module conv1d ( input clock , input start , input reg signed [15:0] input_vec [0:7] , input reg signed [15:0] kernel [0:2] ,  output reg signed[31:0]result[0:5] ,output reg done) ;
  reg signed [31:0] acc ;
  reg [2:0] i ;
  localparam [1:0] S0 = 2'd0 , S1 = 2'd1 , S2 = 2'd2 ;
  reg [1:0] curr_state , next_state ;
  
  
  always @(posedge clock) begin 
    if(!start) curr_state <= S0 ;
    else curr_state <= next_state ;
  end
  
  always @(*) begin 
    next_state = curr_state ;
    case(curr_state) 
      S0 : begin if(start) begin next_state = S1 ;
                         end
      end
      S1 : begin next_state = S2 ; end
            
     				 
       
      S2 : begin if(i<3'd5) next_state = S1 ;
        else next_state = S0 ; end
      
      default : next_state = S0 ;
          endcase 
  end
    
    
  always @(posedge clock) begin
      case(curr_state)
        S0 : begin acc <= 32'd0 ;
          i<= 3'd0 ;
         done<= 0 ; end
        S1 :  begin 
          acc <= input_vec[i]   * kernel[0] +input_vec[i+1] * kernel[1] + input_vec[i+2] * kernel[2];
        end
        S2 : begin result[i] <= acc ;
                   acc <= 32'd0;
                   i<= i+1 ;
          if(i==3'd5) done <= 1 ; 
        end
          endcase
        end
        
        endmodule
