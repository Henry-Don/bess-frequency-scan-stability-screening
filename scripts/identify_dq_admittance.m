function point = identify_dq_admittance(baseline, dAxis, qAxis, frequencyHz, timing)
%IDENTIFY_DQ_ADMITTANCE Form the measured 2-by-2 dq admittance at one frequency.

dResponse = subtractBaseline(dAxis, baseline);
qResponse = subtractBaseline(qAxis, baseline);
dMask = dAxis.time_s >= timing.measurement_start_s & ...
    dAxis.time_s <= timing.measurement_end_s;
qMask = qAxis.time_s >= timing.measurement_start_s & ...
    qAxis.time_s <= timing.measurement_end_s;

[vdd, rvdd] = estimate_complex_tone(dAxis.time_s(dMask), dResponse.vd_V(dMask), frequencyHz);
[vqd, rvqd] = estimate_complex_tone(dAxis.time_s(dMask), dResponse.vq_V(dMask), frequencyHz);
[idd, ridd] = estimate_complex_tone(dAxis.time_s(dMask), dResponse.id_A(dMask), frequencyHz);
[iqd, riqd] = estimate_complex_tone(dAxis.time_s(dMask), dResponse.iq_A(dMask), frequencyHz);
[vdq, rvdq] = estimate_complex_tone(qAxis.time_s(qMask), qResponse.vd_V(qMask), frequencyHz);
[vqq, rvqq] = estimate_complex_tone(qAxis.time_s(qMask), qResponse.vq_V(qMask), frequencyHz);
[idq, ridq] = estimate_complex_tone(qAxis.time_s(qMask), qResponse.id_A(qMask), frequencyHz);
[iqq, riqq] = estimate_complex_tone(qAxis.time_s(qMask), qResponse.iq_A(qMask), frequencyHz);

voltageMatrix = [vdd, vdq; vqd, vqq];
currentMatrix = [idd, idq; iqd, iqq];
point = struct();
point.frequency_Hz = frequencyHz;
point.voltage_phasor_V = voltageMatrix;
point.current_phasor_A = currentMatrix;
point.Y_dq_S = currentMatrix/voltageMatrix;
point.voltage_matrix_condition = cond(voltageMatrix);
point.relative_fit_residual = [rvdd, rvdq; rvqd, rvqq; ridd, ridq; riqd, riqq];
point.maximum_fault_state = max([dAxis.fault_state; qAxis.fault_state]);
point.minimum_soc_pu = min([dAxis.soc_pu; qAxis.soc_pu]);
point.maximum_soc_pu = max([dAxis.soc_pu; qAxis.soc_pu]);
point.measured_cycles = timing.measured_cycles;
end

function response = subtractBaseline(runSignals, baseline)
fields = {'vd_V','vq_V','id_A','iq_A','p_W','q_var','pll_frequency_Hz'};
response = struct();
for k = 1:numel(fields)
    name = fields{k};
    reference = interp1(baseline.time_s, baseline.(name), ...
        runSignals.time_s, 'linear', 'extrap');
    response.(name) = runSignals.(name) - reference;
end
end
