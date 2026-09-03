% RUN_ALL_CHECKS Execute the complete local validation sequence.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
if strcmpi(getenv('BESS_VALIDATION_SCOPE'), 'smoke')
    runSmokeChecks(projectRoot);
    return
end
checks = { ...
    'run_phase1_interface_check.m', ...
    'run_phase1_repeatability_check.m', ...
    'run_phase1_baseline_equivalence_check.m', ...
    'run_phase2_frequency_scan_check.m', ...
    'run_phase3_scr_interaction_check.m', ...
    'run_phase4_pll_risk_map_check.m', ...
    'run_phase5_time_domain_check.m'};

for k = 1:numel(checks)
    run(fullfile(projectRoot, 'tests', checks{k}));
end
fprintf('ALL LOCAL CHECKS PASS | %d check groups\n', numel(checks));

function runSmokeChecks(projectRoot)
addpath(fullfile(projectRoot, 'models'));
addpath(fullfile(projectRoot, 'scripts'));
resultsFolder = fullfile(projectRoot, 'results');
if ~isfolder(resultsFolder)
    mkdir(resultsFolder);
end

run(fullfile(projectRoot, 'tests', 'run_phase1_interface_check.m'));
run(fullfile(projectRoot, 'tests', 'run_phase1_repeatability_check.m'));
run(fullfile(projectRoot, 'tests', ...
    'run_phase1_baseline_equivalence_check.m'));

quickScanFile = fullfile(resultsFolder, 'ci_weak_grid_scan.mat');
if isfile(quickScanFile)
    delete(quickScanFile);
end
quickConfiguration = struct('scr',2,'pll_scale',2, ...
    'create_admittance_plot',false);
quickScan = run_frequency_scan(10, quickScanFile, quickConfiguration);
assert(all(quickScan.completed), 'The CI weak-grid scan is incomplete.');
assert(all(isfinite(real(quickScan.Y_dq_S)),'all') && ...
    all(isfinite(imag(quickScan.Y_dq_S)),'all'), ...
    'The CI weak-grid admittance contains a non-finite value.');
assert(all(quickScan.voltage_matrix_condition < ...
    quickScan.configuration.maximum_voltage_matrix_condition), ...
    'The CI weak-grid excitation matrix is ill-conditioned.');
assert(all(quickScan.maximum_fault_state < 0.5) && ...
    all(quickScan.minimum_soc_pu > 0.10) && ...
    all(quickScan.maximum_soc_pu < 0.90), ...
    'The CI weak-grid scan left the validated operating envelope.');
assert(quickScan.configuration.scr == 2 && ...
    quickScan.configuration.pll_scale == 2, ...
    'The CI weak-grid configuration was not applied.');
quickMetric = compute_interaction_metric(quickScan);
assert(isfinite(quickMetric.peak_interaction_gain) && ...
    quickMetric.critical_frequency_Hz == 10, ...
    'The CI interaction metric is invalid.');

initializationFile = fullfile(projectRoot, 'scripts', ...
    'init_frequency_scan.m');
variablesBeforeInitialization = who;
run(initializationFile);
initializedVariableNames = setdiff(who, variablesBeforeInitialization);
modelVariables = struct();
for variableIndex = 1:numel(initializedVariableNames)
    variableName = initializedVariableNames{variableIndex};
    modelVariables.(variableName) = eval(variableName);
end

validationCfg = struct();
validationCfg.nominal_frequency_Hz = scan_cfg.nominal_frequency_Hz;
validationCfg.initial_active_power_W = scan_cfg.nominal_active_power_W;
validationCfg.final_active_power_W = scan_cfg.nominal_active_power_W + ...
    0.05*scan_cfg.converter_base_power_VA;
validationCfg.reactive_power_var = scan_cfg.nominal_reactive_power_var;
validationCfg.step_time_s = 0.75;
validationCfg.stop_time_s = 3.0;
validationCfg.sample_rate_Hz = 1000;
validationCfg.pre_window_s = 0.20;
validationCfg.pre_guard_s = 0.05;
validationCfg.final_window_s = 0.30;
validationCfg.settling_tolerance = 0.05;
validationCfg.residual_smoothing_s = 0.05;
validationCfg.early_window_s = [0.02 0.40];
validationCfg.late_window_s = [0.05 0.40];
validationCfg.spectral_delay_s = 0.02;
validationCfg.spectral_duration_s = 1.25;
validationCfg.oscillation_frequency_band_Hz = [0.5 100];

timeDomainCase = struct('scr',2,'pll_scale',2);
in = make_time_domain_validation_input(timeDomainCase, validationCfg, ...
    scan_cfg, frequency_scan_model, modelVariables);
out = sim(in);
timeDomainSignals = extract_pcc_dq_signals(out);
clear out
timeDomainSignals = resample_time_domain_signals(timeDomainSignals, ...
    validationCfg.sample_rate_Hz);
timeDomainMetrics = estimate_time_domain_metrics(timeDomainSignals, ...
    validationCfg);
assert(all(isfinite(timeDomainSignals.p_W)) && ...
    all(isfinite(timeDomainSignals.pll_frequency_Hz)), ...
    'The CI time-domain run contains a non-finite signal.');
assert(max(timeDomainSignals.fault_state) < 0.5 && ...
    min(timeDomainSignals.soc_pu) > 0.10 && ...
    max(timeDomainSignals.soc_pu) < 0.90, ...
    'The CI time-domain run left the validated operating envelope.');
assert(isfinite(timeDomainMetrics.overshoot_percent) && ...
    isfinite(timeDomainMetrics.oscillation_decay_ratio), ...
    'The CI time-domain metrics are invalid.');

save(fullfile(resultsFolder, 'ci_smoke_summary.mat'), ...
    'quickScan', 'quickMetric', 'timeDomainMetrics');
fprintf(['CI SMOKE CHECKS PASS | interface, repeatability, baseline, ' ...
    'weak-grid scan, interaction metric and time-domain response\n']);
end
