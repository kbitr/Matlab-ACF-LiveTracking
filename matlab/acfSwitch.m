%% acfSwitch
% Switches and transcodes the detector model for acfObjectDetector()
%
% INPUT:    channel features model to be used (model)
% OUTPUT:   initialized detector (acfDetector)

function acfDetector = acfSwitch(model)

switch model
    case 1, load('models/pretrained/AcfCaltech+Detector.mat');
    case 2, load('models/pretrained/AcfInriaDetector.mat');
    case 3, load('models/pretrained/AcfKAIST.mat');
    case 4, load('models/pretrained/LdcfCaltechDetector.mat');
    case 5, load('models/pretrained/LdcfInriaDetector.mat');
    case 6, load('models/pretrained/AcfKAIST-RGBDetector.mat');
    case 7, load('models/pretrained/AcfKAIST-RGB-T-TM-THOGDetector.mat');
    otherwise
        load(model);
        return;
end

% Transcode parameters
params.ChannelPadding                 = detector.opts.pPyramid.pad;
params.gradient.FullOrientation       = detector.opts.pPyramid.pChns.pGradMag.full;
params.gradient.NormalizationConstant = detector.opts.pPyramid.pChns.pGradMag.normConst;
params.gradient.NormalizationRadius   = detector.opts.pPyramid.pChns.pGradMag.normRad;
params.hog.FullOrientation            = params.gradient.FullOrientation;
params.hog.Normalize                  = detector.opts.pPyramid.pChns.pGradHist.useHog;
params.hog.NumBins                    = detector.opts.pPyramid.pChns.pGradHist.nOrients;
params.Lambdas                        = detector.opts.pPyramid.lambdas;
params.MaxWeakLearners                = detector.opts.nWeak(end);
params.ModelName                      = detector.opts.name;
params.ModelSize                      = round(detector.opts.modelDs);
params.ModelSizePadded                = detector.opts.modelDsPad;
params.NegativeSamplesFactor          = 10; %static NegativeSamplesFactor?
params.NumApprox                      = detector.opts.pPyramid.nApprox;
params.NumStages                      = numel(detector.opts.nWeak);
params.NumUpscaledOctaves             = detector.opts.pPyramid.nOctUp;
params.PreSmoothColor                 = detector.opts.pPyramid.pChns.pColor.smooth;
params.Shrink                         = detector.opts.pPyramid.pChns.shrink;
params.SmoothChannels                 = detector.opts.pPyramid.smooth;

if isempty(detector.opts.pPyramid.pChns.pGradHist.binSize)
params.hog.CellSize                   = params.Shrink;
else, params.hog.CellSize             = detector.opts.pPyramid.pChns.pGradHist.binSize;
end
switch detector.opts.pPyramid.pChns.pGradHist.softBin
    case 0, params.hog.Interpolation  = 'Orientation'; % only interpolate orientation
    case 1, params.hog.Interpolation  = 'Both'; % spatial and orientation interpolation
end

acfDetector = acfObjectDetector(rmfield(detector.clf, {'errs', 'losses'}), params);