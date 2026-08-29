function studyResult = run_pll_risk_map(frequenciesHz, resultFile)
%RUN_PLL_RISK_MAP Sweep the complete SCR-by-PLL interaction matrix.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'scripts'));
initializationFile = fullfile(projectRoot, 'scripts', 'init_frequency_scan.m');
run(initializationFile);
if nargin < 1 || isempty(frequenciesHz)
    frequenciesHz = scan_cfg.frequencies_Hz;
end
frequenciesHz = frequenciesHz(:).';
resultsFolder = fullfile(projectRoot, 'results');
if ~isfolder(resultsFolder)
    mkdir(resultsFolder);
end
if nargin < 2 || isempty(resultFile)
    resultFile = fullfile(resultsFolder, 'phase4_pll_risk_map.mat');
end

scrValues = [10 5 3 2];
pllScales = [0.5 1.0 1.5 2.0];
caseTemplate = struct('scr',nan,'pll_scale',nan,'scan_file','', ...
    'reused_phase3',false,'scan',struct(),'metric',struct());
cases = repmat(caseTemplate, numel(scrValues), numel(pllScales));

for row = 1:numel(scrValues)
    for column = 1:numel(pllScales)
        scr = scrValues(row);
        pllScale = pllScales(column);
        fprintf('\nPLL MATRIX CASE (%d,%d)/(%d,%d) | SCR = %g | PLL = %.3g\n', ...
            row, column, numel(scrValues), numel(pllScales), ...
            scr, pllScale);

        phase3File = fullfile(resultsFolder, ...
            sprintf('phase3_scr_%g_frequency_scan.mat', scr));
        reusedPhase3 = pllScale == 1.0 && ...
            canReuseScan(phase3File, frequenciesHz, scr, pllScale);
        if reusedPhase3
            saved = load(phase3File, 'scanResult');
            scan = saved.scanResult;
            scanFile = phase3File;
            fprintf('Reusing the verified nominal-PLL scan.\n');
        else
            scanFile = fullfile(resultsFolder, sprintf( ...
                'phase4_scr_%g_pll_%s_frequency_scan.mat', ...
                scr, numericToken(pllScale)));
            caseConfig = struct('scr',scr,'pll_scale',pllScale, ...
                'create_admittance_plot',false);
            scan = run_frequency_scan(frequenciesHz, scanFile, caseConfig);
        end

        cases(row,column).scr = scr;
        cases(row,column).pll_scale = pllScale;
        cases(row,column).scan_file = scanFile;
        cases(row,column).reused_phase3 = reusedPhase3;
        cases(row,column).scan = scan;
        cases(row,column).metric = compute_interaction_metric(scan);
        save(resultFile, 'cases', 'scrValues', 'pllScales');
        fprintf('CASE COMPLETE | peak %.6g at %.6g Hz | %s risk\n', ...
            cases(row,column).metric.peak_interaction_gain, ...
            cases(row,column).metric.critical_frequency_Hz, ...
            cases(row,column).metric.risk_level);
    end
end

peakGain = reshape(arrayfun(@(x) x.metric.peak_interaction_gain, cases), ...
    size(cases));
criticalFrequencyHz = reshape(arrayfun( ...
    @(x) x.metric.critical_frequency_Hz, cases), size(cases));
minimumReturnDifference = reshape(arrayfun( ...
    @(x) min(x.metric.return_difference_distance,[],'all'), cases), ...
    size(cases));
riskCode = ones(size(peakGain));
riskCode(peakGain >= scan_cfg.interaction_thresholds.moderate) = 2;
riskCode(peakGain >= scan_cfg.interaction_thresholds.higher) = 3;
riskLevel = strings(size(cases));
for k = 1:numel(cases)
    riskLevel(k) = string(cases(k).metric.risk_level);
end
reusedMask = reshape([cases.reused_phase3], size(cases));

studyResult = struct();
studyResult.stage = 4;
studyResult.frequency_Hz = frequenciesHz;
studyResult.scr_values = scrValues;
studyResult.pll_scales = pllScales;
studyResult.cases = cases;
studyResult.peak_interaction_gain = peakGain;
studyResult.critical_frequency_Hz = criticalFrequencyHz;
studyResult.minimum_return_difference = minimumReturnDifference;
studyResult.risk_code = riskCode;
studyResult.risk_level = riskLevel;
studyResult.thresholds = scan_cfg.interaction_thresholds;
studyResult.reused_phase3_mask = reusedMask;
studyResult.total_matrix_injection_runs = ...
    2*numel(cases)*numel(frequenciesHz);
studyResult.reused_injection_runs = ...
    2*nnz(reusedMask)*numel(frequenciesHz);
studyResult.new_injection_runs = studyResult.total_matrix_injection_runs - ...
    studyResult.reused_injection_runs;
studyResult.metric_definition = ...
    'maximum singular value of Zgrid times Ybess';
studyResult.completed_utc = char(datetime('now','TimeZone','UTC', ...
    'Format','yyyy-MM-dd''T''HH:mm:ss''Z'''));
save(resultFile, 'studyResult');
plot_pll_risk_map(studyResult, resultsFolder);
fprintf(['\nPLL RISK MAP COMPLETE | %d cases | %d represented runs | ' ...
    '%d new runs\n'], numel(cases), ...
    studyResult.total_matrix_injection_runs, studyResult.new_injection_runs);
end

function reusable = canReuseScan(scanFile, frequenciesHz, scr, pllScale)
reusable = false;
if ~isfile(scanFile)
    return
end
savedNames = who('-file', scanFile);
if ~ismember('scanResult', savedNames)
    return
end
saved = load(scanFile, 'scanResult');
scan = saved.scanResult;
required = {'frequency_Hz','completed','configuration'};
if ~all(isfield(scan, required)) || ~all(scan.completed)
    return
end
configuration = scan.configuration;
if ~all(isfield(configuration, {'scr','pll_scale'}))
    return
end
reusable = isequal(scan.frequency_Hz, frequenciesHz) && ...
    abs(configuration.scr-scr) <= 1e-12 && ...
    abs(configuration.pll_scale-pllScale) <= 1e-12;
end

function value = numericToken(number)
value = strrep(sprintf('%.3g', number), '.', 'p');
value = strrep(value, '-', 'm');
end
