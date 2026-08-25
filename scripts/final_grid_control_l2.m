function final_grid_control_l2(block)
%FINAL_GRID_CONTROL_L2 Level-2 GFL controller with protection and SoC limits.
% Input: [vabc(3), iabc(3), vdc, pRef, qRef, vdcRef, SoC].
% Output: [mabc(3), theta, omega, id, iq, idRef, iqRef, xiVdc, xiId, xiIq].

setup(block);
end

function setup(block)
block.NumDialogPrms = 1;
block.NumInputPorts = 1;
block.NumOutputPorts = 1;
block.InputPort(1).Dimensions = 11;
block.InputPort(1).DatatypeID = 0;
block.InputPort(1).Complexity = 'Real';
block.InputPort(1).DirectFeedthrough = false;
block.OutputPort(1).Dimensions = 12;
block.OutputPort(1).DatatypeID = 0;
block.OutputPort(1).Complexity = 'Real';
block.SampleTimes = [50e-6 0];
block.SimStateCompliance = 'DefaultSimState';
block.RegBlockMethod('PostPropagationSetup', @postPropagationSetup);
block.RegBlockMethod('InitializeConditions', @initializeConditions);
block.RegBlockMethod('Outputs', @outputs);
block.RegBlockMethod('Update', @update);
end

function postPropagationSetup(block)
block.NumDworks = 1;
block.Dwork(1).Name = 'controllerState';
block.Dwork(1).Dimensions = 15;
block.Dwork(1).DatatypeID = 0;
block.Dwork(1).Complexity = 'Real';
block.Dwork(1).UsedAsDiscState = true;
end

function initializeConditions(block)
cfg = block.DialogPrm(1).Data;
x0 = zeros(15,1);
% Pre-synchronize the average VSC with the nominal grid at t=0. Starting a
% weak grid from zero modulation can collapse PCC voltage before the PLL is
% enabled and create a self-sustaining low-voltage lockout.
x0(8:10) = cfg.modulationPolarity*cfg.mBase* ...
    [0; -sqrt(3)/2; sqrt(3)/2];
block.Dwork(1).Data = x0;
end

function outputs(block)
x = block.Dwork(1).Data;
block.OutputPort(1).Data = [x(8:10); x(2); x(11:15); x(4:6)];
end

function update(block)
cfg = block.DialogPrm(1).Data;
x = block.Dwork(1).Data;
u = block.InputPort(1).Data;
[y, coreState] = controllerStep(x, u, cfg);
block.Dwork(1).Data = [coreState; y(1:3); y(5:9)];
end

function [y, nextX] = controllerStep(x, u, cfg)
vabc = u(1:3); iabc = u(4:6); vdc = u(7);
pRef = u(8); qRef = u(9); vdcRef = u(10); soc = u(11);
thetaDrive = x(1); theta = x(2); xiPll = x(3);
xiVdc = x(4); xiId = x(5); xiIq = x(6); faultLatched = x(7);

vab = vabc(1); vbc = vabc(2); vca = vabc(3);
va = (vab-vca)/3; vb = (vbc-vab)/3; vc = (vca-vbc)/3;
ia = iabc(1); ib = iabc(2); ic = iabc(3);
vAlpha = (2/3)*(va-0.5*vb-0.5*vc);
vBeta = (sqrt(3)/3)*(vb-vc);
iAlpha = (2/3)*(ia-0.5*ib-0.5*ic);
iBeta = (sqrt(3)/3)*(ib-ic);
c = cos(theta); s = sin(theta);
vd = vAlpha*c+vBeta*s; vq = -vAlpha*s+vBeta*c;
id = iAlpha*c+iBeta*s; iq = -iAlpha*s+iBeta*c;
vMag = hypot(vAlpha, vBeta);

if vMag < cfg.faultEntry_V
    faultLatched = 1;
elseif vMag > cfg.faultClear_V
    faultLatched = 0;
end

if vMag < cfg.vEnable_V
    omega = cfg.wNom_rad_s;
    theta = mod(theta+omega*cfg.sampleTime_s, 2*pi);
    thetaDrive = mod(thetaDrive+cfg.wNom_rad_s*cfg.sampleTime_s, 2*pi);
    nextX = [thetaDrive; theta; xiPll; xiVdc; xiId; xiIq; faultLatched];
    y = [zeros(3,1); theta; omega; id; iq; 0; 0];
    return
end

ePll = vq/vMag;
xiPll = clamp(xiPll+cfg.pllKi*ePll*cfg.sampleTime_s, ...
    -cfg.pllIntLimit, cfg.pllIntLimit);
omega = clamp(cfg.wNom_rad_s+cfg.pllKp*ePll+xiPll, ...
    cfg.wMin_rad_s, cfg.wMax_rad_s);
theta = mod(theta+omega*cfg.sampleTime_s, 2*pi);
thetaDrive = mod(thetaDrive+cfg.wNom_rad_s*cfg.sampleTime_s, 2*pi);

if vdc > cfg.vdcFloor_V
    eVdc = vdcRef-vdc;
else
    eVdc = 0;
end
pRaw = pRef+cfg.vdcKp_W_per_V*eVdc+xiVdc;
pCmd = clamp(pRaw, -cfg.pLimit_W, cfg.pLimit_W);
if (soc <= cfg.socMin_pu && pCmd > 0) || ...
        (soc >= cfg.socMax_pu && pCmd < 0)
    pCmd = 0;
end
xiVdc = clamp(xiVdc+cfg.vdcKi_W_per_Vs*eVdc*cfg.sampleTime_s+ ...
    cfg.outerAntiWindupGain*(pCmd-pRaw)*cfg.sampleTime_s, ...
    -cfg.pLimit_W, cfg.pLimit_W);

qFault = cfg.qSupportGain_var_per_V*max(0, cfg.qSupportStart_V-vMag);
qCmd = clamp(qRef+qFault, -cfg.qLimit_var, cfg.qLimit_var);
vDSafe = max(abs(vd), cfg.vFloor_V);
idRaw = (2/3)*pCmd/vDSafe;
iqRaw = -(2/3)*qCmd/vDSafe;
if faultLatched
    iqRef = clamp(iqRaw, -cfg.iLimit_A, cfg.iLimit_A);
    idCap = sqrt(max(0, cfg.iLimit_A^2-iqRef^2));
    idRef = clamp(idRaw, -idCap, idCap);
else
    idRef = clamp(idRaw, -cfg.iLimit_A, cfg.iLimit_A);
    iqCap = sqrt(max(0, cfg.iLimit_A^2-idRef^2));
    iqRef = clamp(iqRaw, -iqCap, iqCap);
end

% During a grid fault, changing current priority and voltage saturation can
% pin the dq integrators at their limits. Use proportional-dominant fault
% control and restart integration from zero after clearing the event.
if faultLatched
    xiId = 0;
    xiIq = 0;
end
eId = idRef-id; eIq = iqRef-iq;
xiIdTrial = xiId+cfg.currentKi_V_per_As*eId*cfg.sampleTime_s;
xiIqTrial = xiIq+cfg.currentKi_V_per_As*eIq*cfg.sampleTime_s;
vDRaw = vd+cfg.rEq_Ohm*id-omega*cfg.lEq_H*iq+ ...
    cfg.currentKp_V_per_A*eId+xiIdTrial;
vQRaw = vq+cfg.rEq_Ohm*iq+omega*cfg.lEq_H*id+ ...
    cfg.currentKp_V_per_A*eIq+xiIqTrial;
vScale = min(1, cfg.vCmdLimit_V/max(hypot(vDRaw, vQRaw), eps));
vDCmd = vScale*vDRaw; vQCmd = vScale*vQRaw;
xiId = clamp(xiIdTrial+cfg.currentAntiWindupGain*(vDCmd-vDRaw)*cfg.sampleTime_s, ...
    -cfg.vCmdLimit_V, cfg.vCmdLimit_V);
xiIq = clamp(xiIqTrial+cfg.currentAntiWindupGain*(vQCmd-vQRaw)*cfg.sampleTime_s, ...
    -cfg.vCmdLimit_V, cfg.vCmdLimit_V);

vAlphaCmd = vDCmd*c-vQCmd*s;
vBetaCmd = vDCmd*s+vQCmd*c;
mA = 2*vAlphaCmd/max(vdc, cfg.vdcFloor_V);
mB = 2*(-0.5*vAlphaCmd+sqrt(3)/2*vBetaCmd)/max(vdc, cfg.vdcFloor_V);
mC = 2*(-0.5*vAlphaCmd-sqrt(3)/2*vBetaCmd)/max(vdc, cfg.vdcFloor_V);
mabc = cfg.modulationPolarity*[clamp(mA,-cfg.mLimit,cfg.mLimit); ...
    clamp(mB,-cfg.mLimit,cfg.mLimit); clamp(mC,-cfg.mLimit,cfg.mLimit)];
nextX = [thetaDrive; theta; xiPll; xiVdc; xiId; xiIq; faultLatched];
y = [mabc; theta; omega; id; iq; idRef; iqRef];
end

function y = clamp(x, lower, upper)
y = min(max(x, lower), upper);
end
