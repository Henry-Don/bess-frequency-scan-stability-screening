function outputFile = plot_time_domain_validation(studyResult, outputFolder)
%PLOT_TIME_DOMAIN_VALIDATION Plot the three representative step responses.

if ~isfolder(outputFolder)
    mkdir(outputFolder);
end
cases = studyResult.cases;
colors = lines(numel(cases));
fig = figure('Visible','off','Color','w','Position',[100 100 1550 980]);
tiledlayout(2,3,'Padding','compact','TileSpacing','compact');

allNormalizedPower = [];
for k = 1:numel(cases)
    displayMask = cases(k).signals.time_s >= ...
        studyResult.configuration.step_time_s-0.20;
    allNormalizedPower = [allNormalizedPower; ...
        cases(k).metrics.normalized_active_power(displayMask)]; %#ok<AGROW>
end
sharedLimits = [min(allNormalizedPower) max(allNormalizedPower)];
padding = max(0.1, 0.04*diff(sharedLimits));
sharedLimits = sharedLimits+[-padding padding];
for k = 1:numel(cases)
    nexttile;
    relativeTime = cases(k).signals.time_s-studyResult.configuration.step_time_s;
    plot(relativeTime, cases(k).metrics.normalized_active_power, ...
        'LineWidth',0.85,'Color',colors(k,:));
    hold on;
    yline(1,'--','Command');
    xline(0,':','Step');
    xlim([-0.20 studyResult.configuration.stop_time_s- ...
        studyResult.configuration.step_time_s]);
    ylim(sharedLimits);
    grid on;
    xlabel('Time after step (s)');
    if k == 1
        ylabel('Normalized active-power response');
    end
    title(caseLegend(cases(k)));
end

labels = string({cases.label});
positions = 1:numel(cases);
overshoot = arrayfun(@(item)item.metrics.overshoot_percent, cases);
settling = arrayfun(@(item)item.metrics.settling_time_s, cases);
dominantFrequency = arrayfun( ...
    @(item)item.metrics.dominant_oscillation_frequency_Hz, cases);
decayRatio = arrayfun( ...
    @(item)item.metrics.oscillation_decay_ratio, cases);
nexttile;
bar(positions, overshoot, 0.65);
configureBarAxes(labels, positions);
ylabel('Overshoot (%)');
title('Active-power overshoot');

nexttile;
bar(positions, settling, 0.65);
configureBarAxes(labels, positions);
ylabel('Settling time (s)');
title('5% settling time');
for k = 1:numel(cases)
    if ~cases(k).metrics.settled_within_window
        text(positions(k), settling(k), 'Unsettled', ...
            'HorizontalAlignment','center','VerticalAlignment','bottom');
    end
end

nexttile;
yyaxis left;
bar(positions-0.18, ...
    dominantFrequency, 0.34);
ylabel('Dominant frequency (Hz)');
yyaxis right;
bar(positions+0.18, decayRatio, 0.34);
yline(1,'--','Non-decaying boundary');
ylabel('Late/early oscillation RMS');
configureBarAxes(labels, positions);
title('Oscillation frequency and decay');

outputFile = fullfile(outputFolder, 'phase5_time_domain_validation.png');
exportgraphics(fig, outputFile, 'Resolution', 180);
close(fig);
end

function configureBarAxes(labels, positions)
xticks(positions);
xticklabels(labels);
grid on;
end

function value = caseLegend(item)
value = sprintf('%s | SCR %g, PLL %.3g | %s', item.label, ...
    item.scr, item.pll_scale, item.frequency_risk_level);
end
