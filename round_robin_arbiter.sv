`timescale 1ns/1ps
module round_robin_arbiter (
    input  logic        clk,
    input  logic        reset,
    input  logic [3:0]  req,
    output logic [3:0]  grant
);

    // Pointer register
    logic [1:0] ptr_q, ptr_d;

    // Temporary flag must be declared OUTSIDE always_comb (Vivado restriction)
    logic found;

    always_comb begin
        grant = 4'b0000; 
        ptr_d = ptr_q;

        found = 1'b0;

        for (int i = 0; i < 4; i++) begin
            
            logic [1:0] idx;     // Vivado allows loop-local variables, keep this
            
            idx = ptr_q + i;
            if (idx >= 4)
                idx = idx - 4;

            if (!found && req[idx]) begin
                grant[idx] = 1'b1;
                found      = 1'b1;

                ptr_d = idx + 1;
                if (ptr_d >= 4)
                    ptr_d = ptr_d - 4;
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

