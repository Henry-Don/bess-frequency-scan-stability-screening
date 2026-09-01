function studyResult = run_baseline_equivalence(referenceModelFile, resultFile)
%RUN_BASELINE_EQUIVALENCE Compare disabled-perturbation baseline signals.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'models'));
addpath(fullfile(projectRoot, 'scripts'));
if nargin < 1 || isempty(referenceModelFile)
    referenceModelFile = fullfile(fileparts(projectRoot), ...
        'grid-connected-bess-control-validation', 'models', ...
        'bess_final_physical_validation.slx');
end
if ~isfile(referenceModelFile)
    error('FrequencyScan:ReferenceModelMissing', ...
        'The project-one reference model was not found: %s', ...
        referenceModelFile);
end
referenceProjectRoot = fileparts(fileparts(referenceModelFile));
addpath(fullfile(referenceProjectRoot, 'models'), '-end');
addpath(fullfile(referenceProjectRoot, 'scripts'), '-end');

resultsFolder = fullfile(projectRoot, 'results');
if ~isfolder(resultsFolder)
    mkdir(resultsFolder);
end
if nargin < 2 || isempty(resultFile)
    resultFile = fullfile(resultsFolder, ...
        'phase1_baseline_equivalence.mat');
end

initializationFile = fullfile(projectRoot, 'scripts', ...
    'init_frequency_scan.m');
evalin('base', ['run(''' strrep(initializationFile, '''', '''''') ''')']);
scanConfiguration = evalin('base', 'scan_cfg');
candidateModel = evalin('base', 'frequency_scan_model');
[~, referenceModel] = fileparts(referenceModelFile);
frequencyHz = scanConfiguration.test_frequency_Hz;

candidateConfiguration = scanConfiguration;
candidateConfiguration.pcc_source_block = ...
    [candidateModel '/Grid_11kV'];
in = make_frequency_scan_input('off', frequencyHz, false, ...
    candidateConfiguration, candidateModel);
out = sim(in);
candidateSignals = extract_pcc_dq_signals(out);
clear out

referenceConfiguration = scanConfiguration;
referenceConfiguration.pcc_source_block = ...
    [referenceModel '/Grid_11kV'];
in = make_frequency_scan_input('off', frequencyHz, false, ...
    referenceConfiguration, referenceModel);
out = sim(in);
referenceSignals = extract_pcc_dq_signals(out);
clear out

fields = {'vd_V','vq_V','id_A','iq_A','p_W','q_var', ...
    'pll_frequency_Hz','soc_pu','fault_state'};
scaleFloors = [1 1 1 1 1 1 1e-3 1e-6 1];
metricTemplate = struct('signal','','relative_rms_error',nan, ...
    'normalized_maximum_error',nan,'candidate_final_mean',nan, ...
    'reference_final_mean',nan,'passed',false);
metrics = repmat(metricTemplate, 1, numel(fields));
thresholds = scanConfiguration.baseline_equivalence_thresholds;
candidateTime = candidateSignals.time_s(:);
finalMask = candidateTime >= candidateTime(end)-0.20;
for k = 1:numel(fields)
    name = fields{k};
    candidateValue = candidateSignals.(name)(:);
    referenceValue = interp1(referenceSignals.time_s(:), ...
        referenceSignals.(name)(:), candidateTime, 'linear', 'extrap');
    difference = candidateValue-referenceValue;
    rmsScale = max(sqrt(mean(referenceValue.^2)), scaleFloors(k));
    maximumScale = max(max(abs(referenceValue)), scaleFloors(k));
    metrics(k).signal = name;
    metrics(k).relative_rms_error = ...
        sqrt(mean(difference.^2))/rmsScale;
    metrics(k).normalized_maximum_error = ...
        max(abs(difference))/maximumScale;
    metrics(k).candidate_final_mean = mean(candidateValue(finalMask));
    metrics(k).reference_final_mean = mean(referenceValue(finalMask));
    metrics(k).passed = ...
        metrics(k).relative_rms_error <= thresholds.relative_rms_error && ...
        metrics(k).normalized_maximum_error <= ...
        thresholds.normalized_maximum_error;
end

candidateModelFile = fullfile(projectRoot, 'models', ...
    [candidateModel '.slx']);
studyResult = struct();
studyResult.candidate_model_file = candidateModelFile;
studyResult.reference_model_file = referenceModelFile;
studyResult.model_files_byte_identical = filesAreIdentical( ...
    candidateModelFile, referenceModelFile);
studyResult.perturbation_enabled = false;
studyResult.frequency_Hz = frequencyHz;
studyResult.signal_metrics = metrics;
studyResult.maximum_relative_rms_error = ...
    max([metrics.relative_rms_error]);
studyResult.maximum_normalized_error = ...
    max([metrics.normalized_maximum_error]);
studyResult.thresholds = thresholds;
studyResult.passed = all([metrics.passed]);
studyResult.completed_utc = char(datetime('now','TimeZone','UTC', ...
    'Format','yyyy-MM-dd''T''HH:mm:ss''Z'''));
save(resultFile, 'studyResult');
fprintf(['BASELINE EQUIVALENCE | byte identical %d | relative RMS %.6g | ' ...
    'normalized maximum %.6g | pass %d\n'], ...
    studyResult.model_files_byte_identical, ...
    studyResult.maximum_relative_rms_error, ...
    studyResult.maximum_normalized_error, studyResult.passed);
end

function identical = filesAreIdentical(firstFile, secondFile)
firstInfo = dir(firstFile);
secondInfo = dir(secondFile);
if firstInfo.bytes ~= secondInfo.bytes
    identical = false;
    return
end
firstId = fopen(firstFile, 'rb');
if firstId < 0
    error('FrequencyScan:FileRead', 'Unable to read %s.', firstFile);
end
firstCleanup = onCleanup(@()fclose(firstId));
firstBytes = fread(firstId, inf, '*uint8');
secondId = fopen(secondFile, 'rb');
if secondId < 0
    error('FrequencyScan:FileRead', 'Unable to read %s.', secondFile);
end
secondCleanup = onCleanup(@()fclose(secondId));
secondBytes = fread(secondId, inf, '*uint8');
identical = isequal(firstBytes, secondBytes);
clear firstCleanup secondCleanup
end
