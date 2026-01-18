 `timescale 1ns/1ps

module tb_conv1d;

  // Clock & control
  reg clock;
  reg start;

  // Inputs
  reg signed [15:0] input_vec [0:7];
  reg signed [15:0] kernel    [0:2];

  // Outputs
  wire signed [31:0] result [0:5];
  wire done;

  // DUT instantiation
  conv1d DUT (
    .clock(clock),
    .start(start),
    .input_vec(input_vec),
    .kernel(kernel),
    .result(result),
    .done(done)
  );

  // Clock generation (10 ns period)
  always #5 clock = ~clock;
  
  initial begin 
    $dumpfile("conv1d_waveform.vcd") ;
    $dumpvars(0,tb_conv1d) ;
  end

  integer i;

  initial begin
    // Initialize
    clock = 0;
    start = 0;

    // Input vector
    input_vec[0] = 1;
    input_vec[1] = 2;
    input_vec[2] = 3;
    input_vec[3] = 4;
    input_vec[4] = 5;
    input_vec[5] = 6;
    input_vec[6] = 7;
    input_vec[7] = 8;

    // Kernel
    kernel[0] = 1;
    kernel[1] = 0;
    kernel[2] = -1;

    // Wait before starting
    #20;

    // Start convolution
    start = 1;

    // Wait until done is asserted
    wait(done == 1);

    // Display results
    $display("Convolution Results:");
    for (i = 0; i < 6; i = i + 1) begin
      $display("result[%0d] = %0d", i, result[i]);
    end

    #20;
    $finish;
  end

endmodule


