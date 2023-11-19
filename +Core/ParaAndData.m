classdef ParaAndData
    properties
        %Input
        ParaFileLocation % 参数文件路径
        DataFileLocation % 数据文件路径
        %Output
        Para % 参数
        Data % 数据
    end
    methods     
        %% Load predetermined parameters from a saved .mat file
        % 从.mat文件中加载参数，或者设置手动输入参数的相关标记
        function obj = loadParameters(obj)
            % input: location of parameter files.mat (string) format
            % output: loaded parameters
            if ischar(obj.ParaFileLocation)
                load(obj.ParaFileLocation); % 加载参数文件
                obj.Para = DetPara; % 获取参数
                obj.Para.ParaFileLocation = obj.ParaFileLocation; % 修改参数中的参数文件路径
            elseif isstruct(obj.ParaFileLocation) % 如果参数文件路径为结构体，即参数手动输入
                obj.Para = obj.ParaFileLocation;
                obj.Para.ParaFileLocation = 'Manual input';
            end
            % 初始化startBaseline参数
            if ~isfield(obj.Para, 'startBaseline')
                obj.Para.startBaseline = 1;
            end
        end
        
        %% Load data and relavant meta-data
        % 加载数据和相关的元数据
        function obj = loadData(obj, chanContains)
            %input: Parameters, Data file location.mat (string) and cell of
            %channel names (cell of strings)
            %output: Loaded data and computed meta data

            % 获取参数
            maxToJoinPARA = obj.Para.maxIntervalToJoinPARA;
            MinHiEntrPARA = obj.Para.MinHighEntrIntvLenPARA;
            minETPARA     = obj.Para.minEventTimePARA;
            maxETPARA     = obj.Para.maxEventTimePARA;
            durBaseline   = obj.Para.DurBaseline; 
            startBasline  = obj.Para.startBaseline;
            
            if ischar(obj.DataFileLocation) % 数据路径为字符串
                obj.Data.DataFileLocation  = obj.DataFileLocation; 
                load(obj.DataFileLocation, 'data') % 加载数据文件中的data变量
            elseif isstruct(obj.DataFileLocation) % 数据路径为结构体，即手动输入数据
                obj.Data.DataFileLocation  = 'Manual Input';
                data = obj.DataFileLocation;
            end

            try
                data.lab_bip = data.bib_lab; % 将data数据中的bib_lab属性转为lab_bip属性
            catch
            end
            % read 读取数据中的Datasetup属性
            if  isfield(data, 'Datasetup') % 数据中是否包含Datasetup字段
                obj.Data.dataSetup = data.Datasetup;% Electrode dimensions 电极维度，将data中的Datasetup属性值放到obj.Data.dataSetup中
            else
                obj.Data.dataSetup = [];
            end
            
            [sign, chanNames]           = Core.ParaAndData.getSignal(data.x_bip, data.lab_bip, chanContains);
            obj.Data.signal             = sign;
            obj.Data.channelNames       = chanNames;  
            obj.Data.sampFreq           = data.fs;  
            
            % intermediate values
            lenSig = length(obj.Data.signal);
            nbChan = length(obj.Data.channelNames);
            nbSamples = size(obj.Data.signal,1); % 取行数
            fs =  obj.Data.sampFreq;
            sigdur = lenSig/fs;
            % computed
            obj.Data.maxIntervalToJoin  = maxToJoinPARA*fs;
            obj.Data.MinHighEntrIntvLen = MinHiEntrPARA*fs;
            obj.Data.minEventTime       = minETPARA*fs;
            obj.Data.maxEventTime       = maxETPARA*fs;
            obj.Data.sigDurTime         = sigdur;
            if startBasline  == 1
            obj.Data.timeInterval       = [startBasline, durBaseline]; 
            else
            obj.Data.timeInterval       = [startBasline, startBasline + durBaseline];
            end
            obj.Data.nbChannels         = nbChan;
            obj.Data.nbSamples          = nbSamples;
            
            electrodeInfo = Core.ParaAndData.sortElectrodes(chanNames);
            obj.Data.electrodeInfo = electrodeInfo;
            
        end
        
        %% Test detector parameters against data for consistency
        function [] = testParameters(obj)
            % Input: parameters, data and meta data (all computed above)
            % Output: warnings and errors if inconistencies are detected.
            LowPass  = obj.Para.lowPass; 
            HighPass = obj.Para.highPass;

            if HighPass > LowPass
                warning(['Low pass frequency ' ,char(LowPass), ' must be higher than High pass frequency ', char(HighPass)])
            end
            
            DurBl = obj.Para.DurBaseline;
            startBl = obj.Para.startBaseline;
            sigDur = obj.Data.sigDurTime;
            
            assert(startBl > 0,'Baseline start set in negative time.')
            if (DurBl + startBl > sigDur)
             disp( 'Set-Baseline time segment exceeds signal.')
            end
        end
        
    end
    % 定义静态方法
    methods(Static)
        function [signal, chanNames] = getSignal(x_bip, lab_bip, chanContains)
            % Input: signal, channel labels, cell of strings
            %extracts channel data of channels with names containing 'chanContains'
            % output: selected signal and channel labels
            maskChanContains = contains(lab_bip, chanContains);
            if min(size(x_bip)) == 1
                signal        = x_bip';
            else
                signal        = x_bip(maskChanContains ,:)';
            end
            chanNames = lab_bip(maskChanContains);
            
        end
        
        %% sorting Electrodes
        function electrodeInfo = sortElectrodes(chan_names)
            % this function looks at the given names of the electrode
            % contacts and then decides whether it is scalp, ECoG or iEEG
            % Then it proceeds to group them
            if any(contains(chan_names,{'A' 'C' 'F' 'P' 'O' 'Fp' 'T'}))
                ElecType = 'Scalp';
            else
                ElecType = 'Unknown'; 
            end
            
            mask.Left     = contains(chan_names,{'1' '3' '5' '7'});
            mask.Right    = contains(chan_names,{'2' '4' '6' '8'});
            mask.Central  = contains(chan_names,{'C' 'c' });
            mask.Frontal  = contains(chan_names,{'F' 'f' });
            mask.Temporal = contains(chan_names,{'T' 't' });
            mask.Occipital  = contains(chan_names,{'O' 'o' });
            mask.Parietal = contains(chan_names,{'P' 'p' });
            
            electrodeInfo.mask = mask;
            electrodeInfo.ElecType = ElecType;
        end
    end
end