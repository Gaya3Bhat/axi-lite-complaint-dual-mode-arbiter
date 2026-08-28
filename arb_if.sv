// ============================================================
// arb_if.sv
// Interface for axi_arbiter_top DUT
//
// DUT ports:
//   input  clk, reset
//   input  req[3:0]  - requests from 4 masters
//   input  mode      - 0=Round Robin, 1=Fixed Priority+Aging
//   output grant[3:0]- grant to one master
// ============================================================

interface arb_if (input logic clk);

  logic        reset;
  logic [3:0]  req;
  logic        mode;
  logic [3:0]  grant;

endinterface
