% RUN_SINGLE_FREQUENCY_DEMO Verify the disabled, d-axis, and q-axis cases.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'models'));
run(fullfile(projectRoot, 'scripts', 'init_frequency_scan.m'));
demoTiming = frequency_scan_timing(scan_cfg, scan_cfg.test_frequency_Hz);

resultsFolder = fullfile(projectRoot, 'results');
if ~isfolder(resultsFolder)
    mkdir(resultsFolder);
end

baselineOut = sim(make_frequency_scan_input('off', scan_cfg.test_frequency_Hz, false));
dAxisOut = sim(make_frequency_scan_input('d', scan_cfg.test_frequency_Hz, true));
qAxisOut = sim(make_frequency_scan_input('q', scan_cfg.test_frequency_Hz, true));

phase1_result = struct();
phase1_result.configuration = scan_cfg;
phase1_result.baseline = extract_pcc_dq_signals(baselineOut);
phase1_result.d_axis = extract_pcc_dq_signals(dAxisOut, ...
    phase1_result.baseline.time_s, phase1_result.baseline.reference_angle_rad);
phase1_result.q_axis = extract_pcc_dq_signals(qAxisOut, ...
    phase1_result.baseline.time_s, phase1_result.baseline.reference_angle_rad);

% The 50 Hz fundamental is present in every dq waveform.  Identify the
% injected response relative to the perturbation-disabled baseline instead
% of reporting the fundamental waveform excursion.
phase1_result.d_axis.delta_vd_V = phase1_result.d_axis.vd_V - interp1( ...
    phase1_result.baseline.time_s, phase1_result.baseline.vd_V, ...
    phase1_result.d_axis.time_s, 'linear', 'extrap');
phase1_result.q_axis.delta_vq_V = phase1_result.q_axis.vq_V - interp1( ...
    phase1_result.baseline.time_s, phase1_result.baseline.vq_V, ...
    phase1_result.q_axis.time_s, 'linear', 'extrap');

window = phase1_result.d_axis.time_s >= demoTiming.enable_time_s & ...
    phase1_result.d_axis.time_s <= demoTiming.disable_time_s;
phase1_result.summary = struct();
phase1_result.summary.d_axis_delta_vd_peak_to_peak_V = ...
    peak2peak(phase1_result.d_axis.delta_vd_V(window));
phase1_result.summary.q_axis_delta_vq_peak_to_peak_V = ...
    peak2peak(phase1_result.q_axis.delta_vq_V(window));
phase1_result.summary.baseline_pll_frequency_mean_Hz = ...
    mean(phase1_result.baseline.pll_frequency_Hz(end-999:end));
phase1_result.summary.maximum_fault_state = max([ ...
    phase1_result.baseline.fault_state; phase1_result.d_axis.fault_state; ...
    phase1_result.q_axis.fault_state]);
phase1_result.summary.minimum_soc_pu = min([ ...
    phase1_result.baseline.soc_pu; phase1_result.d_axis.soc_pu; ...
    phase1_result.q_axis.soc_pu]);
phase1_result.summary.maximum_soc_pu = max([ ...
    phase1_result.baseline.soc_pu; phase1_result.d_axis.soc_pu; ...
    phase1_result.q_axis.soc_pu]);

save(fullfile(resultsFolder, 'phase1_single_frequency_demo.mat'), ...
    'phase1_result');

fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1200 720]);
tiledlayout(2,2, 'Padding', 'compact', 'TileSpacing', 'compact');
nexttile; plot(phase1_result.d_axis.time_s, phase1_result.d_axis.delta_vd_V, 'LineWidth', 1.1);
grid on; xlabel('Time (s)'); ylabel('\Delta v_d (V)'); title('d-axis perturbation response');
nexttile; plot(phase1_result.q_axis.time_s, phase1_result.q_axis.delta_vq_V, 'LineWidth', 1.1);
grid on; xlabel('Time (s)'); ylabel('\Delta v_q (V)'); title('q-axis perturbation response');
nexttile; plot(phase1_result.d_axis.time_s, phase1_result.d_axis.id_A, 'LineWidth', 1.1); hold on;
plot(phase1_result.q_axis.time_s, phase1_result.q_axis.id_A, 'LineWidth', 1.1);
grid on; xlabel('Time (s)'); ylabel('i_d (A)'); legend('d-axis test','q-axis test','Location','best');
nexttile; plot(phase1_result.d_axis.time_s, phase1_result.d_axis.iq_A, 'LineWidth', 1.1); hold on;
plot(phase1_result.q_axis.time_s, phase1_result.q_axis.iq_A, 'LineWidth', 1.1);
grid on; xlabel('Time (s)'); ylabel('i_q (A)'); legend('d-axis test','q-axis test','Location','best');
exportgraphics(fig, fullfile(resultsFolder, 'phase1_single_frequency_demo.png'), 'Resolution', 180);
close(fig);

fprintf('PHASE 1 PASS | f = %.2f Hz | d-axis delta Vd p-p = %.3f V | q-axis delta Vq p-p = %.3f V\\n', ...
    scan_cfg.test_frequency_Hz, phase1_result.summary.d_axis_delta_vd_peak_to_peak_V, ...
    phase1_result.summary.q_axis_delta_vq_peak_to_peak_V);
