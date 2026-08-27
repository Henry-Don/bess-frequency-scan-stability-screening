function outputFile = plot_scr_interaction_metric(studyResult, outputFolder)
%PLOT_SCR_INTERACTION_METRIC Plot comparable interaction scores by SCR.

if ~isfolder(outputFolder)
    mkdir(outputFolder);
end
fig = figure('Visible','off','Color','w','Position',[100 100 1150 760]);
tiledlayout(2,1,'Padding','compact','TileSpacing','compact');

topAxes = nexttile;
hold on;
for k = 1:numel(studyResult.cases)
    item = studyResult.cases(k);
    semilogx(item.metric.frequency_Hz, item.metric.interaction_gain, ...
        'o-', 'LineWidth', 1.25, 'MarkerSize', 4, ...
        'DisplayName', sprintf('SCR = %g', item.scr));
end
yline(studyResult.thresholds.moderate, '--', 'Moderate threshold', ...
    'HandleVisibility','off','LabelHorizontalAlignment','right');
yline(studyResult.thresholds.higher, '--', 'Higher threshold', ...
    'HandleVisibility','off','LabelHorizontalAlignment','right');
set(topAxes, 'XScale', 'log');
xlim([min(studyResult.frequency_Hz), max(studyResult.frequency_Hz)]);
grid on;
xlabel('Frequency (Hz)');
ylabel('Interaction gain');
legend('Location','best');
title('Converter-grid interaction screening');

nexttile;
scr = [studyResult.cases.scr];
peak = arrayfun(@(x) x.metric.peak_interaction_gain, studyResult.cases);
positions = 1:numel(scr);
bar(positions, peak, 0.6);
xticks(positions);
xticklabels(string(scr));
grid on;
xlabel('SCR');
ylabel('Peak interaction gain');
title('Worst-case score for each grid strength');

outputFile = fullfile(outputFolder, 'phase3_scr_interaction.png');
exportgraphics(fig, outputFile, 'Resolution', 180);
close(fig);
end
