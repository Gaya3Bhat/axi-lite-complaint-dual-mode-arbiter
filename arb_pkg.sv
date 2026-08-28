// ============================================================
// arb_pkg.sv  (FIXED)
//
// Bugs fixed:
//   B3: logic'(i) → 2'(i)  in predict_rr + update_rr_ptr
//   B4: rr_ptr now updated EVERY cycle (RR arbiter always runs)
//   B5: Age model now uses last_fp_grant (correct 1-cycle ref)
//       and is maintained in BOTH modes (FP arbiter always runs)
//   B6: FP check no longer silently ignores grant=0 cases
//   B7: hold_cyc changed from rand int to rand int unsigned
// ============================================================

package arb_tb_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // ==========================================================
  // 1. SEQUENCE ITEM
  // ==========================================================
  class arb_seq_item extends uvm_sequence_item;

    `uvm_object_utils_begin(arb_seq_item)
      `uvm_field_int(req,      UVM_ALL_ON)
      `uvm_field_int(mode,     UVM_ALL_ON)
      `uvm_field_int(hold_cyc, UVM_ALL_ON)
      `uvm_field_int(grant,    UVM_ALL_ON)
    `uvm_object_utils_end

    rand logic [3:0]    req;
    rand logic          mode;
    rand int unsigned   hold_cyc;   // FIX B7: was "rand int" (signed)
    logic [3:0]         grant;

    constraint c_req      { req != 4'b0000; }
    constraint c_hold_cyc { hold_cyc inside {[1:4]}; }

    function new(string name = "arb_seq_item");
      super.new(name);
    endfunction

    function string convert2string();
      return $sformatf("req=%b mode=%0b hold=%0d grant=%b",
                        req, mode, hold_cyc, grant);
    endfunction

  endclass : arb_seq_item


  // ==========================================================
  // 2. SEQUENCES
  // ==========================================================

  class arb_rand_seq extends uvm_sequence #(arb_seq_item);
    `uvm_object_utils(arb_rand_seq)
    int num_trans = 30;
    function new(string name = "arb_rand_seq");
      super.new(name);
    endfunction
    task body();
      arb_seq_item item;
      repeat(num_trans) begin
        item = arb_seq_item::type_id::create("item");
        start_item(item);
        if (!item.randomize())
          `uvm_fatal("RAND_FAIL", "Randomization failed in arb_rand_seq")
        finish_item(item);
      end
    endtask
  endclass : arb_rand_seq


  class arb_rr_all_seq extends uvm_sequence #(arb_seq_item);
    `uvm_object_utils(arb_rr_all_seq)
    function new(string name = "arb_rr_all_seq");
      super.new(name);
    endfunction
    task body();
      arb_seq_item item;
      repeat(16) begin
        item = arb_seq_item::type_id::create("item");
        start_item(item);
        if (!item.randomize() with {
          req      == 4'b1111;
          mode     == 1'b0;
          hold_cyc == 1;
        })
          `uvm_fatal("RAND_FAIL", "Randomization failed in arb_rr_all_seq")
        finish_item(item);
      end
    endtask
  endclass : arb_rr_all_seq


  class arb_fp_starvation_seq extends uvm_sequence #(arb_seq_item);
    `uvm_object_utils(arb_fp_starvation_seq)
    function new(string name = "arb_fp_starvation_seq");
      super.new(name);
    endfunction
    task body();
      arb_seq_item item;
      // M0 (bit0) and M3 (bit3) both requesting in FP+Aging mode.
      // Expected: M0 wins for ~3 cycles, then M3 ages out and wins.
      repeat(20) begin
        item = arb_seq_item::type_id::create("item");
        start_item(item);
        if (!item.randomize() with {
          req      == 4'b1001;
          mode     == 1'b1;
          hold_cyc == 1;
        })
          `uvm_fatal("RAND_FAIL", "Randomization failed in arb_fp_starvation_seq")
        finish_item(item);
      end
    endtask
  endclass : arb_fp_starvation_seq


  class arb_mode_switch_seq extends uvm_sequence #(arb_seq_item);
    `uvm_object_utils(arb_mode_switch_seq)
    function new(string name = "arb_mode_switch_seq");
      super.new(name);
    endfunction
    task body();
      arb_seq_item item;
      repeat(10) begin
        item = arb_seq_item::type_id::create("item");
        start_item(item);
        if (!item.randomize() with { mode == 1'b0; })
          `uvm_fatal("RAND_FAIL", "Randomization failed")
        finish_item(item);
      end
      repeat(10) begin
        item = arb_seq_item::type_id::create("item");
        start_item(item);
        if (!item.randomize() with { mode == 1'b1; })
          `uvm_fatal("RAND_FAIL", "Randomization failed")
        finish_item(item);
      end
    endtask
  endclass : arb_mode_switch_seq


  // ==========================================================
  // 3. DRIVER
  // ==========================================================
  class arb_driver extends uvm_driver #(arb_seq_item);
    `uvm_component_utils(arb_driver)

    virtual arb_if vif;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db #(virtual arb_if)::get(this, "", "vif", vif))
        `uvm_fatal("NO_VIF", "arb_driver: virtual arb_if not found")
    endfunction

    task run_phase(uvm_phase phase);
      arb_seq_item item;
      // Assert reset for 4 clock cycles
      vif.reset <= 1'b1;
      vif.req   <= 4'b0000;
      vif.mode  <= 1'b0;
      repeat(4) @(posedge vif.clk);
      vif.reset <= 1'b0;
      @(posedge vif.clk);

      forever begin
        seq_item_port.get_next_item(item);
        drive_item(item);
        seq_item_port.item_done();
      end
    endtask

    task drive_item(arb_seq_item item);
      @(posedge vif.clk);
      vif.req  <= item.req;
      vif.mode <= item.mode;
      repeat(item.hold_cyc - 1) @(posedge vif.clk);
    endtask

  endclass : arb_driver


  // ==========================================================
  // 4. MONITOR
  // ==========================================================
  class arb_monitor extends uvm_monitor;
    `uvm_component_utils(arb_monitor)

    virtual arb_if vif;
    uvm_analysis_port #(arb_seq_item) ap;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      ap = new("ap", this);
      if (!uvm_config_db #(virtual arb_if)::get(this, "", "vif", vif))
        `uvm_fatal("NO_VIF", "arb_monitor: virtual arb_if not found")
    endfunction

    task run_phase(uvm_phase phase);
      arb_seq_item item;
      // Wait until reset deasserts, then one more cycle for DUT to stabilise
      @(posedge vif.clk);
      wait(vif.reset === 1'b0);
      @(posedge vif.clk);

      forever begin
        @(posedge vif.clk);
        #1; // sample in the NBA region settling window
        if (!vif.reset) begin
          item          = arb_seq_item::type_id::create("mon_item");
          item.req      = vif.req;
          item.mode     = vif.mode;
          item.grant    = vif.grant;
          item.hold_cyc = 1;
          ap.write(item);
          `uvm_info("MON", item.convert2string(), UVM_HIGH)
        end
      end
    endtask

  endclass : arb_monitor


  // ==========================================================
  // 5. SCOREBOARD  (heavily revised — see fixes B3–B6)
  //
  // TIMING MODEL (critical to understand before reading code):
  //
  //   RR arbiter grant   = COMBINATIONAL → grant[T] = f(req[T], ptr_q[T])
  //   FP arbiter grant   = REGISTERED   → grant[T] = f(req[T-1], ages[T-1])
  //
  //   age_counter update = REGISTERED, based on PREVIOUS registered grant:
  //     clr[T] = grant_q[T-1]
  //     inc[T] = req[T-1] & ~grant_q[T-1]
  //
  //   Monitor item at cycle T:
  //     item.req   = req driven at T's NBA  (new req)
  //     item.grant = grant_q updated at T's NBA = f(req[T-1], ages[T-1])
  //
  //   Therefore scoreboard must:
  //     - FP check  : compare item.grant vs predict_fp(prev_item.req)
  //     - Age update: update_ages(prev_item.req, last_fp_grant)
  //                   where last_fp_grant = fp grant_q from PREVIOUS cycle
  //     - RR update : always advance rr_ptr (FIX B4: even in FP mode)
  // ==========================================================
  class arb_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(arb_scoreboard)

    uvm_analysis_imp #(arb_seq_item, arb_scoreboard) analysis_export;

    int pass_cnt, fail_cnt;

    // ---- Model state ----
    logic [1:0]  rr_ptr;         // mirrors round_robin_arbiter ptr_q
    logic [1:0]  ages [0:3];     // mirrors each age_counter
    logic [3:0]  last_fp_grant;  // FIX B5: tracks FP grant_q from previous cycle
    arb_seq_item prev_item;      // previous monitor transaction

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      analysis_export  = new("analysis_export", this);
      rr_ptr           = 2'd0;
      foreach(ages[i])  ages[i] = 2'd0;
      last_fp_grant    = 4'b0;   // matches grant_q reset value
      prev_item        = null;
      pass_cnt         = 0;
      fail_cnt         = 0;
    endfunction

    // ----------------------------------------------------------
    // write() — called every clock cycle by the monitor
    // ----------------------------------------------------------
    function void write(arb_seq_item item);
      logic [3:0] pred_fp;   // expected FP grant this cycle
      logic [3:0] pred_rr;   // expected RR grant this cycle

      // ---- STEP 1: Compute predictions using state BEFORE any update ----
      // FP prediction: f(prev_req, current_ages)  [1-cycle registered pipeline]
      pred_fp = 4'b0;
      if (prev_item != null && |prev_item.req)
        pred_fp = predict_fp(prev_item.req);

      // RR prediction: f(current_req, current_rr_ptr)  [combinational]
      pred_rr = 4'b0;
      if (|item.req)
        pred_rr = predict_rr(item.req);

      // ---- STEP 2: Update model state for NEXT cycle ----
      // FIX B5: age update uses last_fp_grant (the FP grant_q from the
      // PREVIOUS cycle), because age_counter.clr/inc reference grant_q[T-1].
      // This is correct for BOTH modes — FP arbiter always runs internally.
      if (prev_item != null)
        update_ages(prev_item.req, last_fp_grant);

      // Store this cycle's FP prediction as next cycle's last_fp_grant
      last_fp_grant = pred_fp;

      // FIX B4: always advance rr_ptr regardless of current mode.
      // round_robin_arbiter's ptr_q advances every clock cycle no matter
      // what mode_selector is doing.
      update_rr_ptr(pred_rr);

      // ---- STEP 3: Checks ----
      check_one_hot(item.grant);

      if (item.mode == 1'b0) begin
        // RR mode — grant is combinational, compare against pred_rr
        if (|item.req)
          check_rr(item, pred_rr);
      end else begin
        // FP mode — grant is registered (1-cycle delay), compare against pred_fp
        // Only check once prev_item exists (skip the first-ever FP capture)
        if (prev_item != null && |prev_item.req)
          check_fp(item, pred_fp);
      end

      prev_item = item;
    endfunction


    // ----------------------------------------------------------
    // predict_fp : compute expected FP+Aging grant
    //   Uses current ages[] model (before this cycle's update).
    // ----------------------------------------------------------
    function logic [3:0] predict_fp(logic [3:0] req);
      // Phase A: aged masters (age==3) take priority, still in M0>M1>M2>M3 order
      for (int i = 0; i < 4; i++) begin
        if (req[i] && ages[i] == 2'd3)
          return (4'b0001 << i);
      end
      // Phase B: normal fixed priority
      for (int i = 0; i < 4; i++) begin
        if (req[i])
          return (4'b0001 << i);
      end
      return 4'b0;
    endfunction


    // ----------------------------------------------------------
    // predict_rr : compute expected Round-Robin grant
    //   Starting from rr_ptr, award the first requesting master.
    //   FIX B3: use 2'(i) not logic'(i) to avoid 1-bit truncation
    // ----------------------------------------------------------
    function logic [3:0] predict_rr(logic [3:0] req);
      logic [1:0] idx;
      for (int i = 0; i < 4; i++) begin
        idx = rr_ptr + 2'(i);   // FIX B3: 2-bit cast, wraps mod-4 naturally
        if (req[idx])
          return (4'b0001 << idx);
      end
      return 4'b0;
    endfunction


    // ----------------------------------------------------------
    // check_one_hot : grant must be 0 or exactly one bit set
    // ----------------------------------------------------------
    function void check_one_hot(logic [3:0] grant);
      int cnt;
      cnt = 0;
      for (int i = 0; i < 4; i++)
        if (grant[i]) cnt++;
      if (cnt > 1) begin
        `uvm_error("SB", $sformatf(
          "FAIL [ONE-HOT] grant=%b has %0d bits set — multi-grant bug!", grant, cnt))
        fail_cnt++;
      end else begin
        pass_cnt++;
      end
    endfunction


    // ----------------------------------------------------------
    // check_rr : verify actual RR grant matches prediction
    // ----------------------------------------------------------
    function void check_rr(arb_seq_item item, logic [3:0] pred_rr);
      // Granted master must have been requesting
      if (item.grant != 4'b0 && !(item.req & item.grant)) begin
        `uvm_error("SB", $sformatf(
          "FAIL [RR GRANT-IN-REQ] grant=%b not in req=%b", item.grant, item.req))
        fail_cnt++;
        return;
      end
      if (item.grant !== pred_rr) begin
        `uvm_error("SB", $sformatf(
          "FAIL [RR] req=%b rr_ptr=%0d  expected=%b  got=%b",
          item.req, rr_ptr, pred_rr, item.grant))
        fail_cnt++;
      end else begin
        `uvm_info("SB", $sformatf(
          "PASS [RR] req=%b rr_ptr=%0d grant=%b", item.req, rr_ptr, item.grant), UVM_HIGH)
        pass_cnt++;
      end
    endfunction


    // ----------------------------------------------------------
    // check_fp : verify actual FP grant matches prediction
    //   FIX B6: strict equality — no silent bypass for grant==0
    // ----------------------------------------------------------
    function void check_fp(arb_seq_item item, logic [3:0] pred_fp);
      // Granted master must have been requesting in PREVIOUS req (pipeline)
      if (item.grant != 4'b0 && !(prev_item.req & item.grant)) begin
        `uvm_error("SB", $sformatf(
          "FAIL [FP GRANT-IN-REQ] grant=%b not in prev_req=%b",
          item.grant, prev_item.req))
        fail_cnt++;
        return;
      end
      // FIX B6: check strictly — grant=0 when pred_fp!=0 is also an error
      if (item.grant !== pred_fp) begin
        `uvm_error("SB", $sformatf(
          "FAIL [FP] prev_req=%b ages=[%0d,%0d,%0d,%0d]  expected=%b  got=%b",
          prev_item.req, ages[0], ages[1], ages[2], ages[3], pred_fp, item.grant))
        fail_cnt++;
      end else begin
        `uvm_info("SB", $sformatf(
          "PASS [FP] prev_req=%b ages=[%0d,%0d,%0d,%0d] grant=%b",
          prev_item.req, ages[0], ages[1], ages[2], ages[3], item.grant), UVM_HIGH)
        pass_cnt++;
      end
    endfunction


    // ----------------------------------------------------------
    // update_rr_ptr
    //   FIX B3+B4: always called (both modes); uses 2'(i) cast
    //   Mirrors: ptr_d = idx + 1 in round_robin_arbiter
    // ----------------------------------------------------------
    function void update_rr_ptr(logic [3:0] pred_rr);
      for (int i = 0; i < 4; i++) begin
        if (pred_rr[i]) begin
          rr_ptr = 2'(i) + 2'd1;   // FIX B3: was logic'(i) — truncated to 1 bit
          return;
        end
      end
    endfunction


    // ----------------------------------------------------------
    // update_ages
    //   FIX B5: called with (prev_item.req, last_fp_grant)
    //   Mirrors age_counter RTL:
    //     clr = grant_q[t-1]  (last_fp_grant passed in as 'fp_grant_prev')
    //     inc = req[t-1] & ~grant_q[t-1]
    // ----------------------------------------------------------
    function void update_ages(logic [3:0] req, logic [3:0] fp_grant_prev);
      for (int i = 0; i < 4; i++) begin
        if (fp_grant_prev[i]) begin
          ages[i] = 2'd0;                         // clr: was granted last cycle
        end else if (req[i]) begin
          if (ages[i] != 2'd3)
            ages[i] = ages[i] + 2'd1;             // inc: requesting but not granted
          // else stays at 3 (saturated)
        end
        // else req[i]=0: no change
      end
    endfunction


    function void report_phase(uvm_phase phase);
      `uvm_info("SB", $sformatf(
        "=== SCOREBOARD: PASS=%0d  FAIL=%0d ===", pass_cnt, fail_cnt), UVM_NONE)
      if (fail_cnt > 0)
        `uvm_error("SB", "SIMULATION RESULT: ** FAILED **")
      else
        `uvm_info("SB", "SIMULATION RESULT: ** PASSED **", UVM_NONE)
    endfunction

  endclass : arb_scoreboard


  // ==========================================================
  // 6. FUNCTIONAL COVERAGE
  // ==========================================================
  class arb_coverage extends uvm_subscriber #(arb_seq_item);
    `uvm_component_utils(arb_coverage)

    arb_seq_item item;

    covergroup arb_cg;
      cp_mode: coverpoint item.mode {
        bins rr_mode = {1'b0};
        bins fp_mode = {1'b1};
      }
      cp_req: coverpoint item.req {
        bins only_m0  = {4'b0001};
        bins only_m1  = {4'b0010};
        bins only_m2  = {4'b0100};
        bins only_m3  = {4'b1000};
        bins all_four = {4'b1111};
        bins m0_m3    = {4'b1001};  // starvation scenario
        bins no_req   = {4'b0000};
        bins others   = default;
      }
      cp_grant: coverpoint item.grant {
        bins grant_m0 = {4'b0001};
        bins grant_m1 = {4'b0010};
        bins grant_m2 = {4'b0100};
        bins grant_m3 = {4'b1000};
        bins no_grant = {4'b0000};
      }
      // Every master granted in both modes
      cx_mode_grant: cross cp_mode, cp_grant;
      // All req patterns in both modes
      cx_mode_req:   cross cp_mode, cp_req;
    endgroup

    function new(string name, uvm_component parent);
      super.new(name, parent);
      arb_cg = new();
    endfunction

    function void write(arb_seq_item t);
      item = t;
      arb_cg.sample();
    endfunction

    function void report_phase(uvm_phase phase);
      `uvm_info("COV", $sformatf(
        "=== FUNCTIONAL COVERAGE: %.2f%% ===", arb_cg.get_coverage()), UVM_NONE)
    endfunction

  endclass : arb_coverage


  // ==========================================================
  // 7. AGENT
  // ==========================================================
  class arb_agent extends uvm_agent;
    `uvm_component_utils(arb_agent)

    arb_driver                    driver;
    arb_monitor                   monitor;
    uvm_sequencer #(arb_seq_item) sequencer;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      driver    = arb_driver::type_id::create("driver",    this);
      monitor   = arb_monitor::type_id::create("monitor",  this);
      sequencer = uvm_sequencer #(arb_seq_item)::type_id::create("sequencer", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction

  endclass : arb_agent


  // ==========================================================
  // 8. ENVIRONMENT
  // ==========================================================
  class arb_env extends uvm_env;
    `uvm_component_utils(arb_env)

    arb_agent      agent;
    arb_scoreboard scoreboard;
    arb_coverage   coverage;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      agent      = arb_agent::type_id::create("agent",      this);
      scoreboard = arb_scoreboard::type_id::create("scoreboard", this);
      coverage   = arb_coverage::type_id::create("coverage",    this);
    endfunction

    function void connect_phase(uvm_phase phase);
      agent.monitor.ap.connect(scoreboard.analysis_export);
      agent.monitor.ap.connect(coverage.analysis_export);
    endfunction

  endclass : arb_env


  // ==========================================================
  // 9. TESTS
  // ==========================================================

  class arb_base_test extends uvm_test;
    `uvm_component_utils(arb_base_test)
    arb_env env;
    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      env = arb_env::type_id::create("env", this);
    endfunction
    task run_phase(uvm_phase phase);
      arb_rand_seq seq;
      phase.raise_objection(this);
      `uvm_info("TEST", "=== arb_base_test: random stimulus ===", UVM_NONE)
      seq = arb_rand_seq::type_id::create("seq");
      seq.start(env.agent.sequencer);
      #100;
      phase.drop_objection(this);
    endtask
  endclass : arb_base_test


  class arb_rr_test extends arb_base_test;
    `uvm_component_utils(arb_rr_test)
    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
      arb_rr_all_seq seq;
      phase.raise_objection(this);
      `uvm_info("TEST", "=== arb_rr_test: all masters, RR mode ===", UVM_NONE)
      seq = arb_rr_all_seq::type_id::create("seq");
      seq.start(env.agent.sequencer);
      #100;
      phase.drop_objection(this);
    endtask
  endclass : arb_rr_test


  class arb_fp_test extends arb_base_test;
    `uvm_component_utils(arb_fp_test)
    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
      arb_fp_starvation_seq seq;
      phase.raise_objection(this);
      `uvm_info("TEST", "=== arb_fp_test: starvation/aging ===", UVM_NONE)
      seq = arb_fp_starvation_seq::type_id::create("seq");
      seq.start(env.agent.sequencer);
      #100;
      phase.drop_objection(this);
    endtask
  endclass : arb_fp_test


  class arb_mode_test extends arb_base_test;
    `uvm_component_utils(arb_mode_test)
    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
      arb_mode_switch_seq seq;
      phase.raise_objection(this);
      `uvm_info("TEST", "=== arb_mode_test: RR then FP ===", UVM_NONE)
      seq = arb_mode_switch_seq::type_id::create("seq");
      seq.start(env.agent.sequencer);
      #100;
      phase.drop_objection(this);
    endtask
  endclass : arb_mode_test


endpackage : arb_tb_pkg
