module fpga_top(
    input  clk,
    input  reset,
    input  sw0,          // Nexys A7 Switch 0
    output [3:0] led
);

logic rst;
logic [3:0] req;
logic [3:0] grant;
logic mode;

logic [26:0] counter;
logic [1:0] pattern;

assign rst  = ~reset;   // Nexys buttons are active-low
assign mode = sw0;      // SW0 selects arbitration mode

//--------------------------------------------------
// Clock divider (slow LED movement ~1 second)
//--------------------------------------------------
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        counter <= 0;
        pattern <= 0;
    end
    else begin
        if (counter == 27'd100000000) begin
            counter <= 0;
            pattern <= pattern + 1;
        end
        else begin
            counter <= counter + 1;
        end
    end
end

//--------------------------------------------------
// Request pattern generator
//--------------------------------------------------
always_comb begin
    case(pattern)
        2'b00: req = 4'b0011;   // M0 & M1 request
        2'b01: req = 4'b0111;   // M0, M1, M2 request
        2'b10: req = 4'b1101;   // M0, M2, M3 request
        2'b11: req = 4'b1010;   // M1 & M3 request
    endcase
end

//--------------------------------------------------
// Arbiter
//--------------------------------------------------
axi_arbiter_top arbiter (
    .clk(clk),
    .reset(rst),
    .req(req),
    .mode(mode),
    .grant(grant)
);

//--------------------------------------------------
// LED output
//--------------------------------------------------
assign led = grant;

endmodule