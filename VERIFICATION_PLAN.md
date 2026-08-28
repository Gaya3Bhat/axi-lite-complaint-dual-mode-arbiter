# Verification Plan: AXI Arbiter

## Executive Summary

This document describes the verification methodology for the AXI Arbiter, covering two independent tracks: directed SystemVerilog testbenches (run in **Vivado**) and a UVM testbench (run on **EDA Playground, Xcelium 25.03**). All results quoted below are from actual runs, not estimates.

---

## 1. Verification Objectives

| Objective | Track | Status |
|-----------|-------|--------|
| Functional correctness — directed tests | Vivado | All 4 directed testbenches pass |
| Functional correctness — UVM tests | Xcelium 25.03 (EDA Playground) | 4/4 tests pass, 0 scoreboard failures |
| Functional coverage — UVM | Xcelium 25.03 (EDA Playground) | Collected per test (see Section 6) |
| Statement/branch/toggle coverage — directed | Vivado | **Not collected** (would require a separate coverage-enabled flow) |
| Protocol compliance (AXI Lite) | Vivado | Exercised by `tb_axi_lite_arbiter_wrapper.sv` |

---

## 2. Test Architecture

### 2.1 Directed Testbenches (Vivado)

```
tb_axi_arbiter_top.sv           — top-level integration testbench
tb_round_robin_arbiter.sv       — round robin arbiter unit testbench
tb_fixed_priority_aging_arbiter.sv — fixed priority + aging unit testbench
tb_axi_lite_arbiter_wrapper.sv  — AXI Lite protocol testbench
```

Each is a self-contained, directed (non-UVM) SystemVerilog testbench.

### 2.2 UVM Testbench (EDA Playground / Xcelium 25.03)

```
tb_top
├─ DUT: axi_arbiter_top
├─ arb_if                        (virtual interface)
└─ uvm_test_top
   └─ arb_env
      ├─ arb_agent
      │  ├─ arb_driver            → drives req/mode onto arb_if
      │  ├─ arb_monitor           → samples req/mode/grant each cycle
      │  └─ uvm_sequencer #(arb_seq_item)
      ├─ arb_scoreboard           → independent reference model + checks
      └─ arb_coverage             → functional covergroup
```

**Tests:** `arb_base_test` (random), `arb_rr_test` (all-masters RR), `arb_fp_test` (starvation/aging on M0 vs M3), `arb_mode_test` (RR then FP sequence).

---

## 3. Directed Testbench Coverage (Vivado)

### 3.1 Round Robin Arbiter (`tb_round_robin_arbiter.sv`)

Exercises: no requests, single master requesting, multiple masters requesting, all 4 masters requesting, request de-assertion, reset during grant, and burst request patterns — confirming pointer rotation and one-hot grant behavior.

### 3.2 Fixed Priority + Aging Arbiter (`tb_fixed_priority_aging_arbiter.sv`)

Exercises: single master requesting, static priority ordering among multiple masters, and the aging/starvation scenario (a low-priority master requesting alone long enough to age up, then a high-priority master joining).

### 3.3 Top-Level Integration (`tb_axi_arbiter_top.sv`)

Exercises: RR mode with all masters requesting, FP mode with a subset requesting, mode switching between RR and FP, and simultaneous multi-master requests.

### 3.4 AXI Lite Wrapper (`tb_axi_lite_arbiter_wrapper.sv`)

Exercises: write transactions, read transactions, and multiple masters contending for the wrapper's arbitrated access.

**Result:** All four directed testbenches pass in Vivado. Statement/branch/toggle code coverage was **not collected** for these testbenches — Vivado's coverage flow was not run as part of this project. If you need these numbers, run Vivado's `xsim`/coverage flow (`-cov` options) separately; this repo does not currently include that data.

---

## 4. UVM Testbench — Scoreboard Design

The scoreboard (`arb_scoreboard` in `arb_pkg.sv`) is a **self-checking reference model**, not a simple output comparator. It independently predicts:

- **Round Robin grant** (`predict_rr`): combinational, based on current `req` and a locally-tracked `rr_ptr` mirror
- **Fixed Priority + Aging grant** (`predict_fp`): based on the *previous* cycle's `req` and a locally-tracked `ages[]` mirror, because the DUT's FP arbiter output is registered (1-cycle latency relative to `req`)
- **One-hot property**: checked every cycle regardless of mode

The reference model tracks `rr_ptr` and `ages[]` state independently of the DUT and advances them every cycle using the same rules as the RTL (see comments in `arb_pkg.sv` for the exact timing model — this was the trickiest part to get right, since the RR arbiter is combinational but the FP arbiter is registered).

### 4.1 Scoreboard Checks

| Check | Function | Purpose |
|-------|----------|---------|
| One-hot grant | `check_one_hot` | `grant` must have 0 or exactly 1 bit set, every cycle |
| RR correctness | `check_rr` | DUT grant matches `predict_rr(req, rr_ptr)` in RR mode |
| FP correctness | `check_fp` | DUT grant matches `predict_fp(prev_req, ages)` in FP mode |

---

## 5. UVM Test Scenarios

| Test | Sequence | What it Checks |
|------|----------|-----------------|
| `arb_base_test` | `arb_rand_seq` — 30 fully randomized transactions | Broad random coverage of req patterns, modes, hold cycles |
| `arb_rr_test` | `arb_rr_all_seq` — 16 transactions, all masters requesting, RR mode, hold=1 | Round-robin fairness/rotation under full contention |
| `arb_fp_test` | `arb_fp_starvation_seq` — 20 transactions, M0+M3 requesting, FP mode | Aging mechanism: M0 wins initially, M3 should age out and win |
| `arb_mode_test` | `arb_mode_switch_seq` — 10 transactions RR mode, then 10 transactions FP mode | Correct behavior across a mode transition |

---

## 6. UVM Results (Confirmed — EDA Playground, Xcelium 25.03)

| Test | Scoreboard | Functional Coverage | Result |
|------|-----------|---------------------|--------|
| `arb_rr_test` | PASS=50, FAIL=0 | 38.29% | ✅ PASSED |
| `arb_fp_test` | PASS=57, FAIL=0 | 32.29% | ✅ PASSED |
| `arb_mode_test` | PASS=102, FAIL=0 | 74.86% | ✅ PASSED |
| `arb_base_test` | PASS=156, FAIL=0 | 82.00% | ✅ PASSED |

**Notes on these numbers:**
- "PASS"/"FAIL" counts are the scoreboard's cumulative check count across `check_one_hot`, `check_rr`, and `check_fp` for that test run — not one count per transaction, since multiple checks can fire per cycle.
- Coverage % is from the `arb_coverage` covergroup (`cp_mode`, `cp_req`, `cp_grant`, and their two cross bins), sampled once per monitored transaction, for that test in isolation.
- Coverage is lower for `arb_rr_test` and `arb_fp_test` because each drives a narrow, fixed scenario (all-masters-RR, or M0+M3-only-FP) by design — they are not intended to hit every bin. `arb_base_test`'s fully random sequence reaches the highest coverage (82.00%) because it samples the widest variety of `req`/`mode`/`grant` combinations.
- These are **per-test** coverage numbers, not a merged/cumulative regression coverage. Combining all 4 tests into one regression run (a `arb_regression_test` wrapping all four sequences, or running all four back-to-back and merging coverage databases) would produce a higher combined number, but this was not done — see "Future Work" in `DESIGN_SPECS.md`.

---

## 7. Known Bug Found During Verification

The UVM bring-up on Xcelium (via EDA Playground) surfaced a compile-time issue in the original `round_robin_arbiter.sv` that had not appeared under Vivado:

- Local variable (`idx`) declared inside an `always_comb` block — rejected by Xcelium, accepted by Vivado
- `idx` was only 2 bits wide, making its `>= 4` wraparound check unreachable dead code

Both are fixed in the version of `round_robin_arbiter.sv` in this repo. Full details, including why the bug didn't cause a functional mismatch in Vivado (modulo-4 truncation happened to produce correct results despite the dead branch), are in `CHANGELOG.md`.

---

## 8. Regression Checklist

### 8.1 Directed (Vivado)
- [x] Round Robin: no request / single / multiple / all-4 / de-assert / reset / burst
- [x] Fixed Priority + Aging: single / static priority / starvation-aging
- [x] Top-level: RR mode / FP mode / mode switching / simultaneous requests
- [x] AXI Lite: write / read / multi-master contention

### 8.2 UVM (EDA Playground, Xcelium 25.03)
- [x] `arb_base_test` — random stimulus, 0 failures, 82.00% coverage
- [x] `arb_rr_test` — RR fairness, 0 failures, 38.29% coverage
- [x] `arb_fp_test` — aging/starvation, 0 failures, 32.29% coverage
- [x] `arb_mode_test` — mode switching, 0 failures, 74.86% coverage
- [ ] Merged/cumulative coverage across all 4 tests (not done)
- [ ] Directed testbenches re-run on a second simulator to confirm portability (not done)

---

## 9. Sign-Off Criteria

Verification considered complete for this repo when:
- ✓ All directed testbenches pass in Vivado
- ✓ All 4 UVM tests pass in Xcelium 25.03 (EDA Playground), 0 scoreboard failures
- ✓ Known RTL bug found during verification is documented and fixed
- ✓ Documentation accurately reflects which tool ran which test (this document)

---

**Verification Plan Prepared By:** [Your Name]
**Last Updated:** [Date]
**Status:** Complete for the tools/tracks listed above
