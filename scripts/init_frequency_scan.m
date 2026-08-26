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
scan_cfg.frequencies_Hz = logspace(log10(0.5), log10(100), 20);
scan_cfg.voltage_perturbation_pu = 0.003;
scan_cfg.pre_injection_s = 0.30;
scan_cfg.minimum_injection_s = 0.30;
scan_cfg.injection_cycles = 4;
scan_cfg.discard_cycles = 1;
scan_cfg.post_injection_s = 0.05;
scan_cfg.maximum_voltage_matrix_condition = 1e4;
scan_cfg.pcc_source_block = [frequency_scan_model '/Grid_11kV'];

% A d-axis test uses a line-voltage magnitude modulation.  A q-axis test
% uses an equivalent small phase modulation.  Both are intentionally small
% enough to stay well inside normal voltage and current limits.
scan_cfg.d_axis_amplitude_V = scan_cfg.voltage_perturbation_pu * ...
    scan_cfg.nominal_line_voltage_rms_V;
scan_cfg.q_axis_phase_amplitude_deg = rad2deg(scan_cfg.voltage_perturbation_pu);
