function metric = compute_interaction_metric(scanResult)
%COMPUTE_INTERACTION_METRIC Evaluate converter-grid interaction strength.
% The primary score is max(svd(Zgrid*Ybess)).  It is independent of a
% current-reference sign choice and supplies a conservative small-gain
% screen.  It is a comparative risk indicator, not a formal stability
% proof.  Larger values indicate stronger converter-grid interaction.

if ~all(scanResult.completed)
    error('InteractionMetric:IncompleteScan', ...
        'All frequency points must be complete before scoring.');
end
configuration = scanResult.configuration;
grid = compute_grid_dq_impedance(scanResult.frequency_Hz, ...
    configuration.scr, configuration);
n = numel(scanResult.frequency_Hz);
interactionGain = nan(1,n);
returnDifferenceDistance = nan(1,n);
spectralRadius = nan(1,n);
loopGain = complex(nan(2,2,n));
for k = 1:n
    loopGain(:,:,k) = grid.Z_dq_Ohm(:,:,k)*scanResult.Y_dq_S(:,:,k);
    singularValues = svd(loopGain(:,:,k));
    interactionGain(k) = max(singularValues);
    returnDifferenceDistance(k) = min(svd(eye(2) + loopGain(:,:,k)));
    spectralRadius(k) = max(abs(eig(loopGain(:,:,k))));
end

[peakGain, criticalIndex] = max(interactionGain);
thresholds = configuration.interaction_thresholds;
if peakGain < thresholds.moderate
    riskLevel = 'Lower';
elseif peakGain < thresholds.higher
    riskLevel = 'Moderate';
else
    riskLevel = 'Higher';
end

metric = struct();
metric.definition = 'maximum singular value of Zgrid times Ybess';
metric.interpretation = 'comparative small-gain interaction screen';
metric.frequency_Hz = scanResult.frequency_Hz;
metric.loop_gain = loopGain;
metric.interaction_gain = interactionGain;
metric.return_difference_distance = returnDifferenceDistance;
metric.spectral_radius = spectralRadius;
metric.peak_interaction_gain = peakGain;
metric.critical_frequency_Hz = scanResult.frequency_Hz(criticalIndex);
metric.critical_frequency_index = criticalIndex;
metric.risk_level = riskLevel;
metric.thresholds = thresholds;
metric.grid = grid;
end
