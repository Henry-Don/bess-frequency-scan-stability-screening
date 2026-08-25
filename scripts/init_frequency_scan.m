% INIT_FREQUENCY_SCAN Initialize the BESS frequency-scan study.
% Run this script before simulating bess_frequency_scan.slx.

init_final_physical_validation;

frequency_scan_model = 'bess_frequency_scan';

scan_cfg = struct();
scan_cfg.nominal_frequency_Hz = 50;
scan_cfg.nominal_line_voltage_rms_V = V_grid_LL_rms_V;
scan_cfg.nominal_active_power_W = 0.5*ctrl_cfg.pLimit_W;
scan_cfg.nominal_reactive_power_var = 0;
scan_cfg.test_frequency_Hz = 10;
scan_cfg.voltage_perturbation_pu = 0.003;
scan_cfg.enable_time_s = 0.20;
scan_cfg.disable_time_s = 0.50;
scan_cfg.stop_time_s = 0.60;
scan_cfg.pcc_source_block = [frequency_scan_model '/Grid_11kV'];

% A d-axis test uses a line-voltage magnitude modulation.  A q-axis test
% uses an equivalent small phase modulation.  Both are intentionally small
% enough to stay well inside normal voltage and current limits.
scan_cfg.d_axis_amplitude_V = scan_cfg.voltage_perturbation_pu * ...
    scan_cfg.nominal_line_voltage_rms_V;
scan_cfg.q_axis_phase_amplitude_deg = rad2deg(scan_cfg.voltage_perturbation_pu);
