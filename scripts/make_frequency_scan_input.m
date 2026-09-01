function in = make_frequency_scan_input(axisName, frequencyHz, enabled, scanCfg, modelName)
%MAKE_FREQUENCY_SCAN_INPUT Build one non-destructive scan simulation input.
% AXISNAME is 'd', 'q', or 'off'.  The returned SimulationInput changes
% only run-time settings and never overwrites the saved model.

if nargin < 3
    enabled = true;
end

if ~ischar(axisName) && ~isstring(axisName)
    error('FrequencyScan:AxisType', 'axisName must be d, q, or off.');
end
axisName = lower(char(axisName));
if ~ismember(axisName, {'d','q','off'})
    error('FrequencyScan:AxisValue', 'axisName must be d, q, or off.');
end
if ~isscalar(frequencyHz) || ~isfinite(frequencyHz) || frequencyHz <= 0
    error('FrequencyScan:Frequency', 'frequencyHz must be a positive scalar.');
end

if nargin < 4 || isempty(scanCfg)
    if ~evalin('base', 'exist(''scan_cfg'', ''var'')')
        error('FrequencyScan:NotInitialized', ...
            'Run init_frequency_scan.m before creating a simulation input.');
    end
    scanCfg = evalin('base', 'scan_cfg');
end
if nargin < 5 || isempty(modelName)
    modelName = evalin('base', 'frequency_scan_model');
end

timing = frequency_scan_timing(scanCfg, frequencyHz);

in = Simulink.SimulationInput(modelName);
in = in.setModelParameter('StopTime', num2str(timing.stop_time_s, '%.12g'));
in = in.setVariable('P_ref_initial_W', scanCfg.nominal_active_power_W);
in = in.setVariable('P_ref_final_W', scanCfg.nominal_active_power_W);
in = in.setVariable('Q_ref_initial_var', scanCfg.nominal_reactive_power_var);
in = in.setVariable('Q_ref_final_var', scanCfg.nominal_reactive_power_var);
in = in.setVariable('case_step_time_s', timing.enable_time_s);
if isfield(scanCfg, 'grid_short_circuit_power_VA')
    in = in.setVariable('S_sc_grid_VA', scanCfg.grid_short_circuit_power_VA);
end
if isfield(scanCfg, 'grid_xr_ratio')
    in = in.setVariable('X_R_grid', scanCfg.grid_xr_ratio);
end
if isfield(scanCfg, 'controller_configuration')
    in = in.setVariable('ctrl_cfg', scanCfg.controller_configuration);
end

sourceBlock = scanCfg.pcc_source_block;
in = in.setBlockParameter(sourceBlock, ...
    'magnitude_type', 'ee.enum.timechanging.constant');
in = in.setBlockParameter(sourceBlock, ...
    'phase_type', 'ee.enum.timechanging.constant');
if ~enabled || strcmp(axisName, 'off')
    return
end

switch axisName
    case 'd'
        in = in.setBlockParameter(sourceBlock, ...
            'magnitude_type', 'ee.enum.timechanging.modulation');
        in = in.setBlockParameter(sourceBlock, ...
            'magn_modu_magn', num2str(scanCfg.d_axis_amplitude_V, '%.12g'));
        in = in.setBlockParameter(sourceBlock, ...
            'magn_modu_freq', num2str(frequencyHz, '%.12g'));
        in = in.setBlockParameter(sourceBlock, ...
            'magn_t1', num2str(timing.enable_time_s, '%.12g'));
        in = in.setBlockParameter(sourceBlock, ...
            'magn_t2', num2str(timing.disable_time_s, '%.12g'));
    case 'q'
        in = in.setBlockParameter(sourceBlock, ...
            'phase_type', 'ee.enum.timechanging.modulation');
        in = in.setBlockParameter(sourceBlock, ...
            'phase_modu_magn', num2str(scanCfg.q_axis_phase_amplitude_deg, '%.12g'));
        in = in.setBlockParameter(sourceBlock, ...
            'phase_modu_freq', num2str(frequencyHz, '%.12g'));
        in = in.setBlockParameter(sourceBlock, ...
            'phase_t1', num2str(timing.enable_time_s, '%.12g'));
        in = in.setBlockParameter(sourceBlock, ...
            'phase_t2', num2str(timing.disable_time_s, '%.12g'));
end
end
