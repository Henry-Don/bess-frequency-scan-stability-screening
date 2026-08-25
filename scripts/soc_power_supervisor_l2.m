function soc_power_supervisor_l2(block)
%SOC_POWER_SUPERVISOR_L2 Level-2 SoC charge/discharge interlock.
% Input is [P_request_W, Q_request_var, SoC_pu]; output is [P_safe_W,Q_safe_var].

setup(block);
end

function setup(block)
block.NumDialogPrms = 1;
block.NumInputPorts = 1;
block.NumOutputPorts = 1;
block.InputPort(1).Dimensions = 3;
block.InputPort(1).DatatypeID = 0;
block.InputPort(1).Complexity = 'Real';
block.InputPort(1).DirectFeedthrough = true;
block.OutputPort(1).Dimensions = 2;
block.OutputPort(1).DatatypeID = 0;
block.OutputPort(1).Complexity = 'Real';
block.SampleTimes = [50e-6 0];
block.SimStateCompliance = 'DefaultSimState';
block.RegBlockMethod('Outputs', @outputs);
end

function outputs(block)
cfg = block.DialogPrm(1).Data;
u = block.InputPort(1).Data;
p = u(1);
q = u(2);
soc = u(3);
if (soc <= cfg.socMin_pu && p > 0) || ...
        (soc >= cfg.socMax_pu && p < 0)
    p = 0;
end
block.OutputPort(1).Data = [p; q];
end
