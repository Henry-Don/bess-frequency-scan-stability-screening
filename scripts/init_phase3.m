% INIT_PHASE3 Parameters for the battery, bidirectional DC/DC, and SoC layer.
% Run this script before simulating bess_phase3_battery_dcdc.slx.

init_phase2;

% Aggregate high-voltage battery equivalent-circuit model (one RC branch).
% The block represents the complete series battery pack rather than one cell.
battery_capacity_Ah = 100;
battery_initial_soc_pu = 0.60;
battery_initial_charge_Ah = battery_capacity_Ah * battery_initial_soc_pu;
% The Battery ECM library block internally uses a millivolt-scale voltage
% parameterization. This scale maps the 20 kV converter DC link to that model.
battery_parameter_voltage_scale = 1e3;
battery_nominal_voltage_V = battery_parameter_voltage_scale * Vdc_test_V;
% V1 is the open-circuit voltage at AH1 (half capacity), below Vnom.
battery_voltage_at_half_charge_V = 0.95 * battery_nominal_voltage_V;
battery_series_resistance_Ohm = 0.50;
battery_rc_resistance_Ohm = 0.30;
battery_rc_time_constant_s = 5.0;

% Complementary PWM gates for the nonisolated bidirectional DC/DC interface.
% Change dcdc_duty_percent above or below 50 to select boost or buck power flow.
dcdc_switch_frequency_Hz = 2e3;
dcdc_switch_period_s = 1 / dcdc_switch_frequency_Hz;
dcdc_gate_sample_time_s = 1e-5;
dcdc_duty_percent = 50;
dcdc_duty_on_time_s = dcdc_duty_percent / 100 * dcdc_switch_period_s;
dcdc_inductance_H = 5e-3;
dcdc_r1_Ohm = 0.05;
dcdc_r2_Ohm = 0.05;
dclink_capacitance_F = 10e-3;

% Coulomb-counting output conventions.
soc_min_pu = 0;
soc_max_pu = 1;
