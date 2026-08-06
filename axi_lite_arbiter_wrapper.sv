`timescale 1ns/1ps

module axi_lite_arbiter_wrapper #(
    parameter ADDR_W = 32,
    parameter DATA_W = 32
)(
    input  logic clk,
    input  logic reset,
    input  logic mode,

    // ========================
    // READ ADDRESS CHANNEL
    // ========================
    input  logic [3:0]              M_ARVALID,
    input  logic [3:0][ADDR_W-1:0]   M_ARADDR,
    output logic [3:0]              M_ARREADY,

    // ========================
    // READ DATA CHANNEL
    // ========================
    output logic [3:0]              M_RVALID,
    output logic [3:0][DATA_W-1:0]   M_RDATA,
    input  logic [3:0]              M_RREADY,

    // ========================
    // WRITE ADDRESS CHANNEL
    // ========================
    input  logic [3:0]              M_AWVALID,
    input  logic [3:0][ADDR_W-1:0]   M_AWADDR,
    output logic [3:0]              M_AWREADY,

    // ========================
    // WRITE DATA CHANNEL
    // ========================
    input  logic [3:0]              M_WVALID,
    input  logic [3:0][DATA_W-1:0]   M_WDATA,
    output logic [3:0]              M_WREADY,

    // ========================
    // WRITE RESPONSE CHANNEL
    // ========================
    output logic [3:0]              M_BVALID,
    input  logic [3:0]              M_BREADY,

    // ========================
    // SLAVE INTERFACE
    // ========================
    output logic                    S_ARVALID,
    output logic [ADDR_W-1:0]        S_ARADDR,
    input  logic                    S_ARREADY,

    input  logic                    S_RVALID,
    input  logic [DATA_W-1:0]        S_RDATA,
    output logic                    S_RREADY,

    output logic                    S_AWVALID,
    output logic [ADDR_W-1:0]        S_AWADDR,
    input  logic                    S_AWREADY,

    output logic                    S_WVALID,
    output logic [DATA_W-1:0]        S_WDATA,
    input  logic                    S_WREADY,

    input  logic                    S_BVALID,
    output logic                    S_BREADY
);

    // ========================
    // INTERNAL SIGNALS
    // ========================
    logic [3:0] req_ar, req_aw;
    logic [3:0] grant_ar, grant_aw;

    logic [3:0] grant_ar_q, grant_aw_q;
    logic lock_ar, lock_aw;

    integer i;

    // ========================
    // REQUEST GENERATION
    // ========================
    assign req_ar = M_ARVALID;
    assign req_aw = M_AWVALID;

    // ========================
    // ARBITER INSTANCES
    // ========================
    axi_arbiter_top u_ar_arb (
        .clk   (clk),
        .reset (reset),
        .req   (req_ar),
        .mode  (mode),
        .grant (grant_ar)
    );

    axi_arbiter_top u_aw_arb (
        .clk   (clk),
        .reset (reset),
        .req   (req_aw),
        .mode  (mode),
        .grant (grant_aw)
    );

    // ========================
    // GRANT LOCKING (READ)
    // ========================
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            lock_ar     <= 0;
            grant_ar_q  <= 0;
        end else begin
            if (!lock_ar && |grant_ar) begin
                lock_ar    <= 1;
                grant_ar_q <= grant_ar;
            end else if (lock_ar && S_ARVALID && S_ARREADY) begin
                lock_ar    <= 0;
            end
        end
    end

    // ========================
    // GRANT LOCKING (WRITE)
    // ========================
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            lock_aw     <= 0;
            grant_aw_q  <= 0;
        end else begin
            if (!lock_aw && |grant_aw) begin
                lock_aw    <= 1;
                grant_aw_q <= grant_aw;
            end else if (lock_aw && S_AWVALID && S_AWREADY) begin
                lock_aw    <= 0;
            end
        end
    end

    // ========================
    // READ ADDRESS ROUTING
    // ========================
    assign S_ARVALID = |(grant_ar_q & M_ARVALID);

    always_comb begin
        S_ARADDR  = '0;
        M_ARREADY = '0;

        for (i = 0; i < 4; i++) begin
            if (grant_ar_q[i]) begin
                S_ARADDR      = M_ARADDR[i];
                M_ARREADY[i]  = S_ARREADY;
            end
        end
    end

    // ========================
    // READ DATA ROUTING
    // ========================
    assign S_RREADY = |(grant_ar_q & M_RREADY);

    always_comb begin
        M_RVALID = '0;
        M_RDATA  = '0;

        for (i = 0; i < 4; i++) begin
            if (grant_ar_q[i]) begin
                M_RVALID[i] = S_RVALID;
                M_RDATA[i]  = S_RDATA;
            end
        end
    end

    // ========================
    // WRITE ADDRESS ROUTING
    // ========================
    assign S_AWVALID = |(grant_aw_q & M_AWVALID);

    always_comb begin
        S_AWADDR  = '0;
        M_AWREADY = '0;

        for (i = 0; i < 4; i++) begin
            if (grant_aw_q[i]) begin
                S_AWADDR      = M_AWADDR[i];
                M_AWREADY[i]  = S_AWREADY;
            end
        end
    end

    // ========================
    // WRITE DATA ROUTING
    // ========================
    assign S_WVALID = |(grant_aw_q & M_WVALID);

    always_comb begin
        S_WDATA  = '0;
        M_WREADY = '0;

        for (i = 0; i < 4; i++) begin
            if (grant_aw_q[i]) begin
                S_WDATA      = M_WDATA[i];
                M_WREADY[i]  = S_WREADY;
            end
        end
    end

    // ========================
    // WRITE RESPONSE ROUTING
    // ========================
    assign S_BREADY = |(grant_aw_q & M_BREADY);

    always_comb begin
        M_BVALID = '0;

        for (i = 0; i < 4; i++) begin
            if (grant_aw_q[i]) begin
                M_BVALID[i] = S_BVALID;
            end
        end
    end

endmodule

