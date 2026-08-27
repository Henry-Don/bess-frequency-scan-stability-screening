function grid = compute_grid_dq_impedance(frequencyHz, scr, configuration)
%COMPUTE_GRID_DQ_IMPEDANCE Build the synchronous-frame Thevenin impedance.

validateattributes(frequencyHz, {'numeric'}, ...
    {'real','finite','positive','vector'}, mfilename, 'frequencyHz');
validateattributes(scr, {'numeric'}, ...
    {'real','finite','positive','scalar'}, mfilename, 'scr');
required = {'nominal_line_voltage_rms_V','nominal_frequency_Hz', ...
    'converter_base_power_VA','grid_xr_ratio'};
for k = 1:numel(required)
    if ~isfield(configuration, required{k})
        error('InteractionMetric:MissingConfiguration', ...
            'Configuration field %s is required.', required{k});
    end
end

frequencyHz = frequencyHz(:).';
baseImpedanceOhm = configuration.nominal_line_voltage_rms_V^2 / ...
    configuration.converter_base_power_VA;
impedanceMagnitudeOhm = baseImpedanceOhm/scr;
xr = configuration.grid_xr_ratio;
resistanceOhm = impedanceMagnitudeOhm/sqrt(1+xr^2);
reactanceOhm = xr*resistanceOhm;
nominalOmega = 2*pi*configuration.nominal_frequency_Hz;
inductanceH = reactanceOhm/nominalOmega;

n = numel(frequencyHz);
Zdq = complex(zeros(2,2,n));
for k = 1:n
    s = 1i*2*pi*frequencyHz(k);
    diagonal = resistanceOhm + s*inductanceH;
    Zdq(:,:,k) = [diagonal, -nominalOmega*inductanceH; ...
        nominalOmega*inductanceH, diagonal];
end

grid = struct();
grid.frequency_Hz = frequencyHz;
grid.scr = scr;
grid.base_impedance_Ohm = baseImpedanceOhm;
grid.short_circuit_power_VA = ...
    scr*configuration.converter_base_power_VA;
grid.resistance_Ohm = resistanceOhm;
grid.inductance_H = inductanceH;
grid.reactance_at_nominal_frequency_Ohm = reactanceOhm;
grid.Z_dq_Ohm = Zdq;
end
