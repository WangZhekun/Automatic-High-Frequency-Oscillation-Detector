% This is a walkthrough for the package
% Automatic-High-Frequency-Oscillation-Detector

%% Close all figures, clear variables and command window
close all
clear
clc

%% Add the package to path
strPaths.HFODetector = pwd % 当前目录
addpath(genpath(strPaths.HFODetector)) % 将当前目录添加到搜索路径

%% Basic data-structure of this code is the hfo-object which is used as follows:
% Create an hfo-object by calling the following:
% 创建类HFO的对象
hfo = Core.HFO;

%% The data and parameters can be loaded from 
%% Specify the paths for .mat files for the parameters and date (see README for format of these files)
%% Parameters
% 参数文件路径 ./+Demo/Spec/ECoG/Parameters/RSpecPara.mat
hfo.ParaFileLocation = [strPaths.HFODetector, filesep, '+Demo', filesep,'Spec', filesep,'ECoG', filesep,'Parameters', filesep,'RSpecPara.mat'];
% see the contents of the folder "PresetParameterCreator" for the format.
% 数据文件路径 ./+Demo/Spec/ECoG/Data/Data.mat
hfo.DataFileLocation = [strPaths.HFODetector, filesep, '+Demo', filesep,'Spec', filesep,'ECoG', filesep,'Data', filesep,'Data.mat'];
% Data must be called "data" and must contain the following fields
% 数据必须交“data”变量，包含如下属性
% data.Datasetup
% data.x_bip 
% data.lab_bip
% data.fs
%% Load the parameters and data, this extracts relavant information from the
% above mentioned files to the hfo-object.
chanContains    = '';
hfo = getParaAndData(hfo, chanContains);%, data); % 获取参数和数据
% data: optional imput to overide the file path, useful for running from
% work space. Must be in correct format.
%% This step produces filtered signal based on specification given in the
% parameters file. The envelope of the filtered signal is also computed.
smoothBool = false;
hfo = getFilteredSignal(hfo, smoothBool); % 对数据进行滤波，并计算包络线
% smoothBool: boolean value specifying if the envelope is to be smoothed.
%% Events are described in contradiction to the background which is
% defind by the baseline. This code computes the baseline using entropy.
hfo = getBaselineSTD(hfo); 
%% Events are detected by various means
RefType   = 'spec';
CondMulti = true;
hfo = getEventsOfInterest(hfo, RefType);
% RefType: is a string value, either 'morph', 'spec', 'specECoG' and 'specScalp'
%% Visualize the HFO by calling
% SigString = 'filt';
% chanInd = [1,2,3];
% Visualizations.VisualizeHFO(hfo, SigString, chanInd)
Modality          = 'iEEG';
ChanNames         = hfo.Data.channelNames;
VParams           = Visual.getVParams(Modality, ChanNames);
% SigString = 'raw';
Visual.ValidateHFO(hfo,hfo,hfo, VParams)
% SigString: is a string variable which is either: 'filt' or 'raw'
% chanInd: are the indices of the channels from which to view the data
%% %%%%%%%%%%%%%%%%%%%%%%%% Wrapped %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear
clc
%% The above can be collected in the following  wrapper:
ParaPath = [pwd, filesep, '+Demo', filesep,'Morph', filesep,'Parameters', filesep,'RMorphPara.mat'];
DataPath = [pwd, filesep, '+Demo', filesep,'Morph', filesep,'Data', filesep,'Data.mat'];
RefType         = 'morph'; 
% CondMulti       = false;
AnalysisDepth   = 3;
chanContains    = '';
smoothBool      = true;
hfo = Core.massHFO.getHFOdata(ParaPath, DataPath ,RefType , AnalysisDepth ,chanContains, smoothBool);
% AnalysisDepth: 1: Load parmeters,Data and filter the signal.
%                2: Compute the baseline and associated values.
%                3: Find events of interest(hfo) and associated values.
Modality          = 'iEEG';
ChanNames         = hfo.Data.channelNames;
VParams           = Visual.getVParams(Modality, ChanNames);
% SigString = 'raw';
Visual.ValidateHFO(hfo,hfo,hfo, VParams)
%% %%%%%%%%%%%% Combining ripples and fast ripples %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear
clc
%% Difference in ripples and fast ripples is that they are computed using different parameters.
rParaPath       = [pwd, filesep, '+Demo', filesep,'Morph', filesep,'Parameters', filesep,'RMorphPara.mat'];
frParaPath      = [pwd, filesep, '+Demo', filesep,'Morph', filesep,'Parameters', filesep,'FRMorphPara.mat'];
DataPath        = [pwd, filesep, '+Demo', filesep,'Morph', filesep,'Data', filesep,'Data.mat'];
RefType         = 'morph'; 
AnalysisDepth   = 3;
chanContains    = '';
smoothBool      = true;
% ContThresh      = 0.8;
rhfo = Core.massHFO.getHFOdata(rParaPath, DataPath ,RefType , AnalysisDepth ,chanContains, smoothBool);
frhfo = Core.massHFO.getHFOdata(frParaPath, DataPath ,RefType , AnalysisDepth ,chanContains, smoothBool);
% what we do now is look to see which of the fast ripples are contained in
% ripples as the co-occurence of the two is a good predictor of the HFO area
CoOccurenceInfo = Core.CoOccurence.getECECoOccurence(rhfo, frhfo);
RippleAndFastRippleRates = CoOccurenceInfo.Rates.RippleANDFastRipple;
RFRhfo = Core.CoOccurence.getRFRevents(rhfo, frhfo, CoOccurenceInfo);

% Validate the co-occurence of Ripples and Fast ripples
Modality          = 'iEEG';
ChanNames         = rhfo.Data.channelNames;
VParams           = Visual.getVParams(Modality, ChanNames);
% Validation interface params (VParams) can include: 
%-data: all the data or a data segment
%-dataFiltered: the filtered version of the data
%-fs: sampling frequency
%-ElectrodeLabels: specific electrodes to show
%-Markings_ToPlot: Specific markings (HFO) to plot
%-strSaveImagesFolderPath: Path to save images of the markings
%More information on function Visual.ValidateHFO
Visual.ValidateHFO(rhfo,frhfo,RFRhfo, VParams)

