%% Tracking Pedestrians Live
%
% This example shows how to track people using a camera.
% VAR: t*=Threshold, c*=Cost
%
% You can choose between live and file mode and select either your own
% model or pretrained models below.
%
% The pretrained models (1-5) will be automatically transcoded.

function main()
addpath(fullfile(pwd,'matlab'));

% Mode
live  = 0; % 1 for webcam usage, 0 for file usage
model = 'models/IRtrain_NS10.mat'; % 'filename': own model
%model = 1; options: 1: AcfCaltech+Detector 2: AcfInriaDetector 3: AcfKAIST 4: LdcfCaltechDetector 5: LdcfInriaDetector

% User Parameters
load('aScale.mat');   % Table with expected sizes at certain positions from a car dashcam view
resizeRatio    = 1;   % Resize the input image before processing
if live
    vidObj  = webcam();
    frame = snapshot(vidObj);
else
    frame = imread(fullfile(pwd, 'images/img0.jpg'));
    numFrame = 250; % Set start frame
end
startXY        = [50 80]; % (x,y) of the upper left corner of the symmetric RoI
tScale         = inf; % Tolerance of the error in estimating the scale of pedestrians (inf=ignore, normal=0.6)
tGating        = 1;   % When to reject a candidate match between a detection and a track (0.1=static, 1=dynamic)
cGating        = 100; % Value for the cost matrix for enforcing the rejection of a candidate match (large)
cNonAssignment = 1;   % Likelihood of creation of a new track
tNumFrames     = 50;  % Number of frames required to stabilize the confidence of a track
tConfidence    = 100; % Threshold for a detection become a true positive (depends a lot on model!)
tAge           = 8;   % Minimum length required for a track being true positive
tVisibility    = 0.8; % Minimum visibility value for a track being true positive

% Static Init
frameSize      = fliplr(size(frame));
RoI            = [startXY frameSize(2:3)*resizeRatio-2*startXY]; % Rectangle [x, y, w, h] to limit the processing area

trk = struct('id',{},'color',{},'bboxes',{},'scores',{},'kalmanFilter',{},'age',{},'totalVisibleCount',{},'confidence',{},'predPosition',{}); % Empty array
vPlayer = vision.DeployableVideoPlayer(); % Create player
TrackID = 1; % ID of the first track

% Detect and track people
runLoop = true;
while runLoop
    tic;
    if live
        frame = snapshot(vidObj);
    else
        frame = imread(fullfile(pwd, sprintf('images/img%d.jpg', numFrame)));
        numFrame = numFrame+1;
    end
    frame = imresize(frame, resizeRatio, 'Antialiasing',false);
    [centers, bboxes, scores] = detectPeople(aScale, frame, acfSwitch(model), tScale, RoI, resizeRatio);
    trk = predictNewLocationsOfTracks(trk);
    [assigments, unassignedTracks, unassignedDetections] = detectionToTrackAssignment(trk, bboxes, tGating, cGating, cNonAssignment);
    trk = updateAssignedTracks(trk, assigments, centers, bboxes, scores, tNumFrames);
    trk = updateUnassignedTracks(trk, unassignedTracks, tNumFrames);
    trk = deleteLostTracks(trk, tConfidence, tAge, tVisibility);
    trk = createNewTracks(trk, unassignedDetections, centers, bboxes, scores, TrackID); TrackID = TrackID + 1;
    FPS = 1/toc
    displayResults(vPlayer, frame, trk, RoI, tConfidence, tAge);
    runLoop = isOpen(vPlayer);
end
release(vPlayer);