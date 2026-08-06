`timescale 1ns/1ps
module fixed_priority_aging_arbiter (
    input  logic        clk,
    input  logic        reset,
    input  logic [3:0]  req,    // requests from 4 masters
    output logic [3:0]  grant   // grant to one master
);

    // Registered grant (previous cycle decision)
    logic [3:0] grant_q, grant_d;

    // Age values for each master
    logic [1:0] age0, age1, age2, age3;

    // Control signals for age counters
    logic inc0, inc1, inc2, inc3;
    logic clr0, clr1, clr2, clr3;

    //===========================
    // 1) AGE COUNTER INSTANCES
    //===========================

    age_counter u_age0 (
        .clk  (clk),
        .reset(reset),
        .inc  (inc0),
        .clr  (clr0),
        .age  (age0)
    );

    age_counter u_age1 (
        .clk  (clk),
        .reset(reset),
        .inc  (inc1),
        .clr  (clr1),
        .age  (age1)
    );

    age_counter u_age2 (
        .clk  (clk),
        .reset(reset),
        .inc  (inc2),
        .clr  (clr2),
        .age  (age2)
    );

    age_counter u_age3 (
        .clk  (clk),
        .reset(reset),
        .inc  (inc3),
        .clr  (clr3),
        .age  (age3)
    );

    //===========================
    // 2) FIXED PRIORITY + AGING
    //===========================
    // Priority: M0 > M1 > M2 > M3
    // Aging rule: if a master has age == 3, it is treated as urgent

    always_comb begin
        grant_d = 4'b0000;

        // ----- STEP A: clear grant by default -----

        // ----- STEP B: Aging-based selection -----
        // First, check if any "old" master (age == 3) is requesting.
        // We still keep fixed order among "old" masters.

        if (req[0] && (age0 == 2'd3)) begin
            grant_d = 4'b0001;  // M0
        end
        else if (req[1] && (age1 == 2'd3)) begin
            grant_d = 4'b0010;  // M1
        end
        else if (req[2] && (age2 == 2'd3)) begin
            grant_d = 4'b0100;  // M2
        end
        else if (req[3] && (age3 == 2'd3)) begin
            grant_d = 4'b1000;  // M3
        end
        else begin
            // ----- STEP C: Normal fixed priority -----
            if (req[0])       grant_d = 4'b0001; // M0
            else if (req[1])  grant_d = 4'b0010; // M1
            else if (req[2])  grant_d = 4'b0100; // M2
            else if (req[3])  grant_d = 4'b1000; // M3
            else              grant_d = 4'b0000; // No request
        end
    end

    //===========================
    // 3) REGISTER THE GRANT
    //===========================

    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            grant_q <= 4'b0000;
        else
            grant_q <= grant_d;
    end

    assign grant = grant_q;

    //===========================
    // 4) AGE CONTROL LOGIC
    //===========================
    // inc = requested AND not granted in previous cycle
    // clr = granted in previous cycle

    always_comb begin
        // Defaults
        clr0 = grant_q[0];
        clr1 = grant_q[1];
        clr2 = grant_q[2];
        clr3 = grant_q[3];

        inc0 = req[0] & ~grant_q[0];
        inc1 = req[1] & ~grant_q[1];
        inc2 = req[2] & ~grant_q[2];
        inc3 = req[3] & ~grant_q[3];
    end

endmodule
