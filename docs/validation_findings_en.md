# Validation Findings

## 1. Purpose and scope

This note records four verification items added after the first complete frequency-domain and time-domain study: interpretation of time-domain differences, formal fit-quality gates, independent 10 Hz repeatability, and signal-by-signal equivalence with the source BESS model. The numerical limits below are fixed acceptance criteria rather than values adjusted per operating point.

## 2. Time-domain interpretation

The representative cases preserve the originally planned risk labels and report the calculated labels separately.

| Case | Planned label | Calculated label | Overshoot | 5% settling within 2.25 s | Decay ratio |
|---|---|---|---:|---|---:|
| A | Lower | Lower | 36.15% | No | 0.4090 |
| B | Moderate | Higher | 173.3% | No | 0.9733 |
| C | Higher | Higher | 144.7% | No | 0.9778 |

Case B is intentionally retained even though its calculated frequency-domain label is Higher rather than Moderate. This is a study result, not a software failure. It shows that the initially selected point lies beyond the Moderate band under the implemented interaction metric and model settings.

The overshoot ordering agrees with the frequency-domain risk ordering for all three comparable pairs. The decay-ratio ordering agrees for two of three pairs. None of the cases enters and remains inside the 5% band during the 2.25 s observation window, so settling-time ordering is not claimed. A reported settling value of 2.25 s therefore means "not settled by the end of the observation window," not successful settling at exactly 2.25 s.

## 3. Fit-quality acceptance gates

Every completed frequency point must satisfy all of the following gates:

| Quantity | Fixed limit | Reason for use |
|---|---:|---|
| Main injected-voltage relative residual | <= 2% | Confirms the commanded excitation axis is represented by the fitted sinusoid. |
| Current-matrix weighted residual | <= 35% | Reduces the influence of response channels whose phasor magnitude is close to zero while retaining all four current channels. |
| Cross-voltage leakage ratio | <= 5% | Checks excitation-axis purity without dividing by a near-zero cross-voltage phasor. |
| Voltage-matrix condition number | < 10,000 | Prevents inversion of an ill-conditioned excitation matrix. |
| Raw current residual at the 10 Hz reference point | <= 35% for every channel | Provides an additional direct, unweighted reference-point check. |

The 5% cross-voltage leakage limit is applied across the full 0.5–100 Hz band. The measured leakage increases toward the upper end of the band and reaches 3.29%; a 2% limit would reject valid high-frequency points even though the main injected-voltage residual remains below 0.63%.

Measured quality results are:

| Study | Main-voltage residual | Weighted current residual | Raw current residual | Cross-voltage leakage | Result |
|---|---:|---:|---:|---:|---|
| Fresh 10 Hz reference | 0.58% maximum | 8.84% maximum | 29.66% maximum | 0.89% maximum | Pass |
| Complete 0.5–100 Hz scan | 0.63% maximum | 14.23% maximum | 99.99% maximum | 3.29% maximum | Pass |

The full-band raw current maximum is retained for transparency. It occurs when a current-response phasor is close to zero, so the relative residual denominator becomes very small. It is not used alone as the full-band acceptance gate; the weighted current metric is used for that purpose. At 10 Hz, where all raw current channels are explicitly checked, the maximum is 29.66% and passes the 35% reference limit.

## 4. Independent repeatability check

The 10 Hz d-axis and q-axis identification is executed twice in separate simulation runs and saved in separate result files. All four complex dq-admittance elements are compared.

| Quantity | Fixed limit | Measured maximum | Result |
|---|---:|---:|---|
| Magnitude relative difference | <= 2% | 0% | Pass |
| Phase difference | <= 2 degrees | 0 degrees | Pass |

This check quantifies run-to-run repeatability rather than relying only on the ability to rerun the script.

## 5. Baseline-model equivalence

The frequency-scan model and the source model from the grid-connected BESS project are run with the perturbation explicitly disabled, the same 10 Hz test setting, and the same finite simulation timing. The model files are also compared byte for byte.

Nine signals are compared: `vd_V`, `vq_V`, `id_A`, `iq_A`, `p_W`, `q_var`, `pll_frequency_Hz`, `soc_pu`, and `fault_state`.

| Quantity | Fixed limit | Measured maximum | Result |
|---|---:|---:|---|
| Relative RMS error | <= 1e-8 | 0 | Pass |
| Normalized maximum error | <= 1e-8 | 0 | Pass |
| Model-file byte identity | Required | Identical | Pass |

The result confirms that adding the frequency-scan interface does not change the baseline behavior when perturbation is disabled.

## 6. Reproduction

Run `tests/run_all_checks.m` from the project folder in MATLAB. The entry point executes seven check groups covering the single-frequency interface, repeatability, baseline equivalence, the 20-point nominal scan, SCR interaction screening, the PLL risk map, and representative time-domain validation. Saved scan data may be reclassified only from its recorded raw quality metrics when a fixed quality limit changes; the measured phasors are not overwritten.

## 7. Conclusion

All four added verification items pass their stated acceptance criteria. The time-domain mismatch remains visible and is treated as an engineering finding. Frequency-domain risk screening and short-window time-domain metrics are related indicators, but they are not presented as interchangeable stability proofs.
