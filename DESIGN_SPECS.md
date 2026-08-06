# Design Specification: AXI Arbiter System

## Document Information
- **Project:** Design and Verification of an AXI Arbiter
- **Version:** 1.0
- **Status:** Final
- **Date:** 2024

---

## 1. Functional Specification

### 1.1 System Overview

The AXI Arbiter is a multi-master arbitration unit that prioritizes requests from up to 4 masters and grants exclusive bus access according to selectable arbitration policies.

### 1.2 Arbitration Policies

#### 1.2.1 Round Robin (Mode = 0)
- **Algorithm:** Circular priority rotation
- **Latency:** O(1) combinatorial
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
- **Aging Threshold:** Configurable per implementation
- **Use Case:** Systems with quality-of-service requirements and guaranteed latency bounds

**Aging Mechanism:**
```
If request pending for > N cycles:
    Request priority = min(age_level, MAX_PRIORITY)
    Prevents indefinite starvation of low-priority masters
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

#### Request Validity
- Request valid during same cycle as grant
- Request can remain asserted across multiple cycles
- No grant removal delay required

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
- **Timing:** Combinatorial path from req → grant
- **Lines of Code:** ~45

#### round_robin_arbiter
- **Purpose:** Fair arbitration
- **State:** Pointer register (2 bits for 4 masters)
- **Algorithm:** Sequential scanning from pointer position
- **Output:** One-hot grant

#### fixed_priority_aging_arbiter
- **Purpose:** Priority-based arbitration with fairness
- **Components:**
  - Static priority comparator
  - Age counter for each master
  - Priority override logic
- **Output:** One-hot grant

#### age_counter
- **Purpose:** Track request age
- **Behavior:** 
  - Increments when master requests and not granted
  - Resets when master granted
  - Saturates at max value
- **Bit Width:** 4 bits (0-15 cycles max age)

#### mode_selector
- **Purpose:** Multiplex arbitration outputs
- **Logic:** Combinatorial mux based on mode signal
- **Timing:** Zero propagation delay

#### axi_lite_arbiter_wrapper
- **Purpose:** AXI Lite protocol interface
- **Bus Width:** 32-bit address, 32-bit data
- **Features:**
  - Read and write address channels
  - Write data channel
  - Read data and write response channels
  - Protocol compliance checking

---

## 3. Verification Plan

### 3.1 Test Strategy

#### Unit Level (Module Verification)
1. **Round Robin Arbiter**
   - Fairness: Each master granted equal cycles
   - Rotation: Pointer advances correctly
   - Edge cases: Single requester, no requesters, reset during grant

2. **Fixed Priority Arbiter**
   - Priority enforcement: Higher priority always wins
   - Aging activation: Lower priority granted after aging
   - Starvation prevention: All masters get grant within max_age cycles

3. **Age Counter**
   - Increment behavior: Counter increments when no grant
   - Reset behavior: Counter clears on grant
   - Saturation: Counter doesn't overflow

#### Integration Level (System Verification)
1. **Mode Switching**
   - Seamless transition between RR and FP modes
   - No spurious grants during mode switch
   - Output stability maintained

2. **Multi-Master Scenarios**
   - 2-way, 3-way, 4-way simultaneous requests
   - Burst requests (many consecutive cycles)
   - Random request patterns

3. **AXI Lite Compliance**
   - Write transaction sequences
   - Read transaction sequences
   - Back-to-back transactions
   - Response ordering

### 3.2 Test Coverage

#### Functional Coverage
- All arbitration modes exercised
- All grant patterns (0000 to 1111) verified
- Mode transitions covered
- Reset scenarios verified

#### Code Coverage
- Statement coverage: >95%
- Branch coverage: >90%
- Toggle coverage: >85%

### 3.3 Test Scenarios

**Scenario 1: Round Robin Fairness**
```
Requests: All 4 masters continuously requesting
Expected: Each master granted every 4 cycles
```

**Scenario 2: Fixed Priority Static**
```
Requests: Masters 0, 2, 3 requesting (not 1)
Expected: Master 0 always granted
```

**Scenario 3: Fixed Priority Aging**
```
Requests: Master 3 alone, then add Masters 0
Timeline:
  Cycles 1-5:  Master 3 granted
  Cycles 6+:   Master 3 age >= threshold
  Cycles 7+:   Aging priority high, Master 3 still granted
  Add Master 0 requesting at cycle 8
  Expected: Master 3 still granted due to age
```

**Scenario 4: Mode Switching**
```
Cycle 1:  mode=0 (RR), master 0 granted
Cycle 2:  mode=1 (FP), should show FP grants
Cycle 3:  mode=0 (RR), back to RR grants
```

**Scenario 5: Reset**
```
Running grants, then assert reset
Expected: All state clears, no grant on next cycle
```

---

## 4. Implementation Notes

### 4.1 Synthesis Considerations
- All logic fully combinatorial (grant path)
- No latches or uninitialized variables
- Clock gating avoided for simplicity
- Readily synthesizable in any standard library

### 4.2 Simulation Requirements
- Timescale: `1ns/1ps`
- No blocking assignments in clock domain
- Consistent use of `logic` data types

### 4.3 FPGA Considerations
- Resource utilization: Minimal (few LUTs)
- Fmax: Achievable >100 MHz for typical FPGA
- Pin constraints: Provided in `fpga_top.xdc`

---

## 5. Verification Checklist

- [x] Specification complete
- [x] Block-level verification done
- [x] Integration testing complete
- [x] AXI Lite compliance verified
- [x] Edge cases covered
- [x] Reset behavior validated
- [x] Starvation prevention confirmed
- [x] Documentation finalized

---

## 6. Known Limitations & Future Work

### Current Limitations
1. Fixed 4-master limitation (parameterization possible)
2. AXI Lite only (AXI Full requires expanded address handling)
3. Fixed aging threshold (could be made programmable)

### Future Enhancements
1. Parameterized master count
2. AXI Full protocol support
3. Programmable aging threshold via configuration registers
4. QoS-based priority adjustment
5. SystemVerilog Assertions (SVA) for formal verification

---

## 7. References & Standards

- [AMBA AXI Protocol Specification](https://developer.arm.com/documentation/ihi0022/e/)
- [AMBA AXI Lite Protocol Specification](https://developer.arm.com/documentation/ihi0022/latest/)
- IEEE 1800-2017: SystemVerilog Language Reference Manual
- Accellera UVM 1.2 Documentation

---

**Document Prepared By:** Design & Verification Team  
**Review Status:** Complete  
**Approval Date:** 2024
