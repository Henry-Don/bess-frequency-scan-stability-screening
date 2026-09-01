function studyResult = run_frequency_scan_repeatability(resultFile, forceRerun)
%RUN_FREQUENCY_SCAN_REPEATABILITY Compare two independent 10 Hz scans.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'scripts'));
resultsFolder = fullfile(projectRoot, 'results');
if ~isfolder(resultsFolder)
    mkdir(resultsFolder);
end
if nargin < 1 || isempty(resultFile)
    resultFile = fullfile(resultsFolder, 'phase1_repeatability.mat');
end
if nargin < 2
    forceRerun = false;
end

runAFile = fullfile(resultsFolder, 'phase1_repeatability_run_a.mat');
runBFile = fullfile(resultsFolder, 'phase1_repeatability_run_b.mat');
if forceRerun
    deleteIfPresent(runAFile);
    deleteIfPresent(runBFile);
    deleteIfPresent(resultFile);
end

caseConfiguration = struct('create_admittance_plot', false);
runA = run_frequency_scan(10, runAFile, caseConfiguration);
runB = run_frequency_scan(10, runBFile, caseConfiguration);
thresholds = runA.configuration.repeatability_thresholds;

admittanceA = runA.Y_dq_S(:,:,1);
admittanceB = runB.Y_dq_S(:,:,1);
globalScale = max(abs([admittanceA(:); admittanceB(:)]));
magnitudeDenominator = max(max(abs(admittanceA), ...
    abs(admittanceB)), globalScale*1e-6);
magnitudeDifference = abs(abs(admittanceA)-abs(admittanceB)) ./ ...
    magnitudeDenominator;
phaseDifferenceDeg = abs(rad2deg(angle( ...
    admittanceA.*conj(admittanceB))));

studyResult = struct();
studyResult.frequency_Hz = 10;
studyResult.run_a_result_file = runAFile;
studyResult.run_b_result_file = runBFile;
studyResult.run_a_admittance_S = admittanceA;
studyResult.run_b_admittance_S = admittanceB;
studyResult.magnitude_relative_difference = magnitudeDifference;
studyResult.phase_difference_deg = phaseDifferenceDeg;
studyResult.maximum_magnitude_relative_difference = ...
    max(magnitudeDifference, [], 'all');
studyResult.maximum_phase_difference_deg = ...
    max(phaseDifferenceDeg, [], 'all');
studyResult.thresholds = thresholds;
studyResult.passed = ...
    studyResult.maximum_magnitude_relative_difference <= ...
    thresholds.admittance_magnitude_relative_difference && ...
    studyResult.maximum_phase_difference_deg <= ...
    thresholds.admittance_phase_difference_deg;
studyResult.completed_utc = char(datetime('now','TimeZone','UTC', ...
    'Format','yyyy-MM-dd''T''HH:mm:ss''Z'''));
save(resultFile, 'studyResult');
fprintf(['10 HZ REPEATABILITY | magnitude drift %.6g | ' ...
    'phase drift %.6g deg | pass %d\n'], ...
    studyResult.maximum_magnitude_relative_difference, ...
    studyResult.maximum_phase_difference_deg, studyResult.passed);
end

function deleteIfPresent(file)
if isfile(file)
    delete(file);
end
end
