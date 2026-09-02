# Model Description

**English** | [简体中文](model_description.zh-CN.md)

## 1. Purpose

`models/bess_frequency_scan.slx` is an isolated grid-following battery energy storage system model prepared for small-signal frequency-response identification, weak-grid interaction screening and time-domain cross-checking. It preserves the validated power stage and control behavior of the source BESS project while adding a repeatable perturbation interface.

## 2. Power stage

| Subsystem | Implementation |
|---|---|
| Grid | 11 kV, 50 Hz three-phase source with configurable short-circuit strength and X/R ratio |
| AC interface | Voltage-source converter and LCL filter connected at the point of common coupling |
| DC link | Dynamic DC-link capacitor and voltage measurement |
| Storage side | RC battery representation and bidirectional DC/DC conversion |
| Measurements | PCC voltage/current, active/reactive power, DC-link voltage, battery current and state of charge |

## 3. Control structure

The grid-following controller uses a PLL for angle tracking, abc/dq transformations, outer active/reactive-power and DC-link loops, inner dq current control, current limiting and anti-windup. A state-of-charge supervisor constrains the active-power request. The controller structure is summarized in [`control_architecture.svg`](control_architecture.svg).

## 4. Frequency-scan interface

The d-axis test applies a small line-voltage magnitude modulation. The q-axis test applies an equivalent phase modulation. For every frequency the workflow runs a perturbation-disabled baseline, followed by separate d-axis and q-axis injections. Complex voltage and current tones are extracted over an integer-cycle analysis window to identify all four entries of the dq admittance matrix.

## 5. Executable entry points

| Task | Entry point |
|---|---|
| Initialize parameters | `scripts/init_frequency_scan.m` |
| Demonstrate one frequency | `scripts/run_single_frequency_demo.m` |
| Run the complete frequency scan | `scripts/run_frequency_scan.m` |
| Screen four SCR values | `scripts/run_scr_interaction_scan.m` |
| Build the PLL-SCR risk map | `scripts/run_pll_risk_map.m` |
| Run time-domain cases | `scripts/run_time_domain_validation.m` |
| Execute all checks | `tests/run_all_checks.m` |

## 6. Data and reproducibility

Run-time MAT files and automatically generated plots are written to `results/`. Curated evidence used by the repository is copied to `docs/images/`. Frequency scans save each completed point and can resume only when the saved configuration signature matches the requested case.

## 7. Interpretation boundary

The model identifies simulated terminal behavior around selected operating points. The reported score is a comparative screening indicator based on the maximum singular value of `ZgridYbess`; it is not a formal generalized-Nyquist proof, hardware result, protection study or grid-code approval.
