function train()

% Train
load('models/TrainTable.mat');
acfDetector = trainACFObjectDetector(IRTable,'NumStages',2, 'NegativeSamplesFactor',1);
save('models/new.mat',acfDetector);

%% Video
obj.videoPlayer = vision.DeployableVideoPlayer();
i = 200; % Start frame

%% Detector Loop
runLoop = true; 
while runLoop
    frame = imread(fullfile(pwd, sprintf('images/img%d.jpg', i)));
    [bboxes, scores] = detect(acfDetector, frame, 'SelectStrongest',true);
    for j = 1:length(scores)
        if scores(j) > 180
            annotation = sprintf('Confidence = %.1f', scores(j));
            frame = insertObjectAnnotation(frame, 'rectangle', bboxes(j,:), annotation);
        end
    end
    step(obj.videoPlayer, frame);
    runLoop = isOpen(obj.videoPlayer);
    i = i+1;
end
release(obj.videoPlayer);
