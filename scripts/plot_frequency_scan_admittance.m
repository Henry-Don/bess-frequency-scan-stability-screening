function outputFile = plot_frequency_scan_admittance(scanResult, outputFolder)
%PLOT_FREQUENCY_SCAN_ADMITTANCE Plot magnitude and phase of all dq elements.

if ~isfolder(outputFolder)
    mkdir(outputFolder);
end
completed = scanResult.completed;
frequencyHz = scanResult.frequency_Hz(completed);
Y = scanResult.Y_dq_S(:,:,completed);
labels = {'Y_{dd}','Y_{dq}','Y_{qd}','Y_{qq}'};
indices = [1 1; 1 2; 2 1; 2 2];

fig = figure('Visible','off','Color','w','Position',[100 100 1200 900]);
layout = tiledlayout(4,2,'Padding','compact','TileSpacing','compact');
for k = 1:4
    value = squeeze(Y(indices(k,1),indices(k,2),:));
    nexttile;
    loglog(frequencyHz, abs(value), 'o-', 'LineWidth', 1.1, 'MarkerSize', 4);
    grid on; ylabel([labels{k} ' magnitude (S)']);
    nexttile;
    semilogx(frequencyHz, rad2deg(unwrap(angle(value))), ...
        'o-', 'LineWidth', 1.1, 'MarkerSize', 4);
    grid on; ylabel([labels{k} ' phase (deg)']);
end
xlabel(layout, 'Frequency (Hz)');
outputFile = fullfile(outputFolder, 'phase2_dq_admittance.png');
exportgraphics(fig, outputFile, 'Resolution', 180);
close(fig);
end
