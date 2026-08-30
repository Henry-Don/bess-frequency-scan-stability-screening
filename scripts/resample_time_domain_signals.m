function uniform = resample_time_domain_signals(signals, sampleRateHz)
%RESAMPLE_TIME_DOMAIN_SIGNALS Put logged signals on a compact uniform grid.

validateattributes(sampleRateHz, {'numeric'}, ...
    {'real','finite','positive','scalar'}, mfilename, 'sampleRateHz');
time = signals.time_s(:);
if any(~isfinite(time)) || any(diff(time) <= 0)
    error('TimeDomainValidation:TimeBase', ...
        'The logged time vector must be finite and strictly increasing.');
end
uniformTime = (time(1):1/sampleRateHz:time(end)).';
fields = {'vd_V','vq_V','id_A','iq_A','p_W','q_var', ...
    'pll_frequency_Hz','soc_pu','fault_state'};
uniform = struct();
uniform.time_s = uniformTime;
for k = 1:numel(fields)
    name = fields{k};
    uniform.(name) = interp1(time, signals.(name)(:), ...
        uniformTime, 'linear');
end
uniform.sample_rate_Hz = sampleRateHz;
end
