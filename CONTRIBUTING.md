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

### Tools Required

- SystemVerilog simulator (ModelSim, VCS, Xcelium, or Vivado)
- Git version control
- Text editor or IDE (VS Code, Vim, etc.)
- Waveform viewer (for debugging)

---

## Contribution Types

### 1. Bug Reports

Found an issue? Please report it by:

1. Check if issue already exists
2. Create a clear title: `[BUG] Brief description`
3. Include:
   - Which testbench fails
   - Expected vs actual behavior
   - Steps to reproduce
   - Simulator version used
   - Relevant waveforms/logs

**Example:**
```
Title: [BUG] Round Robin pointer not advancing after grant

Simulator: ModelSim 10.7
Behavior: In tb_round_robin_arbiter, when master 0 is granted,
          pointer should advance to 1. Instead it stays at 0.

Steps:
1. Run vsim tb_round_robin_arbiter
2. Set req = 4'b1111
3. Observe grant transitions
4. Pointer remains at master 0

Expected: Pointer = 1 after grant to master 0
Actual: Pointer remains at 0
```

### 2. Feature Requests

Suggest improvements via issues:

- `[FEATURE] Parameterized master count`
- `[FEATURE] Dynamic aging threshold via CSR`
- `[ENHANCEMENT] Add formal verification`

Include:
- Motivation/use case
- Proposed implementation (if applicable)
- Potential impact on performance/area

### 3. Code Contributions

Contributing code changes? Follow these guidelines:

#### Before You Start
- Review `DESIGN_SPECS.md` for architecture
- Review `VERIFICATION_PLAN.md` for testing approach
- Run full test suite: all testbenches must pass
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
localparam MAX_AGE = 8;

// Typedefs: CamelCase
typedef enum {IDLE, ARBIT, GRANT} state_t;
```

**Formatting:**
```systemverilog
// Use 2-space indentation
module example (
  input  logic  clk,
  input  logic  reset
);
  always @(posedge clk) begin
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
// Use clear, concise comments
// Explain WHY, not WHAT

// Bad:
counter = counter + 1;  // increment counter

// Good:
// Increment age counter when request pending
// Saturates at MAX_AGE to prevent overflow
counter = (counter >= MAX_AGE) ? MAX_AGE : counter + 1;
```

**Port & Signal Organization:**
```systemverilog
module arbiter (
  // Clock & Reset (always first)
  input  logic        clk,
  input  logic        reset,
  
  // Control Signals
  input  logic        enable,
  input  logic        mode,
  
  // Data Signals (grouped by direction)
  input  logic [3:0]  req,
  output logic [3:0]  grant,
  
  // Optional: AXI interface
  input  axi_lite_if  axi_if
);
  // Body
endmodule
```

#### Testing Requirements

All code changes must include:

1. **Updated Testbench** (if modifying design module)
   ```systemverilog
   // New test case
   tb_new_feature: begin
     // Setup
     req = 4'b0001;
     @(posedge clk);
     
     // Verify
     assert(grant == 4'b0001) else 
       $error("Feature not working correctly");
   end
   ```

2. **Test Case Pass/Fail Log**
   ```
   Test: new_feature_tc_01 ............ PASS ✓
   Test: new_feature_tc_02 ............ PASS ✓
   Coverage: 98% statements, 95% branches
   ```

3. **Regression Testing**
   - Ensure all existing tests still pass
   - Run: `make test` (or all testbenches)

#### Documentation

Update relevant documentation:

- **Code changes:** Update `DESIGN_SPECS.md`
- **New features:** Add section in `README.md`
- **Test changes:** Update `VERIFICATION_PLAN.md`
- **Implementation notes:** Add inline comments

---

## Pull Request Process

### 1. Prepare Your Branch

```bash
# Update main branch
git checkout main
git pull origin main

# Create feature branch
git checkout -b feature/meaningful-name

# Make your changes
# ...

# Test locally
vsim work.tb_axi_arbiter_top -do "run -all; quit"
```

### 2. Commit Changes

```bash
# Follow conventional commit format
git add .
git commit -m "feat: add parameterized master count

- Modified axi_arbiter_top to accept NUM_MASTERS parameter
- Updated all submodules to support variable count
- Added testbench with 8-master scenario
- Verified backward compatibility with 4-master default

Closes #123"
```

**Commit Format:**
```
type(scope): short description (50 chars max)

Detailed explanation (wrap at 72 chars)
- Bullet point 1
- Bullet point 2

Fixes #issue_number
```

**Types:** `feat`, `fix`, `refactor`, `test`, `docs`, `style`

### 3. Push to Your Fork

```bash
git push origin feature/meaningful-name
```

### 4. Create Pull Request on GitHub

**PR Title:** `[TYPE] Brief description`

**PR Description Template:**
```markdown
## Description
Brief summary of changes

## Motivation & Context
Why is this change needed? What problem does it solve?

## Testing Done
- [ ] Round Robin tests pass
- [ ] Fixed Priority tests pass
- [ ] AXI Lite tests pass
- [ ] New feature test: [test_name]
- [ ] No regressions detected

## Verification Results
```
Test Suite Results:
- All testbenches: PASS
- Code coverage: 96% statements, 91% branches
- Simulation time: <2 minutes
```

## Files Changed
- axi_arbiter_top.sv
- fixed_priority_aging_arbiter.sv
- tb_axi_arbiter_top.sv
- DESIGN_SPECS.md

## Type of Change
- [ ] Bug fix (non-breaking)
- [ ] New feature (non-breaking)
- [ ] Breaking change
- [ ] Documentation update
```

### 5. Review Process

Reviewers will check:
- ✓ Code follows style guidelines
- ✓ All tests pass with no regressions
- ✓ Documentation is updated
- ✓ Design is sound and efficient
- ✓ Verification coverage adequate

**Response time:** Reviews typically within 7 days

### 6. Address Feedback

- Make requested changes
- Push updates to same branch
- Respond to comments
- Re-request review once complete

### 7. Merge

Once approved:
```bash
# Ensure branch is up-to-date
git fetch origin
git rebase origin/main

# Fix any conflicts
# ...

# Project maintainer will merge PR
```

---

## Verification Standards

All contributions must meet:

| Criteria | Requirement |
|----------|-------------|
| **Compilation** | No errors or warnings |
| **Functionality** | All testbenches pass |
| **Code Coverage** | >95% statements, >90% branches |
| **Documentation** | Design and test docs updated |
| **Regression** | No existing tests fail |
| **Performance** | Simulation time reasonable |

---

## Documentation Contribution

Improving docs? Follow these guidelines:

- Use clear, technical language
- Include examples where applicable
- Update table of contents
- Check for broken links
- Proofread before submitting

**Markdown style:**
```markdown
# Heading 1

Paragraph with explanation.

## Heading 2

### Heading 3

Use backticks for `code` inline.

Use triple backticks for code blocks:
\```systemverilog
module example;
endmodule
\```

Use `| table | format |` for structured data.
```

---

## Issues & Discussions

### Getting Help

- Check `README.md` and `QUICK_START.md` first
- Search existing issues/discussions
- Ask in Discussions tab (if available)

### Reporting Issues

Use descriptive titles:
- `[BUG]` for bugs
- `[QUESTION]` for questions
- `[IDEA]` for suggestions
- `[DOCUMENTATION]` for doc issues

Include:
- Simulator version
- Exact reproduction steps
- Expected vs actual behavior
- Relevant logs/waveforms

---

## Recognition

Contributors will be recognized in:
- Pull request acknowledgment
- Project CONTRIBUTORS file (coming soon)
- Release notes

---

## Questions?

- Check existing issues/PRs
- Review documentation
- Start a discussion

---

## Additional Resources

- [AMBA AXI Specification](https://developer.arm.com/documentation/ihi0022/latest/)
- [SystemVerilog Reference](https://standards.ieee.org/ieee/1800/6700/)
- [Git Workflow Guide](https://www.atlassian.com/git/tutorials/comparing-workflows)
- [Conventional Commits](https://www.conventionalcommits.org/)

---

**Thank you for contributing! Your efforts help improve hardware design and verification practices.**

Last Updated: 2024
