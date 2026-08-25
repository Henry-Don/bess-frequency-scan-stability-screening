% INIT_PHASE1 Central parameters for the stage-one grid-connected plant.
% Run this script before opening or simulating bess_phase1_grid_base.slx.

P_rated_W = 1e6;
V_grid_LL_rms_V = 11e3;
f_grid_Hz = 50;
w_grid_rad_s = 2*pi*f_grid_Hz;

% A temporary DC source makes the AC power stage testable before phase three.
Vdc_test_V = 20e3;

% Grid Thevenin equivalent at the 11 kV point of common coupling.
R_grid_Ohm = 0.05;
L_grid_H = 1e-3;
S_sc_grid_VA = 50e6;
X_R_grid = 15;

% LCL filter values for the initial average-value VSC model.
L1_H = 2.0e-3;
R1_Ohm = 0.10;
Cf_F = 10e-6;
Rd_Ohm = 2.0;
L2_H = 1.0e-3;
R2_Ohm = 0.05;

% Fixed open-loop modulation is a temporary phase-one excitation.
modulation_index = 0.85;
simulation_stop_time_s = 0.20;
