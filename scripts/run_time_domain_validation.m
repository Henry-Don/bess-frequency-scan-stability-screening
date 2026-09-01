function studyResult = run_time_domain_validation(resultFile)
%RUN_TIME_DOMAIN_VALIDATION Cross-check three prescribed representative cases.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'models'));
addpath(fullfile(projectRoot, 'scripts'));
initializationFile = fullfile(projectRoot, 'scripts', 'init_frequency_scan.m');
variablesBeforeInitialization = who;
run(initializationFile);
initializedVariableNames = setdiff(who, variablesBeforeInitialization);
modelVariables = struct();
for variableIndex = 1:numel(initializedVariableNames)
    variableName = initializedVariableNames{variableIndex};
    modelVariables.(variableName) = eval(variableName);
end
resultsFolder = fullfile(projectRoot, 'results');
if ~isfolder(resultsFolder)
    mkdir(resultsFolder);
end
if nargin < 1 || isempty(resultFile)
    resultFile = fullfile(resultsFolder, ...
        'phase5_time_domain_validation.mat');
end

riskFile = fullfile(resultsFolder, 'phase4_pll_risk_map.mat');
if ~isfile(riskFile) || ...
        ~ismember('studyResult', who('-file', riskFile))
    run_pll_risk_map([], riskFile);
end
savedRisk = load(riskFile, 'studyResult');
riskMap = savedRisk.studyResult;

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

definitions = struct( ...
    'label', {'Case A','Case B','Case C'}, ...
    'planned_role', {'Low reference','Middle reference','High reference'}, ...
    'expected_risk_level', {'Lower','Moderate','Higher'}, ...
    'scr', {10,3,2}, ...
    'pll_scale', {1.0,1.0,2.0});
caseTemplate = struct('label','','planned_role','','scr',nan, ...
    'pll_scale',nan,'frequency_risk_score',nan, ...
    'frequency_risk_level','','critical_frequency_Hz',nan, ...
    'expected_frequency_risk_level','', ...
    'frequency_risk_matches_expectation',false, ...
    'case_signature','','signals',struct(),'metrics',struct());
cases = repmat(caseTemplate, 1, numel(definitions));

for k = 1:numel(definitions)
    definition = definitions(k);
    [riskScore, riskLevel, criticalFrequencyHz] = ...
        findRiskCell(riskMap, definition.scr, definition.pll_scale);
    signature = caseSignature(definition, validationCfg);
    caseFile = fullfile(resultsFolder, sprintf( ...
        'phase5_case_%s_time_domain.mat', lower(definition.label(end))));
    reusable = canReuseCase(caseFile, signature);
    if reusable
        savedCase = load(caseFile, 'caseResult');
        caseResult = savedCase.caseResult;
        fprintf('%s already complete; reusing saved time-domain result.\n', ...
            definition.label);
    else
        fprintf('\n%s | SCR = %g | PLL = %.3g | P step %.6g to %.6g W\n', ...
            definition.label, definition.scr, definition.pll_scale, ...
            validationCfg.initial_active_power_W, ...
            validationCfg.final_active_power_W);
        in = make_time_domain_validation_input(definition, validationCfg, ...
            scan_cfg, frequency_scan_model, modelVariables);
        out = sim(in);
        signals = extract_pcc_dq_signals(out);
        clear out
        signals = resample_time_domain_signals(signals, ...
            validationCfg.sample_rate_Hz);
        metrics = estimate_time_domain_metrics(signals, validationCfg);
        caseResult = caseTemplate;
        caseResult.label = definition.label;
        caseResult.planned_role = definition.planned_role;
        caseResult.scr = definition.scr;
        caseResult.pll_scale = definition.pll_scale;
        caseResult.frequency_risk_score = riskScore;
        caseResult.frequency_risk_level = riskLevel;
        caseResult.critical_frequency_Hz = criticalFrequencyHz;
        caseResult.case_signature = signature;
        caseResult.signals = signals;
        caseResult.metrics = metrics;
    end
    caseResult.frequency_risk_score = riskScore;
    caseResult.frequency_risk_level = riskLevel;
    caseResult.critical_frequency_Hz = criticalFrequencyHz;
    caseResult.expected_frequency_risk_level = ...
        definition.expected_risk_level;
    caseResult.frequency_risk_matches_expectation = strcmp( ...
        riskLevel, definition.expected_risk_level);
    caseResult = orderfields(caseResult, caseTemplate);
    save(caseFile, 'caseResult');
    cases(k) = caseResult;
    save(resultFile, 'cases', 'validationCfg');
    fprintf(['%s COMPLETE | frequency risk %.6g (%s) | overshoot %.4g%% | ' ...
        'settling %.4g s | oscillation %.4g Hz | decay ratio %.4g\n'], ...
        caseResult.label, caseResult.frequency_risk_score, ...
        caseResult.frequency_risk_level, ...
        caseResult.metrics.overshoot_percent, ...
        caseResult.metrics.settling_time_s, ...
        caseResult.metrics.dominant_oscillation_frequency_Hz, ...
        caseResult.metrics.oscillation_decay_ratio);
end

riskScores = [cases.frequency_risk_score];
overshoot = arrayfun(@(item)item.metrics.overshoot_percent, cases);
settling = arrayfun(@(item)item.metrics.settling_time_s, cases);
decay = arrayfun(@(item)item.metrics.oscillation_decay_ratio, cases);
settled = arrayfun(@(item)item.metrics.settled_within_window, cases);
riskMatch = [cases.frequency_risk_matches_expectation];
rankingAgreement = struct( ...
    'overshoot', pairwiseAgreement(riskScores, overshoot), ...
    'settling_time', pairwiseAgreement(riskScores, settling), ...
    'oscillation_decay_ratio', pairwiseAgreement(riskScores, decay));
interpretation = struct();
interpretation.expected_risk_levels = ...
    string({cases.expected_frequency_risk_level});
interpretation.actual_risk_levels = string({cases.frequency_risk_level});
interpretation.risk_level_matches_expectation = riskMatch;
interpretation.mismatch_case_labels = string({cases(~riskMatch).label});
interpretation.observation_window_after_step_s = ...
    validationCfg.stop_time_s-validationCfg.step_time_s;
interpretation.settled_case_count = nnz(settled);
interpretation.all_cases_settled = all(settled);
interpretation.settling_ranking_available = ...
    rankingAgreement.settling_time.compared_pairs > 0;
interpretation.overshoot_ranking_statement = sprintf( ...
    '%d/%d comparable pairs agree with frequency-risk ordering.', ...
    rankingAgreement.overshoot.matching_pairs, ...
    rankingAgreement.overshoot.compared_pairs);
interpretation.decay_ranking_statement = sprintf( ...
    '%d/%d comparable pairs agree with frequency-risk ordering.', ...
    rankingAgreement.oscillation_decay_ratio.matching_pairs, ...
    rankingAgreement.oscillation_decay_ratio.compared_pairs);
interpretation.settling_statement = sprintf([ ...
    '%d of %d cases entered the 5%% settling band within %.3g s; ' ...
    'settling-time ranking is unavailable.'], nnz(settled), ...
    numel(cases), interpretation.observation_window_after_step_s);
interpretation.conclusion = [ ...
    'Case A matches the prescribed lower-risk role. Case B is classified ' ...
    'Higher rather than Moderate under the fixed thresholds. Case C ' ...
    'matches the prescribed higher-risk role. The discrepancy is retained.'];
studyResult = struct();
studyResult.stage = 5;
studyResult.configuration = validationCfg;
studyResult.cases = cases;
studyResult.pairwise_ranking_agreement = rankingAgreement;
studyResult.interpretation = interpretation;
studyResult.completed_utc = char(datetime('now','TimeZone','UTC', ...
    'Format','yyyy-MM-dd''T''HH:mm:ss''Z'''));
save(resultFile, 'studyResult');
plot_time_domain_validation(studyResult, resultsFolder);
fprintf('\nTIME-DOMAIN VALIDATION COMPLETE | %d representative cases\n', ...
    numel(cases));
end

function [score, level, criticalFrequencyHz] = findRiskCell(riskMap, scr, pllScale)
row = find(abs(riskMap.scr_values-scr) <= 1e-12, 1);
column = find(abs(riskMap.pll_scales-pllScale) <= 1e-12, 1);
if isempty(row) || isempty(column)
    error('TimeDomainValidation:RiskCell', ...
        'The requested SCR/PLL case is absent from the risk map.');
end
score = riskMap.peak_interaction_gain(row,column);
level = char(riskMap.risk_level(row,column));
criticalFrequencyHz = riskMap.critical_frequency_Hz(row,column);
end

function reusable = canReuseCase(caseFile, expectedSignature)
reusable = false;
if ~isfile(caseFile) || ~ismember('caseResult', who('-file', caseFile))
    return
end
saved = load(caseFile, 'caseResult');
reusable = isfield(saved.caseResult, 'case_signature') && ...
    strcmp(saved.caseResult.case_signature, expectedSignature);
end

function value = caseSignature(definition, configuration)
value = sprintf(['SCR=%.12g|PLL=%.12g|P0=%.12g|P1=%.12g|' ...
    'TSTEP=%.12g|TSTOP=%.12g|FS=%.12g'], definition.scr, ...
    definition.pll_scale, configuration.initial_active_power_W, ...
    configuration.final_active_power_W, configuration.step_time_s, ...
    configuration.stop_time_s, configuration.sample_rate_Hz);
end

function agreement = pairwiseAgreement(riskScore, observedMetric)
matching = 0;
compared = 0;
for first = 1:numel(riskScore)-1
    for second = first+1:numel(riskScore)
        riskDirection = sign(riskScore(first)-riskScore(second));
        metricDirection = sign(observedMetric(first)-observedMetric(second));
        if riskDirection ~= 0 && metricDirection ~= 0
            compared = compared+1;
            matching = matching+(riskDirection == metricDirection);
        end
    end
end
agreement = struct('matching_pairs',matching, ...
    'compared_pairs',compared,'fraction',matching/max(compared,1));
end
