% 信号滤波类
classdef FilterSignal
    properties
        hfo % HFO类的对象
        Output % 进行滤波后的输出对象，包含filtSignal、Envelope两个属性
        % filtSignal为hfo.Data经过零相位数字滤波后的记过
        % Envelope为filtSignal经过希尔伯特变换分析后，并取绝对值后的结果，即包络线
    end
    methods
%% Filters the bipolar data signal using predefined parameter
        % 对hfo.Data即数据，进行零相位数字滤波
        function obj = filterSignal(obj)
            % Input: Data(signal matrix) and filter parameters
            % Simply filter the signal with specified filter coefficients
            % Output: Filtered signal (matrix) 
            Signal = obj.hfo.Data.signal;
            B = obj.hfo.Para.FilterPara.bCoef; % 过滤参数
            A = obj.hfo.Para.FilterPara.aCoef;
            disp(['Filtering the signal'])
            obj.Output.filtSignal = filtfilt(B, A, Signal); % 零相位数字滤波 TODO 看不懂
            % https://ww2.mathworks.cn/help/signal/ref/filtfilt.html?s_tid=doc_ta 
            % https://blog.csdn.net/weixin_43249038/article/details/123970682
        end
        
%% Find signal envelope
        % 获取数据的包络线
        function obj = getSignalEnvelope(obj, smoothBool)
            % input: filtered data signal
            % output: Envelope of filtered signal (smoothing option)
            disp(['Find envelope'])
            smoothWin = obj.hfo.Para.SmoothWindow;
            fs = obj.hfo.Data.sampFreq;
            
            % Classical approach to finding signal envelope
            filterSignal = obj.Output.filtSignal;            
            hilbFiltSignal = hilbert(filterSignal); % 用希尔伯特变换对离散时间信号进行分析 TODO 看不懂
            % https://ww2.mathworks.cn/help/signal/ref/hilbert.html?s_tid=doc_ta
            envel = abs(hilbFiltSignal); % 取绝对值
            
            
            % Optional smoothing in the case of the morphology detector
            % 不进行平滑化处理
             if ~smoothBool 
                 obj.Output.Envelope = envel;
                 return
             end
            
            % 进行平滑化处理
             smoothPara = smoothWin*fs; % 计算用于计算经过平滑处理的值的数据点数
             nbCol = size(hilbFiltSignal,2); % 取列数
             if nbCol == 1 % 只有1列
                 obj.Output.Envelope = smooth(envel, smoothPara); % 使用移动平均滤波器平滑处理列向量envel中的响应数据，将移动平均值的跨度设置为smoothPara。
             else
                 for iCol = 1:nbCol
                     obj.Output.Envelope(:,iCol) = smooth(envel(:,iCol), smoothPara); % 对envel每列都做平滑处理
                 end
             end
          
        end
 
    end
end
