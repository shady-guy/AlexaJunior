`timescale 1ns/1ps

module tb_fc_layer;

    // Clock & reset
    reg clock;
    reg reset;

    // Inputs
    reg signed [15:0] vector [0:5];
    reg signed [15:0] weights [0:5][0:3];

    // Outputs
    wire done;
    wire signed [31:0] result [0:3];

    // Instantiate the DUT
    fc_layer DUT (
        .clock(clock),
        .reset(reset),
        .vector(vector),
        .weights(weights),
        .done(done),
        .result(result)
    );

    // Clock generation: 10 ns period
    initial clock = 0;
    always #5 clock = ~clock;

    integer i, j;

    initial begin
        $dumpfile("fc_layer_waveform.vcd");
        $dumpvars(0, tb_fc_layer);

        // Initialize inputs
        reset = 1;
        #10;
        reset = 0;

        // Initialize vector
        vector[0] = 1;
        vector[1] = 2;
        vector[2] = 3;
        vector[3] = 4;
        vector[4] = 5;
        vector[5] = 6;

        // Initialize weights (example)
        weights[0][0] = 1;  weights[0][1] = 2;  weights[0][2] = 3;  weights[0][3] = 4;
        weights[1][0] = 1;  weights[1][1] = 0;  weights[1][2] = -1; weights[1][3] = 1;
        weights[2][0] = 2;  weights[2][1] = 1;  weights[2][2] = 0;  weights[2][3] = -1;
        weights[3][0] = 1;  weights[3][1] = 2;  weights[3][2] = 3;  weights[3][3] = 0;
        weights[4][0] = 0;  weights[4][1] = -1; weights[4][2] = 1;  weights[4][3] = 2;
        weights[5][0] = 1;  weights[5][1] = 1;  weights[5][2] = 1;  weights[5][3] = 1;

        // Wait for computation to finish
        wait(done == 1);

        // Display results
        $display("Fully Connected Layer Results:");
        for (i = 0; i < 4; i = i + 1) begin
            $display("result[%0d] = %0d", i, result[i]);
        end

        #20;
        $finish;
    end

endmodule
