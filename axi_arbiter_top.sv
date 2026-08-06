`timescale 1ns/1ps
module axi_arbiter_top (
    input  logic        clk,
    input  logic        reset,
    input  logic [3:0]  req,     // requests from 4 masters
    input  logic        mode,    // 0 = RR, 1 = Fixed Priority + Aging
    output logic [3:0]  grant    // final grant output
);

    // Internal signals for individual arbiter outputs
    logic [3:0] grant_rr;
    logic [3:0] grant_fp;

    //===========================
    // Round Robin Arbiter
    //===========================
    round_robin_arbiter u_rr (
        .clk   (clk),
        .reset (reset),
        .req   (req),
        .grant (grant_rr)
    );

    //===========================
    // Fixed Priority + Aging Arbiter
    //===========================
    fixed_priority_aging_arbiter u_fp (
        .clk   (clk),
        .reset (reset),
        .req   (req),
        .grant (grant_fp)
    );

    //===========================
    // Mode Selector
    //===========================
    mode_selector u_ms (
        .mode      (mode),
        .grant_rr  (grant_rr),
        .grant_fp  (grant_fp),
        .grant_out (grant)
    );

endmodule
