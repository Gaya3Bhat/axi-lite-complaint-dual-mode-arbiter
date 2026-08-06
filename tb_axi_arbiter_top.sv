`timescale 1ns/1ps

module tb_axi_arbiter_top;

    // Testbench signals
    logic        clk;
    logic        reset;
    logic [3:0]  req;
    logic        mode;
    logic [3:0]  grant;

    // DUT instance
    axi_arbiter_top dut (
        .clk   (clk),
        .reset (reset),
        .req   (req),
        .mode  (mode),
        .grant (grant)
    );

    // Clock generation: 10 ns period (100 MHz)
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Stimulus
    initial begin
        // Initial values
        reset = 1'b1;
        req   = 4'b0000;
        mode  = 1'b0;   // start with Round Robin mode

        // Hold reset for some time
        #20;
        reset = 1'b0;

        //=============================
        // PHASE 1: Round Robin mode
        //=============================
        // All four masters request -> should see rotating grants
        req  = 4'b1111;
        mode = 1'b0;   // 0 = Round Robin
        #200;

        // Only M0 and M2 request -> should see RR between them
        req = 4'b0101;
        #150;

        //=============================
        // PHASE 2: Fixed Priority + Aging mode
        //=============================
        // Switch mode, keep some requests
        mode = 1'b1;   // 1 = Fixed Priority + Aging

        // High priority M0 and low priority M3 both request
        req = 4'b1001;  // M3 + M0
        #250;

        // Only low priority M3 requests
        req = 4'b1000;
        #100;

        // All masters request again
        req = 4'b1111;
        #200;

        // End simulation
        $finish;
    end

endmodule
