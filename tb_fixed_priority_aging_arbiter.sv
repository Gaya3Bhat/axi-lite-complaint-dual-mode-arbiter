`timescale 1ns/1ps

module tb_fixed_priority_aging_arbiter;

    logic        clk;
    logic        reset;
    logic [3:0]  req;
    logic [3:0]  grant;

    // DUT instance
    fixed_priority_aging_arbiter dut (
        .clk   (clk),
        .reset (reset),
        .req   (req),
        .grant (grant)
    );

    // Clock: 10 ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Stimulus
    initial begin
        // Initialize
        reset = 1;
        req   = 4'b0000;

        // Hold reset
        #20;
        reset = 0;

        // Phase 1: Only highest priority M0 requests
        req = 4'b0001;   // only M0
        #50;

        // Phase 2: M0 (high) and M3 (low) both request
        // We keep them requesting for a long time to see aging.
        req = 4'b1001;   // M3 and M0
        #200;

        // Phase 3: Only M3 requests
        req = 4'b1000;
        #100;

        // Phase 4: All masters request
        req = 4'b1111;
        #200;

        // Done
        $finish;
    end

endmodule
