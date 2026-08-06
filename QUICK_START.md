# Quick Start Guide: AXI Arbiter

Get up and running with the AXI Arbiter project in 5 minutes.

## 📋 Prerequisites

Ensure you have installed:
- **SystemVerilog Simulator:** ModelSim, VCS, Xcelium, or Vivado Simulator
- **Waveform Viewer:** GTKWave (free), Verdi, or ModelSim's built-in viewer

```bash
# Check ModelSim installation (if using ModelSim)
which vsim
```

---

## 🚀 Quick Simulation

### Using ModelSim (Recommended for beginners)

#### 1. Compile All Design Files
```bash
cd /path/to/axi-arbiter

vlog axi_arbiter_top.sv \
     round_robin_arbiter.sv \
     fixed_priority_aging_arbiter.sv \
     age_counter.sv \
     mode_selector.sv
```

#### 2. Compile & Run Top-Level Testbench
```bash
vlog tb_axi_arbiter_top.sv
vsim -c work.tb_axi_arbiter_top -do "run -all; quit"
```

**Expected Output:**
```
# ===== AXI Arbiter Testbench =====
# Test: Round Robin Mode
# [RR] Request pattern: 4'b1111, Grant: 4'b0001
# [RR] Request pattern: 4'b1111, Grant: 4'b0010
# ===== All tests PASSED =====
```

#### 3. Compile & Run Individual Unit Tests

**Round Robin Arbiter:**
```bash
vlog tb_round_robin_arbiter.sv
vsim -c work.tb_round_robin_arbiter -do "run -all; quit"
```

**Fixed Priority with Aging:**
```bash
vlog tb_fixed_priority_aging_arbiter.sv
vsim -c work.tb_fixed_priority_aging_arbiter -do "run -all; quit"
```

**AXI Lite Wrapper:**
```bash
vlog axi_lite_arbiter_wrapper.sv
vlog tb_axi_lite_arbiter_wrapper.sv
vsim -c work.tb_axi_lite_arbiter_wrapper -do "run -all; quit"
```

---

### Using VCS (Synopsys)

```bash
# Compile
vcs -full64 -sverilog axi_arbiter_top.sv round_robin_arbiter.sv \
    fixed_priority_aging_arbiter.sv age_counter.sv mode_selector.sv \
    tb_axi_arbiter_top.sv

# Simulate
./simv
```

---

### Using Vivado Simulator

```bash
# Create Vivado project (via GUI or command line)
vivado -mode batch -source create_project.tcl

# Run simulation from Vivado
# Or use xsim directly:
xvlog axi_arbiter_top.sv round_robin_arbiter.sv ...
xsim work.tb_axi_arbiter_top -g "runtime=1us"
```

---

## 📊 View Waveforms

### Option 1: Generate VCD File

Modify testbench to save waveforms:
```systemverilog
initial begin
  $dumpfile("arbiter_wave.vcd");
  $dumpvars(0, tb_axi_arbiter_top);
end
```

Then run simulation and view with GTKWave:
```bash
gtkwave arbiter_wave.vcd
```

### Option 2: Interactive Simulation (ModelSim GUI)

```bash
# Run ModelSim in GUI mode (no -c flag)
vsim work.tb_axi_arbiter_top

# In ModelSim window:
# 1. View → New Wave Window
# 2. Add signals you want to watch
# 3. Run → Run All (or step through)
```

---

## 🔍 Key Signals to Monitor in Waveform

```
Timebase: 1ns
Signals to add:
├── clk           (System clock)
├── reset         (Reset signal)
├── req[3:0]      (Master requests)
├── mode          (Arbitration mode: 0=RR, 1=FP+Aging)
├── grant[3:0]    (Arbiter grant output)
├── age[*]        (Age counters, if FP mode)
└── priority_ptr  (Priority pointer, if RR mode)
```

---

## 📚 File Organization

```
axi-arbiter/
├── README.md                          ← Start here for overview
├── QUICK_START.md                     ← This file
├── DESIGN_SPECS.md                    ← Detailed architecture
├── VERIFICATION_PLAN.md               ← Test methodology
│
├── Design Files/
│   ├── axi_arbiter_top.sv             ← Top-level module
│   ├── round_robin_arbiter.sv         ← RR arbitration
│   ├── fixed_priority_aging_arbiter.sv ← FP+Aging arbitration
│   ├── age_counter.sv                 ← Aging mechanism
│   ├── mode_selector.sv               ← Mode multiplexer
│   ├── axi_lite_arbiter_wrapper.sv    ← AXI Lite interface
│   ├── fpga_top.sv                    ← FPGA top-level
│   └── fpga_top.xdc                   ← FPGA constraints
│
├── Testbenches/
│   ├── tb_axi_arbiter_top.sv
│   ├── tb_round_robin_arbiter.sv
│   ├── tb_fixed_priority_aging_arbiter.sv
│   └── tb_axi_lite_arbiter_wrapper.sv
│
└── .gitignore                         ← Git ignore rules
```

---

## ✅ Verification Checklist

Run these to verify everything works:

- [ ] Round Robin fairness test passes
- [ ] Fixed Priority enforcement verified
- [ ] Aging mechanism active after N cycles
- [ ] No spurious grants during mode switching
- [ ] AXI Lite protocol transactions complete
- [ ] Reset clears all state correctly
- [ ] All waveforms show expected behavior

---

## 🐛 Troubleshooting

### Compilation Errors

**Error:** `Undefined module/signal`
```
Solution: Ensure all files are compiled in dependency order
vlog axi_arbiter_top.sv round_robin_arbiter.sv ... tb_*.sv
```

**Error:** `Timescale mismatch`
```
Solution: All files must use same timescale
Ensure: `timescale 1ns/1ps at top of each file
```

### Simulation Crashes

**Error:** `Simulation stops with no output`
```
Solution: Add $finish in testbench
  initial #10000 $finish;  // 10 microseconds timeout
```

**Error:** `Signal not showing in waveform`
```
Solution: Make sure $dumpvars includes the signal hierarchy
  $dumpvars(0, tb_axi_arbiter_top);  // depth 0 = full hierarchy
```

---

## 🎯 Next Steps

1. **Run all tests:** Follow simulation commands above
2. **Read documentation:** Check DESIGN_SPECS.md for architecture
3. **Study verification:** Review VERIFICATION_PLAN.md for test methodology
4. **Modify & experiment:** Try changing arbitration logic and see effects
5. **Synthesize (Optional):** Run through your FPGA tool flow

---

## 📝 Common Modifications

### Change Aging Threshold
In `fixed_priority_aging_arbiter.sv`, find:
```systemverilog
localparam MAX_AGE = 8;  // Change this value
```

### Increase Master Count
In `axi_arbiter_top.sv`, expand:
```systemverilog
input  logic [N-1:0]  req;
output logic [N-1:0]  grant;
```

### Add Custom Signals for Debugging
In testbenches, add:
```systemverilog
always @(posedge clk) begin
  $display("Cycle %0d: req=%b, grant=%b", $time, req, grant);
end
```

---

## 📞 Support

For detailed information:
- **Architecture:** See `DESIGN_SPECS.md`
- **Verification:** See `VERIFICATION_PLAN.md`
- **Testing:** See individual testbench comments
- **Constraints:** See `fpga_top.xdc`

---

**Last Updated:** 2024  
**Status:** Ready for simulation ✓
