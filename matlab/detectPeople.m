%% Detect People
% Adapted from PedestrianTrackingFromMovingCameraExample, 2014 The MathWorks, Inc.

function [centroids, bboxes, scores] = detectPeople(aScale, frame, acfDetector, scThresh, ROI, resizeRatio)

% Run ACF people detector within a region of interest to produce detection candidates.
[bboxes, scores] = detect(acfDetector, frame, ROI,... %Set the detector acfSwitch(model)
    'WindowStride', 2,...
    'NumScaleLevels', 4, ...
    'SelectStrongest', false);

% Look up the estimated height of a pedestrian based on location of their feet.
height = bboxes(:, 4) / resizeRatio;
y = (bboxes(:,2)-1) / resizeRatio + 1;
yfoot = min(length(aScale), round(y + height));
estHeight = aScale(yfoot);

% Remove detections whose size deviates from the expected size,
% provided by the calibrated scale estimation.
invalid = abs(estHeight-height)>estHeight*scThresh;
bboxes(invalid, :) = [];
scores(invalid, :) = [];

% Apply non-maximum suppression to select the strongest bounding boxes.
[bboxes, scores] = selectStrongestBbox(bboxes, scores, ...
    'RatioType', 'Min', 'OverlapThreshold', 0.6);

% Compute the centroids
if isempty(bboxes)
    centroids = [];
else
    centroids = [(bboxes(:, 1) + bboxes(:, 3) / 2), ...
        (bboxes(:, 2) + bboxes(:, 4) / 2)];
end