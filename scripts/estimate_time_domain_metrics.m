function metrics = estimate_time_domain_metrics(signals, validationCfg)
%ESTIMATE_TIME_DOMAIN_METRICS Quantify step response and oscillation decay.

time = signals.time_s(:);
activePower = signals.p_W(:);
pllFrequency = signals.pll_frequency_Hz(:);
stepTime = validationCfg.step_time_s;
stopTime = validationCfg.stop_time_s;
commandChange = validationCfg.final_active_power_W - ...
    validationCfg.initial_active_power_W;
direction = sign(commandChange);
if direction == 0
    error('TimeDomainValidation:ZeroStep', ...
        'The active-power command step must be nonzero.');
end

preMask = time >= stepTime-validationCfg.pre_window_s & ...
    time <= stepTime-validationCfg.pre_guard_s;
finalMask = time >= stopTime-validationCfg.final_window_s;
if nnz(preMask) < 3 || nnz(finalMask) < 3
    error('TimeDomainValidation:MetricWindows', ...
        'The configured pre-step or final metric window is too short.');
end
initialPower = mean(activePower(preMask));
finalPower = mean(activePower(finalMask));
measuredChange = finalPower-initialPower;
normalizedPower = direction*(activePower-initialPower)/abs(commandChange);
finalNormalized = direction*measuredChange/abs(commandChange);
postMask = time >= stepTime;
peakNormalized = max(normalizedPower(postMask));
overshootPercent = 100*max(0, peakNormalized-finalNormalized) / ...
    max(abs(finalNormalized), 0.05);

settlingBandW = validationCfg.settling_tolerance*abs(commandChange);
postIndices = find(postMask);
outside = abs(activePower(postMask)-finalPower) > settlingBandW;
lastOutside = find(outside, 1, 'last');
if isempty(lastOutside)
    settled = true;
    settlingTime = 0;
elseif lastOutside < numel(postIndices)
    settled = true;
    settlingTime = time(postIndices(lastOutside+1))-stepTime;
else
    settled = false;
    settlingTime = stopTime-stepTime;
end

smoothSamples = max(3, round( ...
    validationCfg.residual_smoothing_s*signals.sample_rate_Hz));
powerTrend = smoothdata(activePower, 'movmean', smoothSamples);
powerResidualPu = (activePower-powerTrend)/abs(commandChange);
earlyMask = time >= stepTime+validationCfg.early_window_s(1) & ...
    time <= stepTime+validationCfg.early_window_s(2);
lateMask = time >= stopTime-validationCfg.late_window_s(2) & ...
    time <= stopTime-validationCfg.late_window_s(1);
earlyRms = sqrt(mean(powerResidualPu(earlyMask).^2));
lateRms = sqrt(mean(powerResidualPu(lateMask).^2));
decayRatio = lateRms/max(earlyRms, eps);

spectralMask = time >= stepTime+validationCfg.spectral_delay_s & ...
    time <= min(stopTime, stepTime+validationCfg.spectral_duration_s);
spectralSignal = powerResidualPu(spectralMask);
[dominantFrequencyHz, dominantAmplitudePu] = dominantFrequency( ...
    spectralSignal, signals.sample_rate_Hz, ...
    validationCfg.oscillation_frequency_band_Hz);

if decayRatio < 0.25
    dampingBehaviour = 'Strongly decaying';
elseif decayRatio < 0.60
    dampingBehaviour = 'Decaying';
elseif decayRatio < 1.0
    dampingBehaviour = 'Weakly decaying';
else
    dampingBehaviour = 'Non-decaying tendency';
end

metrics = struct();
metrics.initial_active_power_W = initialPower;
metrics.final_active_power_W = finalPower;
metrics.measured_active_power_change_W = measuredChange;
metrics.final_tracking_error_percent = 100*abs(finalNormalized-1);
metrics.overshoot_percent = overshootPercent;
metrics.settling_time_s = settlingTime;
metrics.settled_within_window = settled;
metrics.settling_band_W = settlingBandW;
metrics.dominant_oscillation_frequency_Hz = dominantFrequencyHz;
metrics.dominant_oscillation_amplitude_pu = dominantAmplitudePu;
metrics.oscillation_early_rms_pu = earlyRms;
metrics.oscillation_late_rms_pu = lateRms;
metrics.oscillation_decay_ratio = decayRatio;
metrics.damping_behaviour = dampingBehaviour;
metrics.maximum_pll_frequency_deviation_Hz = max(abs( ...
    pllFrequency(postMask)-validationCfg.nominal_frequency_Hz));
metrics.normalized_active_power = normalizedPower;
metrics.active_power_residual_pu = powerResidualPu;
end

function [frequencyHz, amplitude] = dominantFrequency(signal, sampleRateHz, bandHz)
signal = signal(:)-mean(signal(:));
n = numel(signal);
if n < 8
    error('TimeDomainValidation:SpectralWindow', ...
        'The spectral window contains too few samples.');
end
window = 0.5-0.5*cos(2*pi*(0:n-1)'/(n-1));
spectrum = abs(fft(signal.*window));
frequency = (0:n-1)'*sampleRateHz/n;
oneSided = 1:floor(n/2)+1;
frequency = frequency(oneSided);
spectrum = spectrum(oneSided);
mask = frequency >= bandHz(1) & frequency <= bandHz(2);
if ~any(mask)
    error('TimeDomainValidation:FrequencyBand', ...
        'The oscillation frequency band is outside the FFT grid.');
end
candidateFrequency = frequency(mask);
candidateSpectrum = spectrum(mask);
[peak, index] = max(candidateSpectrum);
frequencyHz = candidateFrequency(index);
amplitude = 2*peak/max(sum(window), eps);
end
