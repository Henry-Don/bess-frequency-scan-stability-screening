function studyResult = run_scr_interaction_scan(frequenciesHz, resultFile)
%RUN_SCR_INTERACTION_SCAN Run four resumable SCR cases at nominal PLL gain.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'scripts'));
initializationFile = fullfile(projectRoot, 'scripts', 'init_frequency_scan.m');
run(initializationFile);
if nargin < 1 || isempty(frequenciesHz)
    frequenciesHz = scan_cfg.frequencies_Hz;
end
resultsFolder = fullfile(projectRoot, 'results');
if ~isfolder(resultsFolder)
    mkdir(resultsFolder);
end
if nargin < 2 || isempty(resultFile)
    resultFile = fullfile(resultsFolder, 'phase3_scr_interaction.mat');
end

scrValues = [10 5 3 2];
cases = repmat(struct('scr',nan,'scan_file','','scan',struct(), ...
    'metric',struct()), 1, numel(scrValues));
for k = 1:numel(scrValues)
    scr = scrValues(k);
    scanFile = fullfile(resultsFolder, ...
        sprintf('phase3_scr_%g_frequency_scan.mat', scr));
    fprintf('\nSCR CASE %d/%d | SCR = %g | nominal PLL\n', ...
        k, numel(scrValues), scr);
    caseConfig = struct('scr',scr,'pll_scale',1.0, ...
        'create_admittance_plot',false);
    scan = run_frequency_scan(frequenciesHz, scanFile, caseConfig);
    cases(k).scr = scr;
    cases(k).scan_file = scanFile;
    cases(k).scan = scan;
    cases(k).metric = compute_interaction_metric(scan);
    save(resultFile, 'cases', 'scrValues');
    fprintf('SCR %g COMPLETE | peak gain %.6g at %.6g Hz | %s risk\n', ...
        scr, cases(k).metric.peak_interaction_gain, ...
        cases(k).metric.critical_frequency_Hz, ...
        cases(k).metric.risk_level);
end

studyResult = struct();
studyResult.stage = 3;
studyResult.frequency_Hz = frequenciesHz(:).';
studyResult.scr_values = scrValues;
studyResult.pll_scale = 1.0;
studyResult.cases = cases;
studyResult.thresholds = scan_cfg.interaction_thresholds;
studyResult.metric_definition = ...
    'maximum singular value of Zgrid times Ybess';
studyResult.completed_utc = char(datetime('now','TimeZone','UTC', ...
    'Format','yyyy-MM-dd''T''HH:mm:ss''Z'''));
save(resultFile, 'studyResult');
plot_scr_interaction_metric(studyResult, resultsFolder);
fprintf('\nSCR INTERACTION STUDY COMPLETE | %d SCR cases | %d injection runs\n', ...
    numel(scrValues), 2*numel(scrValues)*numel(frequenciesHz));
end
