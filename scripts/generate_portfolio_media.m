% GENERATE_PORTFOLIO_MEDIA Export the model view and create demo media.
% The script does not save or modify the Simulink model. Image Processing
% Toolbox and Computer Vision Toolbox are used only for presentation assets.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
imageDir = fullfile(projectRoot, 'docs', 'images');
mediaDir = fullfile(projectRoot, 'docs', 'media');
temporaryDir = fullfile(tempdir, 'bess_frequency_scan_portfolio_media');

if ~isfolder(imageDir), mkdir(imageDir); end
if ~isfolder(mediaDir), mkdir(mediaDir); end
if ~isfolder(temporaryDir), mkdir(temporaryDir); end

modelRaw = exportModel(projectRoot, temporaryDir, 'bess_frequency_scan');
modelImage = frequencyScanModelCard(modelRaw);
imwrite(modelImage, fullfile(imageDir, 'model_frequency_scan.png'));

singleFrequency = imread(fullfile(imageDir, 'single_frequency_response.png'));
dqAdmittance = imread(fullfile(imageDir, 'dq_admittance_response.png'));
scrInteraction = imread(fullfile(imageDir, 'scr_interaction_screening.png'));
pllRiskMap = imread(fullfile(imageDir, 'pll_scr_risk_map.png'));
timeDomain = imread(fullfile(imageDir, 'time_domain_validation.png'));

slides = {
    titleSlide(modelRaw, pllRiskMap)
    modelImage
    imageSlide(singleFrequency, ...
        'Single-Frequency dq Identification', ...
        '10 Hz perturbation · baseline, d-axis and q-axis runs · fitted complex tone')
    imageSlide(dqAdmittance, ...
        'Complete 2 × 2 dq Admittance', ...
        'Ydd · Ydq · Yqd · Yqq across the 0.5–100 Hz scan')
    imageSlide(scrInteraction, ...
        'Grid-Strength Interaction Screening', ...
        'SCR 10 / 5 / 3 / 2 · interaction metric and critical-frequency extraction')
    imageSlide(pllRiskMap, ...
        'PLL–SCR Relative-Risk Map', ...
        'Four grid strengths · four PLL gain scales · 640 represented injections')
    imageSlide(timeDomain, ...
        'Time-Domain Cross-Check', ...
        'Three representative operating points · calculated outcomes retained')
    summarySlide()
    };

imwrite(slides{1}, fullfile(mediaDir, 'bess_demo_poster.png'));
writeMp4(slides, fullfile(mediaDir, 'bess_demo.mp4'));
writeGif(slides, fullfile(mediaDir, 'bess_demo.gif'));

fprintf('Portfolio media written to %s and %s.\n', imageDir, mediaDir);

function image = exportModel(projectRoot, temporaryDir, modelName)
modelFile = fullfile(projectRoot, 'models', [modelName '.slx']);
rawFile = fullfile(temporaryDir, [modelName '_raw.png']);
load_system(modelFile);
cleanup = onCleanup(@() close_system(modelName, 0));
print(['-s' modelName], rawFile, '-dpng', '-r180');
image = cropWhite(imread(rawFile), 30);
clear cleanup
end

function output = cropWhite(input, padding)
gray = min(input, [], 3);
mask = gray < 247;
rows = find(any(mask, 2));
cols = find(any(mask, 1));
if isempty(rows) || isempty(cols)
    output = input;
    return
end
y1 = max(1, rows(1) - padding);
y2 = min(size(input, 1), rows(end) + padding);
x1 = max(1, cols(1) - padding);
x2 = min(size(input, 2), cols(end) + padding);
output = input(y1:y2, x1:x2, :);
end

function canvas = baseCanvas()
height = 1080;
width = 1920;
canvas = zeros(height, width, 3, 'uint8');
top = uint8([15 36 58]);
bottom = uint8([235 242 248]);
for row = 1:height
    weight = (row - 1) / (height - 1);
    color = uint8((1 - weight) * double(top) + weight * double(bottom));
    canvas(row, :, 1) = color(1);
    canvas(row, :, 2) = color(2);
    canvas(row, :, 3) = color(3);
end
end

function canvas = addHeader(canvas, titleText, subtitleText)
canvas = insertShape(canvas, 'FilledRectangle', [0 0 1920 126], ...
    'Color', [14 35 57], 'Opacity', 1);
canvas = insertText(canvas, [54 24], titleText, ...
    'Font', 'Segoe UI', 'FontSize', 34, 'TextColor', 'white', ...
    'BoxOpacity', 0, 'AnchorPoint', 'LeftTop');
canvas = insertText(canvas, [56 78], subtitleText, ...
    'Font', 'Segoe UI', 'FontSize', 19, 'TextColor', [181 214 235], ...
    'BoxOpacity', 0, 'AnchorPoint', 'LeftTop');
canvas = insertShape(canvas, 'FilledRectangle', [0 122 1920 4], ...
    'Color', [24 164 116], 'Opacity', 1);
end

function canvas = placeImage(canvas, image, rectangle, background)
x = rectangle(1); y = rectangle(2); w = rectangle(3); h = rectangle(4);
canvas = insertShape(canvas, 'FilledRectangle', rectangle, ...
    'Color', background, 'Opacity', 1);
scale = min((w - 24) / size(image, 2), (h - 24) / size(image, 1));
resized = imresize(image, scale, 'bicubic');
left = x + floor((w - size(resized, 2)) / 2);
top = y + floor((h - size(resized, 1)) / 2);
rows = top:(top + size(resized, 1) - 1);
cols = left:(left + size(resized, 2) - 1);
canvas(rows, cols, :) = resized;
end

function canvas = frequencyScanModelCard(modelImage)
canvas = baseCanvas();
canvas = addHeader(canvas, ...
    'BESS Frequency-Scan Simulink Model', ...
    'Validated BESS plant · terminal dq perturbation · PLL and SCR parameterization');
canvas = placeImage(canvas, modelImage, [36 148 1848 340], [255 255 255]);

leftDetail = normalizedCrop(modelImage, [0.00 0.02 0.50 0.94]);
rightDetail = normalizedCrop(modelImage, [0.39 0.02 0.61 0.94]);
canvas = placeImage(canvas, leftDetail, [36 525 900 495], [255 255 255]);
canvas = placeImage(canvas, rightDetail, [984 525 900 495], [255 255 255]);
canvas = insertText(canvas, [58 541], 'GRID, PCC AND PERTURBATION', ...
    'Font', 'Segoe UI', 'FontSize', 17, 'TextColor', 'white', ...
    'BoxColor', [34 88 145], 'BoxOpacity', 0.95);
canvas = insertText(canvas, [1006 541], 'PLL, BESS AND CONTROL', ...
    'Font', 'Segoe UI', 'FontSize', 17, 'TextColor', 'white', ...
    'BoxColor', [31 126 88], 'BoxOpacity', 0.95);
end

function output = normalizedCrop(input, rectangle)
height = size(input, 1);
width = size(input, 2);
x1 = max(1, round(rectangle(1) * width));
y1 = max(1, round(rectangle(2) * height));
x2 = min(width, round((rectangle(1) + rectangle(3)) * width));
y2 = min(height, round((rectangle(2) + rectangle(4)) * height));
output = input(y1:y2, x1:x2, :);
end

function canvas = titleSlide(modelImage, riskImage)
canvas = baseCanvas();
canvas = addHeader(canvas, ...
    'Grid-Following BESS Frequency Scan and Stability Screening', ...
    '0.5–100 Hz · complete 2 × 2 dq admittance · 4 SCR × 4 PLL settings');
canvas = placeImage(canvas, modelImage, [55 164 1135 800], [255 255 255]);
canvas = placeImage(canvas, riskImage, [1225 164 640 530], [255 255 255]);

labels = {'20 FREQUENCY POINTS', '4 × 4 OPERATING MATRIX', ...
    '640 INJECTION RUNS', '7 / 7 CHECK GROUPS'};
positions = [1225 735; 1555 735; 1225 875; 1555 875];
colors = [35 93 153; 31 126 88; 175 101 24; 104 74 160];
for index = 1:numel(labels)
    canvas = insertShape(canvas, 'FilledRectangle', ...
        [positions(index, :) 310 110], 'Color', colors(index, :), ...
        'Opacity', 0.93);
    canvas = insertText(canvas, positions(index, :) + [155 55], labels{index}, ...
        'Font', 'Segoe UI', 'FontSize', 18, 'TextColor', 'white', ...
        'BoxOpacity', 0, 'AnchorPoint', 'Center');
end
end

function canvas = imageSlide(image, titleText, subtitleText)
canvas = baseCanvas();
canvas = addHeader(canvas, titleText, subtitleText);
canvas = placeImage(canvas, image, [55 158 1810 860], [255 255 255]);
end

function canvas = summarySlide()
canvas = baseCanvas();
canvas = addHeader(canvas, ...
    'Reviewable Frequency-Scan Evidence', ...
    'Repeatable perturbation, quality gates and time-domain cross-check');
canvas = insertText(canvas, [960 255], '640', ...
    'Font', 'Segoe UI', 'FontSize', 92, 'TextColor', [21 111 76], ...
    'BoxColor', [232 247 239], 'BoxOpacity', 1, ...
    'AnchorPoint', 'Center');
canvas = insertText(canvas, [960 365], 'INJECTION SIMULATIONS REPRESENTED', ...
    'Font', 'Segoe UI', 'FontSize', 31, 'TextColor', [18 52 78], ...
    'BoxOpacity', 0, 'AnchorPoint', 'Center');

labels = {'20 FREQUENCY POINTS', '4 × 4 SCR–PLL MATRIX', ...
    'COMPLETE 2 × 2 dq ADMITTANCE', '7 / 7 CHECK GROUPS'};
positions = [185 525; 975 525; 185 725; 975 725];
colors = [35 93 153; 31 126 88; 175 101 24; 104 74 160];
for index = 1:numel(labels)
    canvas = insertShape(canvas, 'FilledRectangle', ...
        [positions(index, :) 760 145], 'Color', colors(index, :), ...
        'Opacity', 0.93);
    canvas = insertText(canvas, positions(index, :) + [380 72], labels{index}, ...
        'Font', 'Segoe UI', 'FontSize', 25, 'TextColor', 'white', ...
        'BoxOpacity', 0, 'AnchorPoint', 'Center');
end
canvas = insertText(canvas, [960 970], ...
    'Comparative stability screening for the validated average-value BESS model', ...
    'Font', 'Segoe UI', 'FontSize', 20, 'TextColor', [43 65 82], ...
    'BoxOpacity', 0, 'AnchorPoint', 'Center');
end

function writeMp4(slides, outputFile)
frameRate = 24;
holdSeconds = [2.5 2.8 2.5 2.5 2.5 3.0 3.0 2.5];
transitionSeconds = 0.45;
writer = VideoWriter(outputFile, 'MPEG-4');
writer.FrameRate = frameRate;
writer.Quality = 92;
open(writer);
cleanup = onCleanup(@() close(writer));
for slideIndex = 1:numel(slides)
    for frameIndex = 1:round(holdSeconds(slideIndex) * frameRate)
        writeVideo(writer, slides{slideIndex});
    end
    if slideIndex < numel(slides)
        transitionFrames = round(transitionSeconds * frameRate);
        for frameIndex = 1:transitionFrames
            weight = frameIndex / (transitionFrames + 1);
            frame = uint8((1 - weight) * double(slides{slideIndex}) + ...
                weight * double(slides{slideIndex + 1}));
            writeVideo(writer, frame);
        end
    end
end
clear cleanup
end

function writeGif(slides, outputFile)
frameRate = 6;
holdSeconds = 1.25;
transitionSeconds = 0.34;
isFirst = true;
for slideIndex = 1:numel(slides)
    slide = imresize(slides{slideIndex}, [540 960]);
    for frameIndex = 1:round(holdSeconds * frameRate)
        isFirst = appendGifFrame(slide, outputFile, frameRate, isFirst);
    end
    if slideIndex < numel(slides)
        nextSlide = imresize(slides{slideIndex + 1}, [540 960]);
        transitionFrames = max(2, round(transitionSeconds * frameRate));
        for frameIndex = 1:transitionFrames
            weight = frameIndex / (transitionFrames + 1);
            frame = uint8((1 - weight) * double(slide) + ...
                weight * double(nextSlide));
            isFirst = appendGifFrame(frame, outputFile, frameRate, isFirst);
        end
    end
end
end

function isFirst = appendGifFrame(frame, outputFile, frameRate, isFirst)
[indexed, colorMap] = rgb2ind(frame, 256, 'nodither');
if isFirst
    imwrite(indexed, colorMap, outputFile, 'gif', ...
        'LoopCount', Inf, 'DelayTime', 1 / frameRate);
    isFirst = false;
else
    imwrite(indexed, colorMap, outputFile, 'gif', ...
        'WriteMode', 'append', 'DelayTime', 1 / frameRate);
end
end
