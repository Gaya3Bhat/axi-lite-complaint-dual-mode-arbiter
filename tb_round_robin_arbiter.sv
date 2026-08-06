`timescale 1ns/1ps

module tb_round_robin_arbiter;

    // Testbench signals
    logic        clk;
    logic        reset;
    logic [3:0]  req;
    logic [3:0]  grant;

    // Instantiate the DUT (Device Under Test)
    round_robin_arbiter dut (
        .clk   (clk),
        .reset (reset),
        .req   (req),
        .grant (grant)
    );

    // Clock generation: 10 ns period (100 MHz)
    initial clk = 0;
    always #5 clk = ~clk;

    // Stimulus
    initial begin
        // Open waveform dump (for some simulators, Vivado uses GUI)
        // Initialize
        reset = 1;
        req   = 4'b0000;

        // Apply reset for some time
        #20;
        reset = 0;

        // Case 1: Only master 0 requests
        req = 4'b0001;   // M0
        #50;

        // Case 2: M0 and M1 request together
        req = 4'b0011;   // M0, M1
        #50;

        // Case 3: All masters request
        req = 4'b1111;
        #100;

        // Case 4: Only M2 and M3 request
        req = 4'b1100;
        #100;

        // Case 5: No one requests
        req = 4'b0000;
        #50;

        // Finish simulation
        $finish;
    end

endmodule
