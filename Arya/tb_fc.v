`timescale 1ns/1ps

module tb_fc;

  reg clk;
  reg clr;
  reg start;

  reg  signed [15:0] x [0:5];
  reg  signed [15:0] w [0:5][0:3];

  wire signed [31:0] output_vec [0:3];
  wire finished;

  integer i;

  // Instantiate DUT
  fc dut (
    .clk(clk),
    .clr(clr),
    .start(start),
    .x(x),
    .w(w),
    .output_vec(output_vec),
    .finished(finished)
  );

  // Clock generation: 10ns period
  always #5 clk = ~clk;

  initial begin
    // -------------------------
    // INITIALIZATION
    // -------------------------
    clk   = 0;
    clr   = 0;
    start = 0;

    // -------------------------
    // RESET
    // -------------------------
    #12;
    clr = 1;

    // -------------------------
    // APPLY INPUT VECTOR
    // x = [1 2 3 4 5 6]
    // -------------------------
    x[0] = 16'sd1;
    x[1] = 16'sd2;
    x[2] = 16'sd3;
    x[3] = 16'sd4;
    x[4] = 16'sd5;
    x[5] = 16'sd6;

    // -------------------------
    // APPLY WEIGHTS
    // -------------------------

    // output 0: all 1s → sum(x) = 21
    for (i=0; i<6; i=i+1)
      w[i][0] = 16'sd1;

    // output 1: [1 2 3 4 5 6] → 91
    w[0][1] = 16'sd1;
    w[1][1] = 16'sd2;
    w[2][1] = 16'sd3;
    w[3][1] = 16'sd4;
    w[4][1] = 16'sd5;
    w[5][1] = 16'sd6;

    // output 2: all -1 → -21
    for (i=0; i<6; i=i+1)
      w[i][2] = -16'sd1;

    // output 3: [1 -1 1 -1 1 -1] → -3
    w[0][3] =  16'sd1;
    w[1][3] = -16'sd1;
    w[2][3] =  16'sd1;
    w[3][3] = -16'sd1;
    w[4][3] =  16'sd1;
    w[5][3] = -16'sd1;

    // -------------------------
    // START COMPUTATION
    // -------------------------
    #10;
    start = 1;
    #10;
    start = 0;

    // -------------------------
    // WAIT FOR FINISH
    // -------------------------
    wait (finished == 1);

    // -------------------------
    // DISPLAY RESULTS
    // -------------------------
    $display("\n=== FC OUTPUTS ===");
    $display("output_vec[0] = %0d (expected  21)",  output_vec[0]);
    $display("output_vec[1] = %0d (expected  91)",  output_vec[1]);
    $display("output_vec[2] = %0d (expected -21)",  output_vec[2]);
    $display("output_vec[3] = %0d (expected  -3)",  output_vec[3]);

    // -------------------------
    // END SIMULATION
    // -------------------------
    #20;
    $finish;
  end

endmodule
