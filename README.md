# AXI Arbiter: Design and Verification

A configurable AXI arbiter with two selectable arbitration schemes, verified with both a directed SystemVerilog testbench and a UVM-based testbench.

## 🎯 Project Overview

This project implements an AXI-compliant arbiter supporting two arbitration modes:
- **Round Robin (RR):** Fair allocation with rotating priority
- **Fixed Priority with Aging:** High-priority enforcement with an aging mechanism to prevent starvation

The arbiter is designed for multi-master AXI systems and includes an AXI Lite wrapper for simplified integration.

## 🧪 Tools Used (Confirmed)

| Stage | Tool | Status |
|-------|------|--------|
| RTL Design + Directed Testbenches | **Xilinx Vivado** | Ran full project (design + directed testbenches) |
| UVM Testbench | **EDA Playground — Cadence Xcelium 25.03** | Ran all 4 UVM tests, results below |

> **Note:** The RTL and directed testbenches (`tb_*.sv` files) were executed in Vivado only. They have not been verified on ModelSim, VCS, or other simulators, even though the SystemVerilog is written to standard syntax that should be portable. The UVM testbench was run separately on EDA Playground using Xcelium 25.03. Compatibility with other tools is not claimed.

## 📋 Architecture

```
axi_arbiter_top (Top-Level Module)
├── round_robin_arbiter.sv
│   └── Implements fair, rotating priority scheme
├── fixed_priority_aging_arbiter.sv
│   ├── age_counter.sv (Starvation prevention)
│   └── Fixed priority with dynamic aging
└── mode_selector.sv
    └── Multiplexes between arbitration modes
```

## ✨ Key Features

| Feature | Details |
|---------|---------|
| **Arbitration Modes** | Round Robin & Fixed Priority + Aging |
| **Master Ports** | 4 simultaneous request inputs |
| **AXI Compliance** | AXI protocol-compliant grant signals |
| **Starvation Prevention** | Age counter mechanism in fixed-priority mode |
| **Mode Flexibility** | Runtime selectable arbitration policy |
| **Constraints File** | FPGA implementation ready (`fpga_top.xdc`) |
| **Verification** | Directed testbenches (Vivado) + UVM testbench (Xcelium) |

## 📁 Project Structure

### Design Files
- **`axi_arbiter_top.sv`** — Top-level module orchestrating RR and FP arbiters with mode selection
- **`round_robin_arbiter.sv`** — Rotating priority arbiter (fixed version — see Changelog)
- **`fixed_priority_aging_arbiter.sv`** — Fixed priority scheme with aging logic to prevent request starvation
- **`age_counter.sv`** — Aging counter for starvation prevention
- **`mode_selector.sv`** — Multiplexer selecting between arbitration outputs
- **`axi_lite_arbiter_wrapper.sv`** — AXI Lite-compliant wrapper interfacing with AXI bus transactions
- **`fpga_top.sv`** + **`fpga_top.xdc`** — FPGA top-level design and pin constraints

### Directed Verification Files (Vivado)
- **`tb_axi_arbiter_top.sv`** — Top-level system testbench
- **`tb_round_robin_arbiter.sv`** — Round robin arbiter testbench
- **`tb_fixed_priority_aging_arbiter.sv`** — Fixed priority arbiter testbench
- **`tb_axi_lite_arbiter_wrapper.sv`** — AXI Lite protocol testbench

### UVM Verification Files (EDA Playground / Xcelium 25.03)
- **`arb_if.sv`** — DUT interface
- **`arb_pkg.sv`** — UVM package: sequence item, sequences, driver, monitor, scoreboard, functional coverage, agent, env, tests
- **`tb_top.sv`** — UVM top module (clock, DUT instantiation, `run_test()`)
- **`design.sv`** — Include-stitcher for the design panel (EDA Playground convention)
- **`testbench.sv`** — Include-stitcher for the testbench panel (EDA Playground convention)

## 🔬 Verification Results

### UVM Testbench Results (EDA Playground, Xcelium 25.03)

| Test | Scoreboard | Coverage | Result |
|------|-----------|----------|--------|
| `arb_rr_test` | PASS=50, FAIL=0 | 38.29% | ✅ PASSED |
| `arb_fp_test` | PASS=57, FAIL=0 | 32.29% | ✅ PASSED |
| `arb_mode_test` | PASS=102, FAIL=0 | 74.86% | ✅ PASSED |
| `arb_base_test` | PASS=156, FAIL=0 | 82.00% | ✅ PASSED |

Coverage is per-test functional coverage from the `arb_coverage` covergroup (`cp_mode`, `cp_req`, `cp_grant`, and their cross bins). Running all four tests together would raise the cumulative coverage further, since each test exercises a different scenario subset (RR-only, FP-only, mode switching, and fully random).

The scoreboard is a self-checking reference model that independently predicts round-robin and fixed-priority+aging grants each cycle and compares them against DUT output, in addition to a one-hot grant check.

### Directed Testbench Coverage (Vivado)

The four directed `tb_*.sv` testbenches exercise:
- Round robin fairness and pointer rotation
- Fixed priority enforcement and aging/starvation prevention
- Mode switching between RR and FP+Aging
- AXI Lite read/write transaction sequences

These were run and passed in Vivado. Formal statement/branch/toggle coverage numbers were not collected for the directed testbenches (Vivado's simulator does not produce these coverage metrics without a separate coverage-enabled flow, which wasn't run for this project).

## 🐛 Known Bug Fix — Round Robin Arbiter

During UVM development, two bugs were found in the original `round_robin_arbiter.sv` when compiled under Xcelium and have been fixed in the version in this repo:

- **B1:** `idx` was declared inside the `always_comb` loop body. Xcelium rejects local variable declarations inside `always_comb`. Moved to module scope.
- **B2:** `idx` was 2 bits wide, so the `idx >= 4` wraparound check was dead code (a 2-bit signal can never reach 4). Widened to 3 bits so the wrap logic is actually reachable.

See `CHANGELOG.md` for full details and the original vs. fixed code.

## 🚀 Getting Started

See [QUICK_START.md](QUICK_START.md) for exact steps to run both the directed testbenches in Vivado and the UVM testbench on EDA Playground.

## 📝 Verification Checklist

- [x] Directed testbenches pass in Vivado
- [x] UVM testbench passes in Xcelium 25.03 (EDA Playground) — 4/4 tests, 0 failures
- [x] Self-checking scoreboard with independent reference model
- [x] Functional coverage collected per UVM test
- [x] One-hot grant property checked every cycle
- [x] Known RTL bug (round-robin `idx` width/scope) found via UVM and fixed

## 🎓 Learning Outcomes

This project demonstrates proficiency in:

- **RTL Design:** Modular design, hierarchical architecture
- **SystemVerilog:** Interfaces, packages, `always_comb`/`always_ff`
- **Directed Verification:** Self-checking testbenches in Vivado
- **UVM:** Sequence items, sequences, driver, monitor, analysis ports, scoreboard reference modeling, functional coverage, agents, env, test hierarchy
- **Debugging across simulators:** Found and fixed a bug that only surfaced when moving from Vivado to Xcelium
- **AXI Protocol:** Master/slave transactions, handshaking
- **FPGA:** Constraints file for implementation

## 💡 Future Enhancements

- [ ] Run directed testbenches on additional simulators (ModelSim/VCS) to confirm portability
- [ ] Collect statement/branch/toggle coverage for directed testbenches
- [ ] Combine all 4 UVM tests into one regression run for cumulative coverage
- [ ] Parameterized master count
- [ ] SystemVerilog Assertions (SVA) for formal properties

## 📚 References

- AMBA AXI Protocol Specification v1.0
- AMBA AXI Lite Protocol Specification
- SystemVerilog IEEE 1800-2017
- Accellera UVM 1.2

## 📄 License

This project is provided as-is for educational and portfolio purposes.

---

**Last Updated:** 28-08-2026
**Status:** Complete — RTL verified in Vivado (directed), UVM verified on EDA Playground/Cadence Xcelium 25.03
