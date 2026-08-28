`timescale 1ns/1ps
// ============================================================
// round_robin_arbiter.sv  (FIXED)
//
// Fixes applied:
//   B1: Moved `idx` declaration out of always_comb loop body
//       (Xcelium rejects local declarations inside always_comb)
//   B2: idx is now logic [2:0] so the >= 4 wrap check fires
//       correctly instead of being dead code on a 2-bit signal
// ============================================================
module round_robin_arbiter (
    input  logic        clk,
    input  logic        reset,
    input  logic [3:0]  req,
    output logic [3:0]  grant
);

    // Pointer register
    logic [1:0] ptr_q, ptr_d;

    // FIX B1: declare idx at MODULE scope, not inside always_comb
    // FIX B2: use 3 bits so the ">= 4" wrap comparison is not dead code
    logic [2:0] idx;

    // found flag also at module scope (was already here — no change)
    logic found;

    always_comb begin
        grant = 4'b0000;
        ptr_d = ptr_q;
        found = 1'b0;

        for (int i = 0; i < 4; i++) begin
            // FIX B2: zero-extend ptr_q to 3 bits before adding i
            // so that idx can actually reach values >= 4 and the
            // wrap subtraction below is reachable (not dead code)
            idx = {1'b0, ptr_q} + 3'(i);
            if (idx >= 3'd4)
                idx = idx - 3'd4;

            if (!found && req[idx[1:0]]) begin
                grant[idx[1:0]] = 1'b1;
                found           = 1'b1;

                ptr_d = idx[1:0] + 1;   // stays 2-bit; wraps 3→0 automatically
            end
        end
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            ptr_q <= 2'd0;
        else
            ptr_q <= ptr_d;
    end

endmodule
