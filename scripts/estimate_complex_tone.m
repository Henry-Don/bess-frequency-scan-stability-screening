function [phasor, relativeResidual] = estimate_complex_tone(time, value, frequencyHz)
%ESTIMATE_COMPLEX_TONE Estimate one complex sinusoidal phasor by least squares.

arguments
    time (:,1) double
    value (:,1) double
    frequencyHz (1,1) double {mustBeFinite, mustBePositive}
end

valid = isfinite(time) & isfinite(value);
time = time(valid);
value = value(valid);
if numel(time) < 20
    error('FrequencyScan:InsufficientSamples', ...
        'At least 20 finite samples are required for tone estimation.');
end

centeredTime = time - mean(time);
omega = 2*pi*frequencyHz;
design = [cos(omega*time), sin(omega*time), ...
    ones(size(time)), centeredTime];
coefficient = design\value;
fitted = design*coefficient;
phasor = coefficient(1) - 1i*coefficient(2);
acValue = value - mean(value);
relativeResidual = norm(value-fitted)/max(norm(acValue), eps);
end
