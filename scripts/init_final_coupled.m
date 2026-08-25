% INIT_FINAL_COUPLED Parameters for the physically connected BESS final model.
% The DC/DC stage is an average controlled-current representation: it shares
% the actual Battery, DC-link capacitor and VSC electrical network and avoids
% a fixed PWM gate pattern in the final verification model.

init_phase4;

% A 20 kV, 100 Ah pack stores 2 MWh nominally.  The battery ECM parameters
% are specified directly in volts; no artificial millivolt scaling is used.
battery_capacity_Ah = 100;
battery_initial_soc_pu = 0.60;
battery_initial_charge_Ah = battery_capacity_Ah*battery_initial_soc_pu;
battery_nominal_voltage_V = Vdc_test_V;
battery_voltage_at_half_charge_V = 0.95*Vdc_test_V;
battery_series_resistance_Ohm = 0.50;
battery_rc_resistance_Ohm = 0.30;
battery_rc_time_constant_s = 5.0;
dclink_capacitance_F = 10e-3;

% Both the GFL controller and the physical average DC/DC controller use
% these same operator set-points and DC-link target.
P_ref_W = 0;
Q_ref_var = 0;
Vdc_ref_V = Vdc_test_V;
% The protection boundary is deliberately tighter than the physical 0--1
% estimator range, so the supervisor can block a damaging direction before
% the cell model reaches either mathematical endpoint.
soc_min_pu = 0.10;
soc_max_pu = 0.90;
ctrl_cfg.socMin_pu = soc_min_pu;
ctrl_cfg.socMax_pu = soc_max_pu;

% Explicit dialog-parameter structures for the Level-2 S-functions. Keeping
% every limit in named data makes SimulationInput overrides reproducible.
dcdc_cfg = struct('sampleTime_s',ctrl_sample_time_s,'vdcFloor_V',1000, ...
    'currentLimit_A',80,'kp_A_per_V',0.02,'ki_A_per_Vs',2.0, ...
    'awGain',50,'socMin_pu',soc_min_pu,'socMax_pu',soc_max_pu);
soc_supervisor_cfg = struct('sampleTime_s',ctrl_sample_time_s, ...
    'socMin_pu',soc_min_pu,'socMax_pu',soc_max_pu);
