function outputFile = plot_pll_risk_map(studyResult, outputFolder)
%PLOT_PLL_RISK_MAP Plot risk class and critical frequency over the matrix.

if ~isfolder(outputFolder)
    mkdir(outputFolder);
end
fig = figure('Visible','off','Color','w','Position',[100 100 1450 650]);
tiledlayout(1,2,'Padding','compact','TileSpacing','compact');
rowPositions = 1:numel(studyResult.scr_values);
columnPositions = 1:numel(studyResult.pll_scales);

riskAxes = nexttile;
imagesc(riskAxes, columnPositions, rowPositions, studyResult.risk_code);
set(riskAxes,'YDir','normal');
colormap(riskAxes, [0.26 0.68 0.38; 0.96 0.72 0.18; 0.82 0.25 0.22]);
clim(riskAxes,[0.5 3.5]);
riskBar = colorbar(riskAxes);
riskBar.Ticks = [1 2 3];
riskBar.TickLabels = {'Lower','Moderate','Higher'};
configureAxes(riskAxes, studyResult, rowPositions, columnPositions);
title(riskAxes, 'PLL-SCR risk map');
for row = rowPositions
    for column = columnPositions
        text(riskAxes, column, row, sprintf('%.3g\n%s', ...
            studyResult.peak_interaction_gain(row,column), ...
            studyResult.risk_level(row,column)), ...
            'HorizontalAlignment','center','FontWeight','bold', ...
            'Color',textColor(studyResult.risk_code(row,column)));
    end
end

frequencyAxes = nexttile;
imagesc(frequencyAxes, columnPositions, rowPositions, ...
    studyResult.critical_frequency_Hz);
set(frequencyAxes,'YDir','normal');
colormap(frequencyAxes, parula(256));
frequencyBar = colorbar(frequencyAxes);
frequencyBar.Label.String = 'Frequency (Hz)';
configureAxes(frequencyAxes, studyResult, rowPositions, columnPositions);
title(frequencyAxes, 'Critical interaction frequency');
[minimumFrequency, maximumFrequency] = ...
    bounds(studyResult.critical_frequency_Hz,'all');
midpoint = mean([minimumFrequency maximumFrequency]);
for row = rowPositions
    for column = columnPositions
        value = studyResult.critical_frequency_Hz(row,column);
        color = [0 0 0];
        if value < midpoint
            color = [1 1 1];
        end
        text(frequencyAxes, column, row, sprintf('%.4g Hz',value), ...
            'HorizontalAlignment','center','FontWeight','bold','Color',color);
    end
end

outputFile = fullfile(outputFolder, 'phase4_pll_risk_map.png');
exportgraphics(fig, outputFile, 'Resolution', 180);
close(fig);
end

function configureAxes(axesHandle, studyResult, rowPositions, columnPositions)
xticks(axesHandle, columnPositions);
xticklabels(axesHandle, string(studyResult.pll_scales));
yticks(axesHandle, rowPositions);
yticklabels(axesHandle, string(studyResult.scr_values));
xlabel(axesHandle, 'PLL gain scale');
ylabel(axesHandle, 'SCR');
axis(axesHandle, 'tight');
axesHandle.Layer = 'top';
end

function color = textColor(riskCode)
color = [0 0 0];
if riskCode == 3
    color = [1 1 1];
end
end
