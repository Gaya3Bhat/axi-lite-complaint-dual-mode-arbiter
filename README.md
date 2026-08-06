# Design, Verification, and FPGA Implementation of a Configurable Dual-Mode AXI-Lite Arbiter

A comprehensive RTL design and verification project for a configurable AXI arbiter with multiple arbitration schemes. This project demonstrates advanced SystemVerilog design, testbench development, and verification methodologies.

## 🎯 Project Overview

This project implements an AXI-compliant arbiter supporting two arbitration modes:
- **Round Robin (RR):** Fair allocation with rotating priority
- **Fixed Priority with Aging:** High-priority enforcement with aging mechanism to prevent starvation

The arbiter is designed for multi-master AXI systems and includes an AXI Lite wrapper for simplified integration.

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

## 📁 Project Structure

### Design Files
- **`axi_arbiter_top.sv`** (45 lines)  
  Top-level module orchestrating RR and FP arbiters with mode selection

- **`round_robin_arbiter.sv`**  
  Implements rotating priority arbiter ensuring fair resource allocation

- **`fixed_priority_aging_arbiter.sv`**  
  Fixed priority scheme with aging logic to prevent request starvation

- **`age_counter.sv`**  
  Implements aging counter for starvation prevention

- **`mode_selector.sv`**  
  Multiplexer selecting between arbitration outputs

- **`axi_lite_arbiter_wrapper.sv`** (166 lines)  
  AXI Lite-compliant wrapper interfacing with AXI bus transactions

- **`fpga_top.sv`** + **`fpga_top.xdc`**  
  FPGA top-level design and pin constraints

### Verification Files
- **`tb_axi_arbiter_top.sv`**  
  Testbench for top-level arbiter with comprehensive test cases

- **`tb_round_robin_arbiter.sv`**  
  Round robin arbiter testbench verifying fairness properties

- **`tb_fixed_priority_aging_arbiter.sv`**  
  Fixed priority arbiter testbench with starvation scenarios

- **`tb_axi_lite_arbiter_wrapper.sv`** (400+ lines)  
  Comprehensive AXI Lite testbench with protocol compliance checks

## 🔬 Verification Methodology

### Testbench Coverage
- **Functional Coverage:** All arbitration modes and grant scenarios
- **Protocol Verification:** AXI Lite transaction compliance
- **Corner Cases:** Simultaneous requests, starvation detection, mode switching
- **Error Scenarios:** Invalid states and edge conditions

### Test Scenarios Implemented
1. **Round Robin Fairness**
   - Sequential request patterns
   - Priority rotation verification
   
2. **Fixed Priority + Aging**
   - High-priority request handling
   - Aging mechanism activation
   - Starvation prevention validation
   
3. **Multi-Master Contention**
   - 4-way simultaneous requests
   - Grant exclusivity verification
   
4. **Mode Switching**
   - Runtime arbitration policy changes
   - State coherency during transitions

5. **AXI Lite Protocol**
   - Read/Write address channel compliance
   - Response channel validation
   - Burst transaction handling

## 🚀 Getting Started

### Prerequisites
- SystemVerilog simulator (ModelSim, VCS, Xcelium, or similar)
- Waveform viewer (GTKWave, Verdi, or similar)

### Running Simulations

#### Compile and Simulate
```bash
# Using ModelSim example
vlog axi_arbiter_top.sv round_robin_arbiter.sv fixed_priority_aging_arbiter.sv \
     age_counter.sv mode_selector.sv
vlog tb_axi_arbiter_top.sv
vsim -c work.tb_axi_arbiter_top -do "run -all; quit"
```

#### View Waveforms
```bash
vsim work.tb_axi_arbiter_top
# In simulation: run -all
# View signals in waveform viewer
```

### Expected Outputs
- Comprehensive testbench output showing all test cases passing
- Waveforms demonstrating:
  - Grant signals exclusive and valid
  - Round robin rotation behavior
  - Aging mechanism preventing starvation
  - AXI Lite protocol compliance

## 📊 Design Metrics

| Metric | Value |
|--------|-------|
| Total RTL Lines | ~250 lines |
| Total Testbench Lines | ~800+ lines |
| Number of Modules | 7 |
| Test Cases | 15+ scenarios |
| Arbitration Schemes | 2 |

## 🛠️ Implementation Details

### Round Robin Arbiter
- Maintains rotating priority pointer
- Updates pointer after each grant
- O(1) arbitration latency
- Fair bandwidth distribution

### Fixed Priority + Aging
- 4-level static priority: Master 0 > 1 > 2 > 3
- Aging counter increments for pending requests
- When age exceeds threshold, priority overrides static levels
- Prevents indefinite starvation

### Mode Selector
- Combinatorial mux selecting arbiter output
- Real-time mode switching capability
- No clock gating or glitch generation

## 📝 Verification Checklist

- [x] Functional simulation passing
- [x] All arbitration modes validated
- [x] Starvation prevention verified
- [x] Grant signal exclusivity checked
- [x] AXI Lite protocol compliance confirmed
- [x] Edge cases and corner cases covered
- [x] Reset behavior validated
- [x] Mode switching robustness tested

## 🎓 Learning Outcomes

This project demonstrates proficiency in:

- **RTL Design:** Modular design, hierarchical architecture, state machines
- **SystemVerilog:** Advanced language features, assertions, randomization
- **Verification:** Comprehensive testbenches, self-checking tests, coverage metrics
- **AXI Protocol:** Master/slave transactions, handshaking, protocol compliance
- **FPGA:** Design implementation, constraints, resource mapping
- **Professional Documentation:** Code comments, design specs, test plans

## 💡 Future Enhancements

- [ ] Formal verification (property-based assertions)
- [ ] Coverage-driven testbench improvements
- [ ] Performance analysis and optimization
- [ ] Extended AXI Full protocol support
- [ ] Pipelining for higher throughput
- [ ] SystemVerilog Assertions (SVA) integration

## 📚 References

- AMBA AXI Protocol Specification v1.0
- AMBA AXI Lite Protocol Specification
- SystemVerilog IEEE 1800-2017

## 📄 License

This project is provided as-is for educational and portfolio purposes.

---

**Author:** [Your Name]  
**Last Updated:** [Date]  
**Status:** Complete ✓
