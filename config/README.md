# Configuration

**English** | [简体中文](README.zh-CN.md)

The executable parameter source is [`scripts/init_frequency_scan.m`](../scripts/init_frequency_scan.m). It initializes the plant inherited from the validated grid-connected BESS model and defines the complete `scan_cfg` structure used by the scan, quality gates and interaction studies.

| Group | Parameters |
| --- | --- |
| Operating point | 50 Hz, 11 kV, active/reactive-power targets |
| Frequency scan | 0.5–100 Hz, 20 logarithmic points and injection timing |
| Perturbation | 0.3% d-axis voltage magnitude and equivalent q-axis phase perturbation |
| Grid and control | SCR, X/R ratio and PLL gain scale |
| Identification quality | Voltage residual, weighted current residual, leakage and condition-number limits |
| Validation | Repeatability and baseline-equivalence tolerances |

Keeping one executable parameter source prevents a separate configuration copy from diverging from the scripts that run the model. Case-specific SCR and PLL overrides are applied non-destructively by the batch-run functions.
