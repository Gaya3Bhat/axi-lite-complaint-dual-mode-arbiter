// ============================================================
// tb_top.sv  (FIXED)
//
// Fix B8: removed $dumpfile / $dumpvars — EDA Playground
//         manages its own VCD dump; explicit $dumpfile
//         causes a file-conflict error on the platform.
// ============================================================

module tb_top;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import arb_tb_pkg::*;

  // Clock: 100 MHz
  logic clk;
  initial clk = 1'b0;
  always #5 clk = ~clk;

  // Interface
  arb_if dut_if (.clk(clk));

  // DUT
  axi_arbiter_top dut (
    .clk   (clk),
    .reset (dut_if.reset),
    .req   (dut_if.req),
    .mode  (dut_if.mode),
    .grant (dut_if.grant)
  );

  // UVM startup
  initial begin
    uvm_config_db #(virtual arb_if)::set(
      null,
      "uvm_test_top.*",
      "vif",
      dut_if
    );
    run_test();  // test name via +UVM_TESTNAME=arb_rr_test etc.
  end

  // Timeout guard
  initial begin
    #50000;
    `uvm_fatal("TIMEOUT", "Simulation exceeded 50,000 ns")
  end

  // FIX B8: $dumpfile / $dumpvars REMOVED.
  // EDA Playground provides its own wave capture — adding $dumpfile
  // here causes a "cannot open VCD file" conflict error.
  // To view waves on EDA Playground: tick "Open EPWave after run".

endmodule : tb_top
