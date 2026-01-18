module softmax ( input reg signed [31:0] vector [3:0] , output reg  [31:0] result [3:0] ) ;

  reg signed [31:0] max_value ;
  reg signed [31:0] new_vector [3:0] ;
  reg signed [31:0] exp [3:0] ;
  
  reg signed [31:0] sum ;
  integer i , j;
  always @(*) begin
    max_value = vector[0] ;
    for(i = 0 ; i < 4 ; i++)
      if(vector[i] > max_value) max_value = vector[i] ;
    
  
    for(j=0;j<4;j++)
      begin 
        new_vector[j] = vector[j] - max_value ;
        if(new_vector[j] < 0) 
          exp[j] = 1>>(-new_vector[j] ) ;
        else exp[j] = 1 << new_vector[j] ;
      end
    
  
    sum = exp[0]+ exp[1] +exp[2] +exp[3] ;
    result[3] = (exp[3]<<15) / sum ;
    result[2] = (exp[2]<<15) / sum ;
    result[1] = (exp[1]<<15) / sum ;
    result[0] = (exp[0]<<15) / sum ;
  end
  
endmodule
