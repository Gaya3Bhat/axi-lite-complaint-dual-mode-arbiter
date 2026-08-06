`timescale 1ns/1ps
module mode_selector (
    input  logic        mode,        // 0 = Round Robin, 1 = Fixed Priority + Aging
    input  logic [3:0]  grant_rr,    // grant from Round Robin arbiter
    input  logic [3:0]  grant_fp,    // grant from Fixed Priority + Aging arbiter
    output logic [3:0]  grant_out    // selected grant to top-level
);

    always_comb begin
        case (mode)
            1'b0:   grant_out = grant_rr;   // Round Robin mode
            1'b1:   grant_out = grant_fp;   // Fixed Priority + Aging mode
            default: grant_out = 4'b0000;   // safety
        endcase
    end

endmodule
