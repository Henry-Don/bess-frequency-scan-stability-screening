function signals = extract_pcc_dq_signals(out, referenceTime, referenceAngle)
%EXTRACT_PCC_DQ_SIGNALS Convert PCC abc values into a synchronous dq frame.

vabc = out.v_pcc_abc;
iabc = out.i_pcc_abc;
theta = out.pll_theta_rad;

time = vabc.Time(:);
vll = squeeze(vabc.Data);
iabcData = squeeze(iabc.Data);
measuredAngle = unwrap(squeeze(theta.Data));
measuredAngle = interp1(theta.Time(:), measuredAngle, time, 'linear', 'extrap');
if nargin < 3
    referenceAngleData = measuredAngle;
else
    referenceAngleData = interp1(referenceTime(:), unwrap(referenceAngle(:)), ...
        time, 'linear', 'extrap');
end

if size(vll,1) ~= numel(time)
    vll = vll.';
end
if size(iabcData,1) ~= numel(time)
    iabcData = iabcData.';
end

va = (vll(:,1) - vll(:,3))/3;
vb = (vll(:,2) - vll(:,1))/3;
vc = (vll(:,3) - vll(:,2))/3;
vAlpha = (2/3)*(va - 0.5*vb - 0.5*vc);
vBeta = (sqrt(3)/3)*(vb - vc);
iAlpha = (2/3)*(iabcData(:,1) - 0.5*iabcData(:,2) - 0.5*iabcData(:,3));
iBeta = (sqrt(3)/3)*(iabcData(:,2) - iabcData(:,3));

c = cos(referenceAngleData);
s = sin(referenceAngleData);
signals = struct();
signals.time_s = time;
signals.vd_V = vAlpha.*c + vBeta.*s;
signals.vq_V = -vAlpha.*s + vBeta.*c;
signals.id_A = iAlpha.*c + iBeta.*s;
signals.iq_A = -iAlpha.*s + iBeta.*c;
signals.p_W = interpolateSignal(out.p_pcc_W, time);
signals.q_var = interpolateSignal(out.q_pcc_var, time);
signals.pll_frequency_Hz = interpolateSignal(out.pll_omega_rad_s, time)/(2*pi);
signals.pll_angle_rad = measuredAngle;
signals.reference_angle_rad = referenceAngleData;
signals.soc_pu = interpolateSignal(out.soc_pu, time);
signals.fault_state = interpolateSignal(out.physical_fault_state, time);
end

function value = interpolateSignal(ts, time)
value = interp1(ts.Time(:), squeeze(ts.Data), time, 'linear', 'extrap');
value = value(:);
end
