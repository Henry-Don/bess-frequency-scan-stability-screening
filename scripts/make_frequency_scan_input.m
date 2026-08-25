function in = make_frequency_scan_input(axisName, frequencyHz, enabled)
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

if ~evalin('base', 'exist(''scan_cfg'', ''var'')')
    error('FrequencyScan:NotInitialized', ...
        'Run init_frequency_scan.m before creating a simulation input.');
end
scanCfg = evalin('base', 'scan_cfg');
modelName = evalin('base', 'frequency_scan_model');

in = Simulink.SimulationInput(modelName);
in = in.setModelParameter('StopTime', num2str(scanCfg.stop_time_s, '%.12g'));
in = in.setVariable('P_ref_initial_W', scanCfg.nominal_active_power_W);
in = in.setVariable('P_ref_final_W', scanCfg.nominal_active_power_W);
in = in.setVariable('Q_ref_initial_var', scanCfg.nominal_reactive_power_var);
in = in.setVariable('Q_ref_final_var', scanCfg.nominal_reactive_power_var);
in = in.setVariable('case_step_time_s', scanCfg.enable_time_s);

sourceBlock = scanCfg.pcc_source_block;
if ~enabled || strcmp(axisName, 'off')
    return
end

in = in.setBlockParameter(sourceBlock, ...
    'magnitude_type', 'ee.enum.timechanging.constant');
in = in.setBlockParameter(sourceBlock, ...
    'phase_type', 'ee.enum.timechanging.constant');

switch axisName
    case 'd'
        in = in.setBlockParameter(sourceBlock, ...
            'magnitude_type', 'ee.enum.timechanging.modulation');
        in = in.setBlockParameter(sourceBlock, ...
            'magn_modu_magn', num2str(scanCfg.d_axis_amplitude_V, '%.12g'));
        in = in.setBlockParameter(sourceBlock, ...
            'magn_modu_freq', num2str(frequencyHz, '%.12g'));
        in = in.setBlockParameter(sourceBlock, ...
            'magn_t1', num2str(scanCfg.enable_time_s, '%.12g'));
        in = in.setBlockParameter(sourceBlock, ...
            'magn_t2', num2str(scanCfg.disable_time_s, '%.12g'));
    case 'q'
        in = in.setBlockParameter(sourceBlock, ...
            'phase_type', 'ee.enum.timechanging.modulation');
        in = in.setBlockParameter(sourceBlock, ...
            'phase_modu_magn', num2str(scanCfg.q_axis_phase_amplitude_deg, '%.12g'));
        in = in.setBlockParameter(sourceBlock, ...
            'phase_modu_freq', num2str(frequencyHz, '%.12g'));
        in = in.setBlockParameter(sourceBlock, ...
            'phase_t1', num2str(scanCfg.enable_time_s, '%.12g'));
        in = in.setBlockParameter(sourceBlock, ...
            'phase_t2', num2str(scanCfg.disable_time_s, '%.12g'));
end
end
