function dcdc_average_control_l2(block)
%DCDC_AVERAGE_CONTROL_L2 Level-2 average bidirectional DC/DC controller.
% Input is [Vdc_V, P_ref_W, Vdc_ref_V, SoC_pu]. The output current uses
% the Simscape source tail-to-head sign convention.

setup(block);
end

function setup(block)
block.NumDialogPrms = 1;
block.NumInputPorts = 1;
block.NumOutputPorts = 1;
block.InputPort(1).Dimensions = 4;
block.InputPort(1).DatatypeID = 0;
block.InputPort(1).Complexity = 'Real';
block.InputPort(1).DirectFeedthrough = false;
block.OutputPort(1).Dimensions = 1;
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
block.Dwork(1).Name = 'xiCurrent_A';
block.Dwork(1).Dimensions = 1;
block.Dwork(1).DatatypeID = 0;
block.Dwork(1).Complexity = 'Real';
block.Dwork(1).UsedAsDiscState = true;
end

function initializeConditions(block)
block.Dwork(1).Data = 0;
end

function outputs(block)
block.OutputPort(1).Data = block.Dwork(1).Data;
end

function update(block)
cfg = block.DialogPrm(1).Data;
u = block.InputPort(1).Data;
vdc = u(1);
pRef = u(2);
vdcRef = u(3);
soc = u(4);
feedforward = -pRef / max(abs(vdc), cfg.vdcFloor_V);
eVdc = vdcRef - vdc;
raw = feedforward - cfg.kp_A_per_V*eVdc + block.Dwork(1).Data;
current = clamp(raw, -cfg.currentLimit_A, cfg.currentLimit_A);
if (soc <= cfg.socMin_pu && current < 0) || ...
        (soc >= cfg.socMax_pu && current > 0)
    current = 0;
end
block.Dwork(1).Data = clamp(block.Dwork(1).Data + ...
    cfg.sampleTime_s*(-cfg.ki_A_per_Vs*eVdc + cfg.awGain*(current-raw)), ...
    -cfg.currentLimit_A, cfg.currentLimit_A);
end

function y = clamp(x, lower, upper)
y = min(max(x, lower), upper);
end
