`timescale 1ns/1ps

module tb_axi_lite_arbiter_wrapper;

    // -------------------------
    // Parameters
    // -------------------------
    localparam ADDR_W = 32;
    localparam DATA_W = 32;

    // -------------------------
    // Clock & Reset
    // -------------------------
    logic clk;
    logic reset;
    logic mode;

    // -------------------------
    // MASTER SIDE SIGNALS
    // -------------------------
    logic [3:0]            M_ARVALID;
    logic [3:0][ADDR_W-1:0] M_ARADDR;
    logic [3:0]            M_ARREADY;

    logic [3:0]            M_RVALID;
    logic [3:0][DATA_W-1:0] M_RDATA;
    logic [3:0]            M_RREADY;

    logic [3:0]            M_AWVALID;
    logic [3:0][ADDR_W-1:0] M_AWADDR;
    logic [3:0]            M_AWREADY;

    logic [3:0]            M_WVALID;
    logic [3:0][DATA_W-1:0] M_WDATA;
    logic [3:0]            M_WREADY;

    logic [3:0]            M_BVALID;
    logic [3:0]            M_BREADY;

    // -------------------------
    // SLAVE SIDE SIGNALS
    // -------------------------
    logic                  S_ARVALID;
    logic [ADDR_W-1:0]      S_ARADDR;
    logic                  S_ARREADY;

    logic                  S_RVALID;
    logic [DATA_W-1:0]      S_RDATA;
    logic                  S_RREADY;

    logic                  S_AWVALID;
    logic [ADDR_W-1:0]      S_AWADDR;
    logic                  S_AWREADY;

    logic                  S_WVALID;
    logic [DATA_W-1:0]      S_WDATA;
    logic                  S_WREADY;

    logic                  S_BVALID;
    logic                  S_BREADY;

// -----------------------------
// Performance metric variables
// -----------------------------
    int read_start_cycle;
    int read_end_cycle;
    int read_latency;
    int cycle_counter;
    
    int arb_start_cycle;
    int arb_latency;
    
    int grant_count_m0;
    int grant_count_m1;
    int grant_count_m2;
    int grant_count_m3;
    
    
   // -----------------------------
    // Functional Coverage
    // -----------------------------
    covergroup arbiter_cov @(posedge clk);

    // Which master issued a request
        master_req : coverpoint M_ARVALID {
            bins m0 = {4'b0001};
            bins m1 = {4'b0010};
            bins m2 = {4'b0100};
            bins m3 = {4'b1000};
        }

    // Arbitration mode
        mode_sel : coverpoint mode {
            bins round_robin = {0};
            bins fixed_priority = {1};
        }

    // Read transactions
        read_trans : coverpoint M_ARVALID {
            bins read_req = {4'b0001};
        }

    // Write transactions
        write_trans : coverpoint M_AWVALID {
            bins write_req = {4'b0001};
        }

    endgroup

    arbiter_cov cov_inst = new();
    // -------------------------
    // DUT INSTANTIATION
    // -------------------------
    axi_lite_arbiter_wrapper #(
        .ADDR_W(ADDR_W),
        .DATA_W(DATA_W)
    ) dut (
        .clk        (clk),
        .reset      (reset),
        .mode       (mode),

        .M_ARVALID  (M_ARVALID),
        .M_ARADDR   (M_ARADDR),
        .M_ARREADY  (M_ARREADY),

        .M_RVALID   (M_RVALID),
        .M_RDATA    (M_RDATA),
        .M_RREADY   (M_RREADY),

        .M_AWVALID  (M_AWVALID),
        .M_AWADDR   (M_AWADDR),
        .M_AWREADY  (M_AWREADY),

        .M_WVALID   (M_WVALID),
        .M_WDATA    (M_WDATA),
        .M_WREADY   (M_WREADY),

        .M_BVALID   (M_BVALID),
        .M_BREADY   (M_BREADY),

        .S_ARVALID  (S_ARVALID),
        .S_ARADDR   (S_ARADDR),
        .S_ARREADY  (S_ARREADY),

        .S_RVALID   (S_RVALID),
        .S_RDATA    (S_RDATA),
        .S_RREADY   (S_RREADY),

        .S_AWVALID  (S_AWVALID),
        .S_AWADDR   (S_AWADDR),
        .S_AWREADY  (S_AWREADY),

        .S_WVALID   (S_WVALID),
        .S_WDATA    (S_WDATA),
        .S_WREADY   (S_WREADY),

        .S_BVALID   (S_BVALID),
        .S_BREADY   (S_BREADY)
    );


    // ============================================
    // AXI-LITE PROTOCOL ASSERTIONS
    // ============================================

    // ARVALID must stay high until ARREADY
    property arvalid_stable;
        @(posedge clk)
        disable iff (reset)
        (S_ARVALID && !S_ARREADY) |=> S_ARVALID;
    endproperty

    assert property (arvalid_stable)
        else $error("AXI violation: S_ARVALID dropped before S_ARREADY");

    // Only one master can see ARREADY
    property single_arready;
        @(posedge clk)
        disable iff (reset)
        ($countones(M_ARREADY) <= 1);
    endproperty

    assert property (single_arready)
        else $error("Arbitration error: Multiple ARREADY asserted");

    // Only one master can get RVALID
    property single_rvalid;
        @(posedge clk)
        disable iff (reset)
        ($countones(M_RVALID) <= 1);
    endproperty

    assert property (single_rvalid)
        else $error("AXI violation: Multiple RVALID asserted");

    // -------------------------
    // Clock generation
    // -------------------------
    always #5 clk = ~clk;
    
    // Sample coverage every cycle
    always_ff @(posedge clk) begin
        cov_inst.sample();
    end
    
    // -----------------------------
// Cycle counter
// -----------------------------
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            cycle_counter <= 0;
        else
            cycle_counter <= cycle_counter + 1;
    end
    
    // -----------------------------
    // Start arbitration timing
    // -----------------------------
    always_ff @(posedge clk) begin
        if (M_ARVALID[0]) begin
            arb_start_cycle <= cycle_counter;
        end
    end
    
    // Stop arbitration timing (only once per request)
    always_ff @(posedge clk) begin
        if (M_ARVALID[0] && M_ARREADY[0]) begin
            arb_latency <= cycle_counter - arb_start_cycle;
            $display("ARBITRATION LATENCY = %0d cycles", cycle_counter - arb_start_cycle);
        end
    end
    
    
    // -----------------------------
    // Grant fairness counter
    // -----------------------------
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            grant_count_m0 <= 0;
            grant_count_m1 <= 0;
            grant_count_m2 <= 0;
            grant_count_m3 <= 0;
        end
        else begin
            if (M_ARREADY[0]) grant_count_m0 <= grant_count_m0 + 1;
            if (M_ARREADY[1]) grant_count_m1 <= grant_count_m1 + 1;
            if (M_ARREADY[2]) grant_count_m2 <= grant_count_m2 + 1;
            if (M_ARREADY[3]) grant_count_m3 <= grant_count_m3 + 1;
        end
    end
    
    // -----------------------------
    // Start timing when AR handshake occurs
    // -----------------------------
    always_ff @(posedge clk) begin
        if (S_ARVALID && S_ARREADY) begin
            read_start_cycle <= cycle_counter;
        end
    end
    
    // -----------------------------
    // Stop timing when read data arrives
    // -----------------------------
    always_ff @(posedge clk) begin
        if (M_RVALID[0]) begin
            read_end_cycle <= cycle_counter;
            read_latency   <= cycle_counter - read_start_cycle;
            $display("READ LATENCY = %0d cycles", cycle_counter - read_start_cycle);
        end
    end

    // -------------------------
    // Initial block
    // -------------------------
    // ----------------------------------------------------
    // TESTBENCH : stimulus initial (replace existing initial)
    // ----------------------------------------------------
    initial begin
        clk = 0;
        reset = 1;
        mode = 0;

        // Initialize all master signals
        M_ARVALID = '0;
        M_ARADDR  = '{default: '0};
        M_RREADY  = 4'b0001;    // Master 0 will accept read data

        M_AWVALID = '0;
        M_AWADDR  = '{default: '0};
        M_WVALID  = '0;
        M_WDATA   = '{default: '0};
        M_BREADY  = '0;

        // Initialize slave signals (slave ready initially)
        S_ARREADY = 1'b1;
        S_RVALID  = 1'b0;
        S_RDATA   = '0;
        S_AWREADY = 1'b1;
        S_WREADY  = 1'b1;
        S_BVALID  = 1'b0;

        // Hold reset for a short time
        #20;
        reset = 0;

        // Wait some cycles after reset
        repeat (5) @(posedge clk);

        // ---------- SIMPLE READ from MASTER 0 ----------
        $display("TB: issuing single READ from Master 0 at time %0t", $time);
        M_ARADDR[0] = 32'h0000_1000;
        M_ARVALID[0] = 1'b1;

        // wait for ARREADY handshake
        wait (M_ARREADY[0] == 1'b1);
        @(posedge clk);            // ensure we sample after handshake
        M_ARVALID[0] = 1'b0;       // deassert VALID after handshake

        // wait for read data to arrive at master
        wait (M_RVALID[0] == 1'b1);
        @(posedge clk); // let waveform settle
        $display("TB: Master0 received RDATA = %h at time %0t", M_RDATA[0], $time);

        // small delay then finish
        repeat (10) @(posedge clk);
        
        $display("---- Fairness Metrics ----");
        $display("Master0 grants = %0d", grant_count_m0);
        $display("Master1 grants = %0d", grant_count_m1);
        $display("Master2 grants = %0d", grant_count_m2);
        $display("Master3 grants = %0d", grant_count_m3);
        
        $display("TB: Done - finishing simulation at time %0t", $time);
        $display("Functional coverage collection completed.");
        $finish;
        
        
     /*           // ---------- SIMULTANEOUS READ from MASTER 0 & 1 ----------
        $display("TB: issuing simultaneous READ from Master 0 and 1 at time %0t", $time);

        // Both masters issue read at same time
        M_ARADDR[0] = 32'h0000_1000;
        M_ARADDR[1] = 32'h0000_2000;

        M_ARVALID[0] = 1'b1;
        M_ARVALID[1] = 1'b1;

        // Wait until ONE of them gets ready
        wait (M_ARREADY[0] == 1'b1 || M_ARREADY[1] == 1'b1);
        @(posedge clk);

        // Deassert both VALIDs after handshake
        M_ARVALID[0] = 1'b0;
        M_ARVALID[1] = 1'b0;

        // Wait for read data
        wait (M_RVALID[0] == 1'b1 || M_RVALID[1] == 1'b1);
        @(posedge clk);

        if (M_RVALID[0])
            $display("TB: Master 0 received data %h", M_RDATA[0]);
        else
            $display("TB: Master 1 received data %h", M_RDATA[1]);

        repeat (10) @(posedge clk);
        $finish;*/
        
                // ---------- FIXED PRIORITY + AGING TEST ----------
        // Priority: M0 > M1 > M2 > M3

     /*   $display("TB: Fixed Priority + Aging test started");

        // Master 0 continuously requests
        // Master 1 also requests (should age and eventually win)

        repeat (4) begin
            M_ARADDR[0] = 32'h0000_1000;
            M_ARADDR[1] = 32'h0000_2000;

            M_ARVALID[0] = 1'b1;
            M_ARVALID[1] = 1'b1;

            wait (M_ARREADY[0] || M_ARREADY[1]);
            @(posedge clk);

            M_ARVALID[0] = 1'b0;
            M_ARVALID[1] = 1'b0;

            wait (M_RVALID[0] || M_RVALID[1]);
            @(posedge clk);

            if (M_RVALID[0])
                $display("Cycle grant: Master 0");
            else
                $display("Cycle grant: Master 1");

            repeat (3) @(posedge clk);
        end

        $display("TB: Fixed Priority + Aging test finished");
        $finish;
*/
     /*   // ---------- SINGLE WRITE from MASTER 0 ----------
        $display("TB: issuing single WRITE from Master 0 at time %0t", $time);

        M_AWADDR[0]  = 32'h0000_3000;
        M_AWVALID[0] = 1'b1;

        M_WDATA[0]   = 32'hCAFE_BABE;
        M_WVALID[0]  = 1'b1;

        M_BREADY[0]  = 1'b1;

        // Wait for AW handshake
        wait (M_AWREADY[0] == 1'b1);
        @(posedge clk);
        M_AWVALID[0] = 1'b0;

        // Wait for W handshake
        wait (M_WREADY[0] == 1'b1);
        @(posedge clk);
        M_WVALID[0] = 1'b0;

        // Wait for write response
        wait (M_BVALID[0] == 1'b1);
        @(posedge clk);
        $display("TB: Master 0 WRITE completed at time %0t", $time);

        repeat (10) @(posedge clk);
        $finish;

*/
    end

    // ----------------------------------------------------
    // Simple AXI-Lite slave model (handles AR -> R)
    // responds with DEADBEEF after 2 cycles
    // ----------------------------------------------------
    logic slave_busy;
    logic [1:0] resp_cnt;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            S_ARREADY <= 1'b1;
            S_RVALID  <= 1'b0;
            S_RDATA   <= '0;
            slave_busy <= 1'b0;
            resp_cnt  <= 2'd0;
        end else begin
            if (!slave_busy) begin
                // Accept any AR handshake when ready
                if (S_ARVALID && S_ARREADY) begin
                    slave_busy <= 1'b1;
                    resp_cnt <= 2;        // respond after 2 cycles
                    S_ARREADY <= 1'b0;    // temporarily not ready until response done
                end
            end else begin
                if (resp_cnt != 0) begin
                    resp_cnt <= resp_cnt - 1;
                end else begin
                    // Present read data
                    S_RDATA <= 32'hDEAD_BEEF;
                    S_RVALID <= 1'b1;

                    // Once master accepts R (S_RREADY asserted by wrapper), clear
                    if (S_RVALID && S_RREADY) begin
                        S_RVALID <= 1'b0;
                        slave_busy <= 1'b0;
                        S_ARREADY <= 1'b1;
                    end
                end
            end
        end
    end
    
    
        // ----------------------------------------------------
    // Simple AXI-Lite WRITE slave response
    // ----------------------------------------------------
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            S_AWREADY <= 1'b1;
            S_WREADY  <= 1'b1;
            S_BVALID  <= 1'b0;
        end else begin
            // Accept write address and data
            if (S_AWVALID && S_AWREADY && S_WVALID && S_WREADY) begin
                S_BVALID <= 1'b1;
            end

            // Clear response once accepted
            if (S_BVALID && S_BREADY) begin
                S_BVALID <= 1'b0;
            end
        end
    end


endmodule

