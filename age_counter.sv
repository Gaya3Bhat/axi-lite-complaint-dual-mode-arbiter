`timescale 1ns/1ps
module age_counter (
    input  logic       clk,
    input  logic       reset,
    input  logic       inc,   // increment when master waits
    input  logic       clr,   // clear when master is granted
    output logic [1:0] age    // 2-bit age: 0 to 3
);

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            age <= 2'd0;
        end
        else if (clr) begin
            // Got the grant -> reset age
            age <= 2'd0;
        end
        else if (inc) begin
            // Only increase up to 3 (saturate)
            if (age != 2'd3)
                age <= age + 2'd1;
            else
                age <= age;  // stay at max
        end
        else begin
            // No change
            age <= age;
        end
    end

endmodule
