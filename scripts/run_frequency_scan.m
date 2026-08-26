function scanResult = run_frequency_scan(frequenciesHz, resultFile)
%RUN_FREQUENCY_SCAN Execute resumable d/q sinusoidal frequency scans.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'models'));
addpath(fullfile(projectRoot, 'scripts'));
initializationFile = fullfile(projectRoot, 'scripts', 'init_frequency_scan.m');
evalin('base', ['run(''' strrep(initializationFile, '''', '''''') ''')']);
scan_cfg = evalin('base', 'scan_cfg');
frequency_scan_model = evalin('base', 'frequency_scan_model');

if nargin < 1 || isempty(frequenciesHz)
    frequenciesHz = scan_cfg.frequencies_Hz;
end
frequenciesHz = frequenciesHz(:).';
if any(~isfinite(frequenciesHz)) || any(frequenciesHz <= 0) || ...
        any(diff(frequenciesHz) <= 0)
    error('FrequencyScan:FrequencyVector', ...
        'frequenciesHz must contain finite, positive, strictly increasing values.');
end

resultsFolder = fullfile(projectRoot, 'results');
if ~isfolder(resultsFolder)
    mkdir(resultsFolder);
end
if nargin < 2 || isempty(resultFile)
    resultFile = fullfile(resultsFolder, 'phase2_frequency_scan.mat');
end

scanResult = initializeOrResume(resultFile, frequenciesHz, scan_cfg);
baselineFrequencyHz = min(frequenciesHz);
fprintf('Running shared perturbation-disabled baseline to %.3f s.\n', ...
    frequency_scan_timing(scan_cfg, baselineFrequencyHz).stop_time_s);
out = sim(make_frequency_scan_input('off', baselineFrequencyHz, false, ...
    scan_cfg, frequency_scan_model));
baseline = extract_pcc_dq_signals(out);
clear out

for k = 1:numel(frequenciesHz)
    if scanResult.completed(k)
        fprintf('[%d/%d] %.6g Hz already complete; skipping.\n', ...
            k, numel(frequenciesHz), frequenciesHz(k));
        continue
    end
    frequencyHz = frequenciesHz(k);
    timing = frequency_scan_timing(scan_cfg, frequencyHz);
    fprintf('[%d/%d] %.6g Hz | d-axis injection\n', ...
        k, numel(frequenciesHz), frequencyHz);
    out = sim(make_frequency_scan_input('d', frequencyHz, true, ...
        scan_cfg, frequency_scan_model));
    dAxis = extract_pcc_dq_signals(out, baseline.time_s, ...
        baseline.reference_angle_rad);
    clear out

    fprintf('[%d/%d] %.6g Hz | q-axis injection\n', ...
        k, numel(frequenciesHz), frequencyHz);
    out = sim(make_frequency_scan_input('q', frequencyHz, true, ...
        scan_cfg, frequency_scan_model));
    qAxis = extract_pcc_dq_signals(out, baseline.time_s, ...
        baseline.reference_angle_rad);
    clear out

    point = identify_dq_admittance(baseline, dAxis, qAxis, frequencyHz, timing);
    scanResult.Y_dq_S(:,:,k) = point.Y_dq_S;
    scanResult.voltage_phasor_V(:,:,k) = point.voltage_phasor_V;
    scanResult.current_phasor_A(:,:,k) = point.current_phasor_A;
    scanResult.voltage_matrix_condition(k) = point.voltage_matrix_condition;
    scanResult.maximum_fit_residual(k) = max(point.relative_fit_residual, [], 'all');
    scanResult.maximum_fault_state(k) = point.maximum_fault_state;
    scanResult.minimum_soc_pu(k) = point.minimum_soc_pu;
    scanResult.maximum_soc_pu(k) = point.maximum_soc_pu;
    scanResult.measured_cycles(k) = point.measured_cycles;
    scanResult.completed(k) = true;
    scanResult.last_completed_frequency_Hz = frequencyHz;
    save(resultFile, 'scanResult');
    fprintf('  complete | cond(V)=%.3g | max fit residual=%.3g\n', ...
        point.voltage_matrix_condition, scanResult.maximum_fit_residual(k));
end

scanResult.completed_utc = char(datetime('now','TimeZone','UTC', ...
    'Format','yyyy-MM-dd''T''HH:mm:ss''Z'''));
save(resultFile, 'scanResult');
plot_frequency_scan_admittance(scanResult, resultsFolder);
fprintf('FREQUENCY SCAN COMPLETE | %d frequencies | %d injection runs\n', ...
    numel(frequenciesHz), 2*numel(frequenciesHz));
end

function scanResult = initializeOrResume(resultFile, frequenciesHz, scanCfg)
if isfile(resultFile)
    saved = load(resultFile, 'scanResult');
    if isequal(saved.scanResult.frequency_Hz, frequenciesHz)
        scanResult = saved.scanResult;
        return
    end
end
n = numel(frequenciesHz);
scanResult = struct();
scanResult.frequency_Hz = frequenciesHz;
scanResult.Y_dq_S = complex(nan(2,2,n));
scanResult.voltage_phasor_V = complex(nan(2,2,n));
scanResult.current_phasor_A = complex(nan(2,2,n));
scanResult.voltage_matrix_condition = nan(1,n);
scanResult.maximum_fit_residual = nan(1,n);
scanResult.maximum_fault_state = nan(1,n);
scanResult.minimum_soc_pu = nan(1,n);
scanResult.maximum_soc_pu = nan(1,n);
scanResult.measured_cycles = nan(1,n);
scanResult.completed = false(1,n);
scanResult.configuration = scanCfg;
scanResult.last_completed_frequency_Hz = nan;
scanResult.completed_utc = '';
end
