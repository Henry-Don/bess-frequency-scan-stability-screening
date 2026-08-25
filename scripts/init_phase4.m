% INIT_PHASE4 Parameters for current limiting, anti-windup, and LVRT support.

init_phase3;

% Converter protection limits and PI back-calculation gains.
ctrl_cfg.iLimit_A = 150;
ctrl_cfg.outerAntiWindupGain = 5;
ctrl_cfg.currentAntiWindupGain = 500;

% PCC voltage fault detection and low-voltage reactive-power support.
% The three-phase sensor provides a Clarke-vector magnitude in volts.
fault_entry_voltage_V = 4.5e3;
fault_clear_voltage_V = 5.0e3;
fault_start_time_s = 0.05;
fault_duration_s = 0.10;
fault_test_period_s = 1.0;
fault_command_initial = 0;
fault_command_final = 1;
q_fault_support_var = 150e3;

ctrl_cfg.faultEntry_V = fault_entry_voltage_V;
ctrl_cfg.faultClear_V = fault_clear_voltage_V;
ctrl_cfg.qSupportStart_V = fault_clear_voltage_V;
ctrl_cfg.qSupportGain_var_per_V = q_fault_support_var / ...
    max(fault_clear_voltage_V - fault_entry_voltage_V, 1);
ctrl_cfg.faultModulationScale = 0.75;
