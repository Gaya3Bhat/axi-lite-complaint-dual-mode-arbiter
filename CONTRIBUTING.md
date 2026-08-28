# Contributing to AXI Arbiter Project

This project welcomes contributions and suggestions from the hardware design and verification community. This document outlines guidelines for contributing.

## Code of Conduct

- Be respectful and professional in all communications
- Focus on technical merit and design correctness
- Provide constructive feedback
- Acknowledge and credit contributions

## Getting Started

### Setting Up Your Development Environment

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/axi-arbiter.git
cd axi-arbiter

# Create a feature branch
git checkout -b feature/your-feature-name
```

### Tools Used in This Project

- **Vivado** — RTL design + directed testbench simulation (confirmed working)
- **EDA Playground with Xcelium 25.03** — UVM testbench simulation (confirmed working)
- Git version control
- Text editor or IDE (VS Code, Vim, etc.)

If you test this project on a different simulator (ModelSim, VCS, a standalone Xcelium install, etc.), please open an issue or PR noting the results — portability beyond the two tools above has not been confirmed.

---

## Contribution Types

### 1. Bug Reports

Found an issue? Please report it by:

1. Checking if the issue already exists
2. Creating a clear title: `[BUG] Brief description`
3. Including:
   - Which testbench (directed or UVM) and which tool (Vivado / Xcelium via EDA Playground / other)
   - Expected vs actual behavior
   - Steps to reproduce
   - Simulator version used
   - Relevant waveforms/logs

**Example (based on a real bug found in this project):**
```
Title: [BUG] round_robin_arbiter fails to compile under Xcelium

Simulator: Xcelium 25.03 (EDA Playground)
Behavior: always_comb block declares a local variable (idx) inside the
          loop body. Xcelium rejects this; Vivado accepted it.

Steps:
1. Load round_robin_arbiter.sv into EDA Playground design panel
2. Compile with Xcelium 25.03
3. Compilation error on `idx` declaration

Expected: Clean compile
Actual: Compile error — see CHANGELOG.md for the fix applied (B1, B2)
```

### 2. Feature Requests

Suggest improvements via issues:

- `[FEATURE] Parameterized master count`
- `[FEATURE] Programmable aging threshold`
- `[ENHANCEMENT] Merge UVM tests into one regression with combined coverage`
- `[ENHANCEMENT] Confirm directed testbenches on ModelSim/VCS`

Include:
- Motivation/use case
- Proposed implementation (if applicable)
- Potential impact on performance/area

### 3. Code Contributions

Contributing code changes? Follow these guidelines:

#### Before You Start
- Review `DESIGN_SPECS.md` for architecture
- Review `VERIFICATION_PLAN.md` for testing approach
- Run the directed testbenches in Vivado and/or the UVM testbench on EDA Playground (Xcelium) — whichever your change affects — and confirm no regressions
- Check for similar PRs already in progress

#### Code Style

**Naming Conventions:**
```systemverilog
// Modules: lowercase with underscores
module round_robin_arbiter (...)

// Ports: lowercase with underscores
input  logic        clk,
input  logic [3:0]  req,
output logic [3:0]  grant

// Internal signals: lowercase with underscores
logic [3:0]  grant_rr;
logic        grant_valid;

// Parameters: UPPERCASE
localparam NUM_MASTERS = 4;

// UVM classes: prefix with arb_
class arb_seq_item extends uvm_sequence_item;
```

**Formatting:**
```systemverilog
// Use 2-space indentation
module example (
  input  logic  clk,
  input  logic  reset
);
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      counter <= '0;
    end else begin
      counter <= counter + 1;
    end
  end
endmodule
```

**Comments:**
```systemverilog
// Explain WHY, not WHAT — and note which tool/version surfaced
// an issue if the code works around a simulator-specific behavior.

// Example from this project's actual fix:
// FIX B1: declare idx at MODULE scope, not inside always_comb
// (Xcelium rejects local declarations inside always_comb; Vivado allowed it)
logic [2:0] idx;
```

**Declarations inside `always_comb`:** Do not declare local variables inside `always_comb` procedural blocks — this compiles under Vivado but was rejected by Xcelium during this project's UVM bring-up. Declare at module scope instead.

#### Testing Requirements

All code changes must include:

1. **Updated testbench(es)** — directed and/or UVM, depending on what you changed
2. **Actual run results**, e.g.:
   ```
   Tool: Vivado (or EDA Playground / Xcelium 25.03)
   tb_round_robin_arbiter: PASS
   arb_rr_test: PASS=xx, FAIL=0, Coverage=xx.xx%
   ```
   Report only numbers you actually observed from a run — do not estimate or invent coverage/pass numbers.
3. **Regression note** — confirm existing directed testbenches / UVM tests still pass after your change

#### Documentation

Update relevant documentation:

- **Code changes:** Update `DESIGN_SPECS.md`
- **New features:** Add section in `README.md`
- **Test changes:** Update `VERIFICATION_PLAN.md`
- **Bug fixes:** Add an entry to `CHANGELOG.md`, following the format used for the existing round-robin bug (what broke, which tool caught it, what the fix was)

---

## Pull Request Process

### 1. Prepare Your Branch

```bash
git checkout main
git pull origin main
git checkout -b feature/meaningful-name

# Make your changes, then test locally (Vivado and/or EDA Playground)
```

### 2. Commit Changes

```bash
git add .
git commit -m "feat: add parameterized master count

- Modified axi_arbiter_top to accept NUM_MASTERS parameter
- Updated all submodules to support variable count
- Re-ran tb_axi_arbiter_top in Vivado: PASS
- Re-ran arb_base_test on EDA Playground (Xcelium 25.03): PASS=xx, FAIL=0

Closes #123"
```

**Commit Format:**
```
type(scope): short description (50 chars max)

Detailed explanation (wrap at 72 chars)
- Bullet point 1
- Bullet point 2 (include actual test results, not estimates)

Fixes #issue_number
```

**Types:** `feat`, `fix`, `refactor`, `test`, `docs`, `style`

### 3. Push to Your Fork

```bash
git push origin feature/meaningful-name
```

### 4. Create Pull Request on GitHub

**PR Description Template:**
```markdown
## Description
Brief summary of changes

## Motivation & Context
Why is this change needed? What problem does it solve?

## Testing Done
- Tool(s) used: [Vivado / EDA Playground-Xcelium 25.03 / other — specify]
- [ ] Directed testbench(es) affected: [list] — result: PASS/FAIL
- [ ] UVM test(s) affected: [list] — PASS=xx, FAIL=xx, Coverage=xx.xx%
- [ ] No regressions in previously-passing tests

## Files Changed
- (list files)

## Type of Change
- [ ] Bug fix (non-breaking)
- [ ] New feature (non-breaking)
- [ ] Breaking change
- [ ] Documentation update
```

### 5. Review Process

Reviewers will check:
- ✓ Code follows style guidelines
- ✓ Reported test results are from an actual run, with tool/version stated
- ✓ Documentation is updated (including `CHANGELOG.md` for bug fixes)
- ✓ No unverified claims about tool compatibility

### 6. Address Feedback & Merge

Once approved, the maintainer will merge the PR after confirming branch is up to date with `main`.

---

## Verification Standards

| Criteria | Requirement |
|----------|-------------|
| **Compilation** | No errors or warnings, in the tool(s) you tested |
| **Functionality** | Affected testbenches/tests pass |
| **Reported Numbers** | Must come from an actual run — state the tool and version used |
| **Documentation** | Design/verification docs updated to match what was actually run |
| **Regression** | No previously-passing tests break |

---

## Documentation Contribution

- Use clear, technical language
- State which tool produced any numbers you cite
- Don't claim compatibility with a simulator you haven't tested
- Proofread before submitting

---

## Issues & Discussions

Use descriptive titles: `[BUG]`, `[QUESTION]`, `[IDEA]`, `[DOCUMENTATION]`

Include: tool + version, exact reproduction steps, expected vs actual behavior, relevant logs/waveforms.

---

## Additional Resources

- [AMBA AXI Specification](https://developer.arm.com/documentation/ihi0022/latest/)
- [SystemVerilog Reference](https://standards.ieee.org/ieee/1800/6700/)
- [Accellera UVM](https://www.accellera.org/downloads/standards/uvm)
- [EDA Playground](https://www.edaplayground.com/)
- [Conventional Commits](https://www.conventionalcommits.org/)

---

**Thank you for contributing!**

Last Updated: [Date]
