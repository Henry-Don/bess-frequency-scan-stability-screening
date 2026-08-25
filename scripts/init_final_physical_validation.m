% INIT_FINAL_PHYSICAL_VALIDATION Parameters for the 30-case physical model.

init_final_coupled;

% Every command source is parameterized so SimulationInput can run a case
% without changing the saved model. Defaults reproduce the nominal model.
case_step_time_s = 0.10;
P_ref_initial_W = 0;
P_ref_final_W = 0;
Q_ref_initial_var = 0;
Q_ref_final_var = 0;
recovery_time_s = 9.0;
P_recovery_W = 0;
Q_recovery_var = 0;
Vdc_ref_initial_V = Vdc_ref_V;
Vdc_ref_final_V = Vdc_ref_V;
command_delay_samples = 0;

% Controller-measurement noise. Variance vectors match the three-phase
% sensor outputs and are zero for the default nominal run.
voltage_noise_variance = [0 0 0];
current_noise_variance = [0 0 0];

% Case-level physical parameter multipliers.
lcl_inductance_scale = 1.0;
lcl_capacitance_scale = 1.0;
battery_resistance_scale = 1.0;
physical_fault_resistance_Ohm = 0.02;
physical_fault_ground_resistance_Ohm = 0.02;

physical_validation_stop_time_s = 0.30;
