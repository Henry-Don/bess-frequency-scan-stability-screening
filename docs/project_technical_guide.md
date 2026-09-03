# Automated Frequency-Scan and Weak-Grid Stability Screening of a Grid-Following BESS

**English** | [简体中文](project_technical_guide.zh-CN.md)

**Technical Note - Version 1.0**  
**Author:** Henry Tang  
**Date:** 2 September 2026

## Executive summary

This project implements a repeatable black-box dq frequency-scan workflow around an existing grid-following battery energy storage system (BESS) model. Its purpose is to compare converter-grid interaction risk across grid strength and phase-locked-loop (PLL) settings without rebuilding the converter as an analytical impedance model. The workflow applies separate d-axis and q-axis sinusoidal voltage perturbations, extracts complex voltage and current tones, constructs a complete 2 x 2 dq admittance matrix, combines the result with a dq grid impedance, and summarizes the interaction through one fixed singular-value metric.

The nominal scan covers 0.5-100 Hz using 20 logarithmically spaced points. Four short-circuit-ratio (SCR) values and four PLL gain scales produce a 4 x 4 operating matrix, representing 640 d/q injection runs. The study classifies each case as Lower, Moderate, or Higher relative risk and records the frequency at which the interaction score peaks.

The main finding is that the selected metric separates grid strength clearly. All SCR 10 cases remain Lower, all SCR 5 cases are Moderate, and all SCR 3 and SCR 2 cases are Higher. The most important interaction frequencies are between 57.25 Hz and 100 Hz. PLL scaling changes the score substantially in the weak-grid cases, but the direction is not monotonic for every SCR; therefore the project reports the full matrix rather than claiming that a faster or slower PLL is always safer.

Three time-domain cases were used for cross-checking. Case B was initially selected as a Moderate representative point but calculates as Higher under the completed metric. This difference is retained. Overshoot ordering agrees with frequency-domain risk ordering for all three comparable pairs, decay-ratio ordering agrees for two of three pairs, and none of the three cases settles inside the 5% band during the 2.25 s observation window.

## 1. Scope and system boundary

The study reuses the validated grid-following BESS model from the preceding converter-control project. The model contains an 11 kV, 50 Hz grid connection, LCL filter, average VSC, physical DC-link capacitor, bidirectional average DC/DC stage, RC battery model, SoC supervision, PLL, abc/dq transformations, dq current control, active/reactive-power control, DC-link regulation, current limiting and supporting protection logic.

The new work is deliberately concentrated at the point of common coupling (PCC). A small perturbation is superimposed on the PCC voltage command while the original plant and controller remain unchanged. When the perturbation is disabled, the frequency-scan model must reproduce the source model. This boundary makes the BESS a black-box terminal device: the identification uses measured dq voltage and current behavior rather than internal controller equations.

The baseline operating point is 11 kV, 50 Hz, active power approximately 0.5 pu, and reactive-power reference equal to zero. The voltage perturbation is 0.3% pu. This amplitude is large enough for reliable tone extraction while remaining small enough to avoid intentionally activating current limiting, SoC limits, fault response or other large-signal logic.

The study is a screening and pre-assessment exercise. It does not represent a complete analytical impedance derivation, a generalized Nyquist stability proof, an interconnection-compliance result, or validation against vendor data, hardware, HIL or field measurements.

## 2. Frequency-scan method

For each requested frequency, the same sequence is executed:

1. Run a perturbation-disabled baseline and record the reference PLL angle and PCC signals.
2. Apply a d-axis sinusoidal perturbation and record Vd, Vq, Id and Iq.
3. Apply a q-axis sinusoidal perturbation and record the same signals.
4. Select the steady measurement window after discarding the configured initial cycles.
5. Fit sine and cosine components at the commanded frequency by least squares.
6. Form complex voltage and current phasor matrices and solve for dq admittance.
7. Store raw phasors, condition number, fit metrics, operating-point evidence and completion status.

The small-signal relationship is

```text
[Delta Id]   [Ydd  Ydq] [Delta Vd]
[Delta Iq] = [Yqd  Yqq] [Delta Vq]
```

If the two voltage-excitation columns form `V(jw)` and the corresponding current-response columns form `I(jw)`, the identified admittance is

```text
Ydq(jw) = I(jw) V(jw)^(-1)
```

Both injection axes are required. A d-axis run identifies the first response column and a q-axis run identifies the second; neither run is a duplicate. The off-diagonal terms are retained because PLL dynamics, rotating-frame coupling, power loops and the plant can create cross-axis response.

The nominal frequency vector uses 20 logarithmically spaced points from 0.5 Hz to 100 Hz. Simulation duration is frequency dependent so that low-frequency points contain sufficient cycles without imposing the same long duration on every high-frequency point. Completed points are saved incrementally, allowing an interrupted scan to resume when its configuration signature matches the saved case.

## 3. Identification quality and repeatability

Four formal checks protect the admittance calculation:

| Quantity | Fixed acceptance limit |
|---|---:|
| Main injected-voltage relative residual | <= 2% |
| Current-matrix weighted residual | <= 35% |
| Cross-voltage leakage ratio | <= 5% |
| Voltage-matrix condition number | < 10,000 |

The main injected-voltage residual verifies that the commanded excitation axis is represented by the fitted tone. A raw relative residual is not a useful acceptance metric for a cross-voltage channel whose true tone is nearly zero, because the normalization denominator makes a small absolute error appear very large. Cross-axis purity is therefore checked through leakage relative to the main injected voltage.

The four current residuals are retained. For the complete band, they are scaled by their tone magnitude relative to the largest current tone at that point. This weighted matrix metric prevents a near-zero response channel from dominating the gate while still retaining all four channels. The fresh 10 Hz reference run adds a stricter direct check: every raw current residual must remain below 35%.

At 10 Hz, the maximum main-voltage residual is 0.58%, the maximum weighted current residual is 8.84%, the maximum raw current residual is 29.66%, and cross-voltage leakage is 0.89%. Across the complete 0.5-100 Hz scan, the corresponding maxima are 0.63%, 14.23%, 99.99%, and 3.29%. The 99.99% raw value occurs in a near-zero current response and is retained for transparency; it is not used alone as the full-band gate.

Repeatability is quantified by running the complete 10 Hz d/q identification twice in separate simulations. Every complex admittance element is compared in magnitude and phase. The acceptance limits are 2% magnitude difference and 2 degrees phase difference. The measured maxima are 0% and 0 degrees.

Baseline equivalence is checked independently. With perturbation explicitly disabled, the scan model and source model are run using the same timing. Nine signals - Vd, Vq, Id, Iq, P, Q, PLL frequency, SoC and fault state - are compared. Both maximum relative RMS error and normalized maximum error are zero, and the two model files are byte-identical at the validated revision.

## 4. Grid interaction metric

Grid strength is represented by a Thevenin impedance corresponding to SCR values 10, 5, 3 and 2 while the converter rating and grid X/R ratio remain fixed. In the synchronous frame, the frequency-dependent grid impedance is combined with the identified BESS admittance to form the interaction matrix

```text
L(jw) = Zgrid(jw) Ybess(jw)
```

The scalar screening score at each frequency is the largest singular value

```text
gamma(w) = max singular value of L(jw)
```

The peak score over the scan and its frequency are stored for each operating case. This definition gives one comparable quantity for every SCR-PLL combination and captures matrix coupling without reducing the model to one scalar transfer path.

The fixed labels are Lower for a peak score below 0.5, Moderate from 0.5 to below 1.0, and Higher at or above 1.0. The label names intentionally describe relative screening risk rather than proven stable or unstable states. The thresholds are identical for all cases; no case-specific tuning is allowed.

At nominal PLL scale, SCR 10 has a peak score of 0.343 at 100 Hz, SCR 5 has 0.795 at 100 Hz, SCR 3 has 3.490 at 75.66 Hz, and SCR 2 has 3.284 at 57.25 Hz. The transition from SCR 5 to SCR 3 moves the result across the Higher threshold and shifts the critical region downward from 100 Hz.

## 5. SCR-PLL risk map

PLL proportional and integral gains are scaled together by 0.5, 1.0, 1.5 and 2.0. This is a sensitivity study, not an optimization. Each of the 16 cases uses the same frequency vector, identification method, grid model, fit-quality criteria and risk thresholds.

| SCR / PLL scale | 0.5 | 1.0 | 1.5 | 2.0 |
|---:|---:|---:|---:|---:|
| 10 | 0.338 Lower | 0.343 Lower | 0.318 Lower | 0.346 Lower |
| 5 | 0.653 Moderate | 0.795 Moderate | 0.862 Moderate | 0.844 Moderate |
| 3 | 1.643 Higher | 3.490 Higher | 4.055 Higher | 5.270 Higher |
| 2 | 3.418 Higher | 3.284 Higher | 2.991 Higher | 2.442 Higher |

| SCR / PLL scale | 0.5 | 1.0 | 1.5 | 2.0 |
|---:|---:|---:|---:|---:|
| 10 | 100 Hz | 100 Hz | 100 Hz | 100 Hz |
| 5 | 100 Hz | 100 Hz | 75.66 Hz | 100 Hz |
| 3 | 75.66 Hz | 75.66 Hz | 75.66 Hz | 75.66 Hz |
| 2 | 75.66 Hz | 57.25 Hz | 57.25 Hz | 57.25 Hz |

The strongest trend is the rise in score as the grid weakens from SCR 10 to SCR 3. PLL sensitivity becomes much larger in the weak-grid region. At SCR 3, increasing the PLL scale raises the peak score from 1.643 to 5.270. At SCR 2, however, the score decreases across the same PLL sequence. This non-monotonic behavior is an important reason to preserve the full matrix and avoid a universal statement such as "higher PLL bandwidth always increases risk."

## 6. Time-domain cross-check

Three operating points receive the same type of active-power reference step. The response is normalized so that overshoot, 5% settling, dominant oscillation frequency and late-to-early oscillation RMS ratio can be compared.

| Case | SCR | PLL scale | Planned | Calculated | Overshoot | Dominant frequency | Decay ratio |
|---|---:|---:|---|---|---:|---:|---:|
| A | 10 | 1.0 | Lower | Lower | 36.15% | 2.437 Hz | 0.4090 |
| B | 3 | 1.0 | Moderate | Higher | 173.3% | 97.48 Hz | 0.9733 |
| C | 2 | 2.0 | Higher | Higher | 144.7% | 80.42 Hz | 0.9778 |

All three cases remain outside the 5% band at the end of the 2.25 s observation window. The stored 2.25 s settling value therefore means "not settled by the end of the window" rather than successful settling at exactly 2.25 s.

The frequency-domain and time-domain views are related but not identical. The overshoot ordering agrees with risk ordering for all three comparable pairs. The decay-ratio ordering agrees for two of three pairs. Settling-time ordering cannot be assessed because all three cases are censored at the observation-window limit. Case B's changed label is reported rather than corrected: the selected point falls in the Higher band under the completed metric.

The dominant time-domain frequencies for Cases B and C are in the same high-frequency region highlighted by the screening study, but exact equality is not expected. The time-domain response includes reference-path dynamics, nonlinearities, finite-window estimation and potentially multiple modes, while the frequency scan is a local terminal identification around a defined operating point.

## 7. Reproduction, evidence and limitations

The main local validation command is

```matlab
cd('path/to/bess-frequency-scan-stability-screening')
run('tests/run_all_checks.m')
```

Seven check groups cover the 10 Hz interface, fit quality, independent repeatability, baseline equivalence, the nominal 20-point scan, four-SCR interaction screening, the 16-case PLL risk map and the three time-domain cases. MATLAB static analysis reports zero findings across 43 MATLAB files in the validated revision.

The repository keeps the model, scripts, tests, technical notes and representative figures. Large simulation data, generated caches and compiled model artifacts remain local. Each saved scan records its frequency vector, SCR, PLL scale, quality metrics, completion state and configuration signature. This supports interrupted-run recovery and protects against silently reusing results from a different configuration.

Important limitations are:

- Results are obtained from a simulated average-converter model rather than switching EMT or hardware measurements.
- The identified admittance is local to the selected operating point and perturbation amplitude.
- The interaction score is a comparative small-gain-style screening metric, not a formal generalized Nyquist proof.
- Only SCR and PLL gain scale are swept; X/R ratio, active/reactive operating point, control delays and plant uncertainty are not full study dimensions.
- The 20-point frequency grid can locate broad risk regions but cannot guarantee the exact continuous-frequency maximum.
- The time-domain observation window is finite and all three representative cases are unsettled at its end.

Within those boundaries, the project meets its intended purpose: it automatically converts repeatable terminal perturbations into a complete dq response, compares weak-grid and PLL sensitivity through one fixed metric, identifies critical frequency regions, and retains mismatches for engineering interpretation rather than forcing the data to match an expected narrative.
