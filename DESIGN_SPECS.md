# Design Specification: AXI Arbiter System

## Document Information
- **Project:** Design and Verification of an AXI Arbiter
- **Version:** 2.0
- **Status:** Final
- **Date:** [Date]

---

## 1. Functional Specification

### 1.1 System Overview

The AXI Arbiter is a multi-master arbitration unit that prioritizes requests from up to 4 masters and grants exclusive bus access according to selectable arbitration policies.

### 1.2 Arbitration Policies

#### 1.2.1 Round Robin (Mode = 0)
- **Algorithm:** Circular priority rotation
- **Latency:** O(1) combinational
- **Fairness:** Equal bandwidth per master
- **Use Case:** Multi-master systems requiring fair resource allocation

**Priority Rotation Example:**
```
Cycle 1: Master 0 granted  → Next pointer = 1
Cycle 2: Master 2 granted  → Next pointer = 3
Cycle 3: Master 3 granted  → Next pointer = 0
Cycle 4: Master 0 granted  → Next pointer = 1
```

#### 1.2.2 Fixed Priority with Aging (Mode = 1)
- **Static Priority:** Master 0 > Master 1 > Master 2 > Master 3
- **Starvation Prevention:** Age counter mechanism
- **Aging Threshold:** Fixed (saturates at age value 3 in the current `age_counter` implementation)
- **Use Case:** Systems with quality-of-service requirements and guaranteed latency bounds

**Aging Mechanism:**
```
Each cycle a master requests but is not granted, its age counter increments
(saturating at the max value). When a master's age reaches the saturation
value, it is granted ahead of the normal fixed-priority order. The age
counter resets to 0 the cycle after that master is granted.
```

### 1.3 Interface Specification

#### Inputs
| Signal | Width | Description |
|--------|-------|-------------|
| `clk` | 1 | System clock |
| `reset` | 1 | Active-high synchronous reset |
| `req[3:0]` | 4 | Request signals from 4 masters |
| `mode` | 1 | Arbitration mode selector (0=RR, 1=FP+Aging) |

#### Outputs
| Signal | Width | Description |
|--------|-------|-------------|
| `grant[3:0]` | 4 | One-hot grant signal for winning master |

### 1.4 Protocol Properties

#### Mutual Exclusion
- At most one grant signal asserted per cycle
- `grant` is one-hot encoded: only one bit high
- Checked every cycle by the UVM scoreboard's `check_one_hot` function

#### Request Validity
- Request valid during the cycle relevant to the arbiter's timing (Round Robin grant is combinational on the current-cycle request; Fixed Priority + Aging grant is registered, based on the previous cycle's request — see Section 2.3)

#### Reset Behavior
- Synchronous reset clears all internal state
- `grant` deasserts on reset
- No master preferentially favored after reset

---

## 2. Architecture & Design

### 2.1 Hierarchical Structure

```
axi_arbiter_top
├─ round_robin_arbiter
│  └─ Priority rotation logic
├─ fixed_priority_aging_arbiter
│  ├─ age_counter (4 instances)
│  └─ Fixed priority + aging logic
└─ mode_selector
   └─ Output multiplexer
```

### 2.2 Module Descriptions

#### axi_arbiter_top
- **Purpose:** Top-level integration
- **Logic:** Instantiates both arbiters and mode selector

#### round_robin_arbiter
- **Purpose:** Fair arbitration
- **State:** Pointer register `ptr_q` (2 bits, for 4 masters)
- **Algorithm:** Combinational scan starting from `ptr_q`, awarding the first requesting master found; pointer advances to (winner + 1) every clock cycle
- **Output:** One-hot grant, combinational on current `req` and `ptr_q`
- **Note:** See `CHANGELOG.md` for a bug found and fixed in this module's internal `idx` signal (scope and bit-width) during UVM bring-up on Xcelium

#### fixed_priority_aging_arbiter
- **Purpose:** Priority-based arbitration with fairness
- **Components:**
  - Static priority comparator
  - Age counter for each master (`age_counter` × 4)
  - Priority override logic when a master's age saturates
- **Output:** One-hot grant, registered (1-cycle latency relative to `req`)

#### age_counter
- **Purpose:** Track request age per master
- **Behavior:**
  - Increments when that master requests and is not granted
  - Resets to 0 the cycle after that master is granted
  - Saturates at its maximum representable value (does not wrap)

#### mode_selector
- **Purpose:** Multiplex arbitration outputs
- **Logic:** Combinational mux based on `mode` signal

#### axi_lite_arbiter_wrapper
- **Purpose:** AXI Lite protocol interface
- **Features:** Read and write address channels, write data channel, read data and write response channels, protocol compliance checking (exercised by `tb_axi_lite_arbiter_wrapper.sv`)

---

## 3. Verification Approach (Summary)

This project has two independent verification efforts. Full detail is in `VERIFICATION_PLAN.md`.

1. **Directed SystemVerilog testbenches** — one per module plus a top-level integration testbench — run in **Vivado**.
2. **UVM testbench** — sequence-item driven, with a self-checking scoreboard (independent reference model for both RR and FP+Aging grants) and functional coverage — run on **EDA Playground using Xcelium 25.03**. Confirmed results:

   | Test | Scoreboard | Coverage | Result |
   |------|-----------|----------|--------|
   | `arb_rr_test` | PASS=50, FAIL=0 | 38.29% | ✅ PASSED |
   | `arb_fp_test` | PASS=57, FAIL=0 | 32.29% | ✅ PASSED |
   | `arb_mode_test` | PASS=102, FAIL=0 | 74.86% | ✅ PASSED |
   | `arb_base_test` | PASS=156, FAIL=0 | 82.00% | ✅ PASSED |

---

## 4. Implementation Notes

### 4.1 Synthesis Considerations
- Round Robin grant path is fully combinational
- Fixed Priority + Aging grant path is registered (1-cycle latency)
- No latches (all `always_comb` blocks fully assign outputs on every path)

### 4.2 Simulation Requirements
- `round_robin_arbiter.sv` uses `` `timescale 1ns/1ps ``
- Directed testbenches: run and passing in **Vivado**
- UVM testbench: run and passing in **Xcelium 25.03** (via EDA Playground)
- Portability to other simulators (ModelSim, VCS, standalone Xcelium, etc.) has not been tested

### 4.3 FPGA Considerations
- Pin constraints provided in `fpga_top.xdc`
- Resource utilization and Fmax have not been characterized in this repo (no synthesis/implementation results included)

---

## 5. Verification Checklist

- [x] Directed testbenches implemented and passing in Vivado
- [x] UVM testbench implemented and passing in Xcelium 25.03 (EDA Playground), 4/4 tests, 0 scoreboard failures
- [x] Self-checking scoreboard with independent RR + FP reference models
- [x] One-hot grant property checked every cycle
- [x] Functional coverage collected per UVM test
- [x] Round-robin bug (idx scope/width) found via cross-simulator UVM bring-up and fixed
- [ ] Statement/branch/toggle code coverage for directed testbenches (not collected)
- [ ] Cross-simulator confirmation of directed testbenches (Vivado-only so far)

---

## 6. Known Limitations & Future Work

### Current Limitations
1. Fixed 4-master arbiter (not parameterized)
2. AXI Lite only (AXI Full not implemented)
3. Fixed aging saturation value (not configurable via register)
4. Directed testbenches confirmed in Vivado only; UVM testbench confirmed in Xcelium 25.03 (EDA Playground) only
5. No statement/branch/toggle coverage collected for directed testbenches

### Future Enhancements
1. Parameterized master count
2. AXI Full protocol support
3. Programmable aging threshold
4. Combine the 4 UVM tests into a single regression run for cumulative coverage
5. Confirm directed testbenches on additional simulators
6. SystemVerilog Assertions (SVA) for formal properties

---

## 7. References & Standards

- [AMBA AXI Protocol Specification](https://developer.arm.com/documentation/ihi0022/e/)
- [AMBA AXI Lite Protocol Specification](https://developer.arm.com/documentation/ihi0022/latest/)
- IEEE 1800-2017: SystemVerilog Language Reference Manual
- Accellera UVM 1.2

---

**Document Prepared By:** [Your Name]
**Review Status:** Complete
**Approval Date:** [Date]
