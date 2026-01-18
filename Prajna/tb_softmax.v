`timescale 1ns/1ps

module tb_softmax;

  reg  signed [31:0] vector [0:3];
  wire [31:0] result [0:3];

  // DUT
  softmax dut (
    .vector(vector),
    .result(result)
  );

  integer i;
  initial begin
    $dumpfile("softmax_waveform.vcd");
    $dumpvars(0,tb_softmax);
  end

  task display_results;
    real r;
    begin
      $display("Inputs: %0d %0d %0d %0d",
               vector[0], vector[1], vector[2], vector[3]);
      for (i = 0; i < 4; i = i + 1) begin
        r = result[i] / 32768.0;   // Q1.15 → real
        $display(" result[%0d] = %0d  (%.6f)", i, result[i], r);
      end
      $display("                         ");
    end
  endtask

  initial begin
   
    vector[0] = 10;
    vector[1] = 9;
    vector[2] = 8;
    vector[3] = 7;
    #10;
    display_results();

   
    vector[0] = 5;
    vector[1] = 5;
    vector[2] = 5;
    vector[3] = 5;
    #10;
    display_results();

   
    vector[0] = 20;
    vector[1] = 10;
    vector[2] = 0;
    vector[3] = -10;
    #10;
    display_results();

    
    vector[0] = 3;
    vector[1] = 1;
    vector[2] = 0;
    vector[3] = -1;
    #10;
    display_results();

    $finish;
  end

endmodule
