# Quick Start Guide: AXI Arbiter

This project has two independent verification tracks. Both were actually run — pick the one you want to reproduce.

| Track | Tool | Status |
|-------|------|--------|
| Directed testbenches (`tb_*.sv`) | **Xilinx Vivado 2025.1** | Full project run, confirmed working |
| UVM testbench (`arb_pkg.sv`, `tb_top.sv`) | **EDA Playground — Cadence Xcelium 25.03** | 4/4 tests passed, results in README |

Neither track has been confirmed on other simulators (ModelSim, VCS, standalone Xcelium install, etc.) — only what's listed above has actually been run.

---

## Track 1: Directed Testbenches in Vivado

### Prerequisites
- Vivado (any recent version with simulation support)

### Steps

1. Create a new Vivado project (or open an existing one) and add all design files:
   ```
   axi_arbiter_top.sv
   round_robin_arbiter.sv
   fixed_priority_aging_arbiter.sv
   age_counter.sv
   mode_selector.sv
   axi_lite_arbiter_wrapper.sv
   fpga_top.sv
   ```

2. Add the simulation-only testbench files as **Simulation Sources**:
   ```
   tb_axi_arbiter_top.sv
   tb_round_robin_arbiter.sv
   tb_fixed_priority_aging_arbiter.sv
   tb_axi_lite_arbiter_wrapper.sv
   ```

3. Set the desired testbench as the top module for simulation (Vivado picks one `tb_*` module at a time — switch the "Simulation Top" in Project Settings to run a different one).

4. Run **Flow → Run Simulation → Run Behavioral Simulation**.

5. Check the Tcl console / simulation log for `$display` pass/fail messages from the testbench.

### Notes
- Add `fpga_top.xdc` as a Constraints source only if you intend to run synthesis/implementation — it is not needed for simulation.
- This project was run **end-to-end in Vivado** (design + all 4 directed testbenches). It has not been tested in other simulators.

---

## Track 2: UVM Testbench on EDA Playground (Xcelium 25.03)

### Prerequisites
- An [EDA Playground](https://www.edaplayground.com/) account (free)
- Simulator selection: **Xcelium 25.03** (or compatible), with UVM library enabled (e.g., UVM 1.2)

### Steps

1. Create a new EDA Playground project with two panels:
   - **Design panel** — paste the contents of `design.sv`, and add the actual files it includes to the project: `age_counter.sv`, `round_robin_arbiter.sv`, `fixed_priority_aging_arbiter.sv`, `mode_selector.sv`, `axi_arbiter_top.sv`, `arb_if.sv`
   - **Testbench panel** — paste the contents of `testbench.sv`, and add `arb_pkg.sv` and `tb_top.sv` to the project

2. Select **Xcelium 25.03** as the simulator, and enable UVM (select a UVM version, e.g. 1.2) in the tool options.

3. To run a specific UVM test, set the plusarg in the simulator run options:
   ```
   +UVM_TESTNAME=arb_rr_test
   ```
   Available tests: `arb_base_test`, `arb_rr_test`, `arb_fp_test`, `arb_mode_test`

4. Click **Run**.

5. Check the log for the scoreboard and coverage summary at the end:
   ```
   === SCOREBOARD: PASS=<N>  FAIL=<N> ===
   === FUNCTIONAL COVERAGE: <X>.XX% ===
   ```

6. (Optional) Tick **"Open EPWave after run"** to view waveforms — do not add `$dumpfile`/`$dumpvars` manually, EDA Playground manages its own VCD capture (see `CHANGELOG.md`, Fix B8).

### Confirmed Results

| Test | Scoreboard | Coverage | Result |
|------|-----------|----------|--------|
| `arb_rr_test` | PASS=50, FAIL=0 | 38.29% | ✅ PASSED |
| `arb_fp_test` | PASS=57, FAIL=0 | 32.29% | ✅ PASSED |
| `arb_mode_test` | PASS=102, FAIL=0 | 74.86% | ✅ PASSED |
| `arb_base_test` | PASS=156, FAIL=0 | 82.00% | ✅ PASSED |

Run each test with its own `+UVM_TESTNAME` to reproduce these numbers. Coverage is per-test (each test only exercises its own scenario); running multiple tests in sequence within one simulation would accumulate coverage further since the covergroup instance persists for the life of the `arb_coverage` component.

---

## 🔍 Key Signals to Monitor

```
clk           System clock
reset         Reset signal
req[3:0]      Master requests
mode          Arbitration mode: 0=RR, 1=FP+Aging
grant[3:0]    Arbiter grant output
age[*]        Age counters (internal to fixed_priority_aging_arbiter, if probed)
ptr_q         Round robin pointer (internal to round_robin_arbiter, if probed)
```

---

## 📚 File Organization

```
axi-arbiter/
├── README.md
├── QUICK_START.md                     ← This file
├── DESIGN_SPECS.md
├── VERIFICATION_PLAN.md
├── CHANGELOG.md                       ← Round-robin bug fix details
│
├── Design Files/
│   ├── axi_arbiter_top.sv
│   ├── round_robin_arbiter.sv         ← Fixed version (see CHANGELOG.md)
│   ├── fixed_priority_aging_arbiter.sv
│   ├── age_counter.sv
│   ├── mode_selector.sv
│   ├── axi_lite_arbiter_wrapper.sv
│   ├── fpga_top.sv
│   └── fpga_top.xdc
│
├── Directed Testbenches (Vivado)/
│   ├── tb_axi_arbiter_top.sv
│   ├── tb_round_robin_arbiter.sv
│   ├── tb_fixed_priority_aging_arbiter.sv
│   └── tb_axi_lite_arbiter_wrapper.sv
│
├── UVM Testbench (EDA Playground / Xcelium 25.03)/
│   ├── arb_if.sv
│   ├── arb_pkg.sv
│   ├── tb_top.sv
│   ├── design.sv
│   └── testbench.sv
│
└── .gitignore
```

---

## 🐛 Troubleshooting

### Vivado: `Undefined module/signal`
Ensure all design files are added before the testbench, and that the correct file is set as the simulation top.

### Vivado: Simulation runs but shows nothing
Check that the correct `tb_*` module is selected as **Simulation Top** in Project Settings — Vivado only simulates one top module at a time.

### EDA Playground: `local variable declarations are not allowed in an always_comb`
This is exactly Bug B1 described in `CHANGELOG.md`. Make sure you're using the fixed `round_robin_arbiter.sv` in this repo, not an older version.

### EDA Playground: UVM_FATAL — virtual interface not found
Confirm `arb_if.sv` is included in the **design** panel (via `design.sv`), and that `tb_top.sv` sets the interface into `uvm_config_db` before `run_test()` is called.

### EDA Playground: simulation hangs / times out
`tb_top.sv` has a 50,000 ns timeout guard (`uvm_fatal("TIMEOUT", ...)`). If you hit it, check that `+UVM_TESTNAME` is set to a valid test name.

---

## 🎯 Next Steps

1. Run Track 1 (Vivado) to confirm the directed testbenches pass
2. Run Track 2 (EDA Playground) to reproduce the UVM pass/coverage numbers
3. Read `CHANGELOG.md` to understand the round-robin bug and fix
4. Read `DESIGN_SPECS.md` for architecture details
5. Read `VERIFICATION_PLAN.md` for the full test strategy

---

**Last Updated:** [Date]
