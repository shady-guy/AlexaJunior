`timescale 1ns/1ps

module tb_cl;

  // Clock & control
  reg clk;
  reg clr;
  reg start;

  // Inputs
  reg signed [15:0] x [0:7];
  reg signed [15:0] k [0:2];

  // Outputs
  wire signed [31:0] output_vec [0:5];
  wire finished;

  integer i;

  // DUT instantiation
  cl dut (
    .clk(clk),
    .clr(clr),
    .start(start),
    .x(x),
    .k(k),
    .output_vec(output_vec),
    .finished(finished)
  );

  // Clock generation (10 ns period)
  always #5 clk = ~clk;

  initial begin
    // Initialize
    clk   = 0;
    clr   = 0;
    start = 0;

    // Apply reset
    #10;
    clr = 1;

    // Input vector (length = 8)
    // x = [1 2 3 4 5 6 7 8]
    x[0] = 1;
    x[1] = 2;
    x[2] = 3;
    x[3] = 4;
    x[4] = 5;
    x[5] = 6;
    x[6] = 7;
    x[7] = 8;

    // Kernel (length = 3)
    // k = [1 1 1]
    k[0] = 1;
    k[1] = 1;
    k[2] = 1;

    // Start computation
    #10;
    start = 1;
    #10;
    start = 0;

    // Wait for completion
    wait(finished == 1);

    // Display results
    $display("\n===== Convolution Output =====");
    for (i = 0; i < 6; i = i + 1)
      $display("output_vec[%0d] = %0d", i, output_vec[i]);

    /*
      EXPECTED OUTPUT (VALID CONVOLUTION):

      output_vec[0] =  1+2+3 =  6
      output_vec[1] =  2+3+4 =  9
      output_vec[2] =  3+4+5 = 12
      output_vec[3] =  4+5+6 = 15
      output_vec[4] =  5+6+7 = 18
      output_vec[5] =  6+7+8 = 21

      FINAL EXPECTED ARRAY:
      [6, 9, 12, 15, 18, 21]
    */

    $display("===== TEST COMPLETE =====\n");
    #20;
    $finish;
  end

endmodule
