function timing = frequency_scan_timing(scanCfg, frequencyHz)
%FREQUENCY_SCAN_TIMING Return adaptive excitation and measurement windows.

arguments
    scanCfg (1,1) struct
    frequencyHz (1,1) double {mustBeFinite, mustBePositive}
end

cycleDuration = 1/frequencyHz;
injectionDuration = max(scanCfg.injection_cycles*cycleDuration, ...
    scanCfg.minimum_injection_s);
timing = struct();
timing.enable_time_s = scanCfg.pre_injection_s;
timing.disable_time_s = timing.enable_time_s + injectionDuration;
timing.stop_time_s = timing.disable_time_s + scanCfg.post_injection_s;
timing.measurement_start_s = timing.enable_time_s + ...
    min(scanCfg.discard_cycles*cycleDuration, 0.5*injectionDuration);
timing.measurement_end_s = timing.disable_time_s;
timing.measured_cycles = (timing.measurement_end_s - ...
    timing.measurement_start_s)*frequencyHz;
end
