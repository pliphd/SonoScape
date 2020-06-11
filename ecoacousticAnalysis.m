classdef ecoacousticAnalysis < handle
    properties
        % data
        ts
        fs
        startTime
        
        % analysis scale in sec
        timescale
        
        % acoustic complexity
        acousticComplexity = struct(...
            'clumping',       [], ...
            'minEnergy',      [], ...
            'cutOffFreqLine', []);
    end
    
    % hidden properties for future
    properties (Hidden = true)
        % frequency analysis parameters
        window       = hann(1024);
        windowName   = 'hann';
        windowLength = 1024;
    end
    
    % intermediate things, set hidden later
    properties (Dependent = true, Hidden = false)
        amplitudeSpectrum
        aciF
        aciT
    end
    
    properties (Dependent = true)
        aciFTo
        aciTTo
        aciTToMax
        aciFEvenness
        aciTEvenness
    end
    
    % shadow
    properties (Hidden = true)
        amplitudeSpectrum_
        aciF_
        aciT_
        
        aciFTo_
        aciTTo_
        aciTToMax_
        
        aciFEvenness_
        aciTEvenness_
    end
    
    % visible methods
    methods
        function ecoAnaFast(this)
            this.stftOverlap;
            this.aciCalc;
            this.aciEvenness;
            this.aciTotal
        end
        
        function ecoAna(this)
            tsRescale = this.rescale;
            this.stft(tsRescale);
            this.aci;
            this.aciEvenness;
            this.aciTotal
        end
    end
    
    % private
    methods
        % +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        % +++++++ using overlap stft to speed up calculation ++++++++++++++
        % +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        function stftOverlap(this)
            % zero padding ts to make the last window available
            p = stft([this.ts; zeros(rem(this.windowLength, 1000), 1)], this.fs, ...
                'Window', this.window, ...
                'OverlapLength', rem(this.windowLength, 1000));
            
            singleP = abs(p(floor(this.windowLength/2):end-1, :)); % threw last frequency line to be consistent with sfractal
            singleP(2:end, :, :)   = 2 * singleP(2:end, :, :);
            this.amplitudeSpectrum = singleP;
        end
        
        function aciCalc(this)
            ampSpec = this.amplitudeSpectrum;
            
            % clumping
            if ~isempty(this.acousticComplexity.clumping)
                intBlock  = floor(size(ampSpec, 2) / this.acousticComplexity.clumping)...
                    *this.acousticComplexity.clumping;
                temp      = reshape(ampSpec(:, 1:intBlock), ...
                    size(ampSpec, 1), this.acousticComplexity.clumping, []);
                
                if intBlock < size(ampSpec, 2)
                    ampSpec = [squeeze(sum(temp, 2)) sum(ampSpec(:, intBlock+1:end), 2)];
                else
                    ampSpec = squeeze(sum(temp, 2));
                end
                
                scaleAfterClumping = this.timescale ./ this.acousticComplexity.clumping;
            else
                scaleAfterClumping = this.timescale;
            end
            
            % filtering
            if ~isempty(this.acousticComplexity.minEnergy)
                ampSpec(ampSpec <= this.acousticComplexity.minEnergy) = 0;
            end
            if ~isempty(this.acousticComplexity.cutOffFreqLine)
                ampSpec(1:this.acousticComplexity.cutOffFreqLine, :)  = 0;
            end
            
            % acitf and acift
            this.aciF = arrayfun(@(x) doAciF(ampSpec, this.fs, x), scaleAfterClumping, ...
                'UniformOutput', 0);
            
            this.aciT = arrayfun(@(x) doAciT(ampSpec, this.fs, x), scaleAfterClumping, ...
                'UniformOutput', 0);
        end
    end
    
    methods
        % +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        % +++++++ methods match the implemental of SFractal  ++++++++++++++
        % +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        function tsRescale = rescale(this)
            % in case non divisible
            trem = floor(length(this.ts) ./ (this.fs*this.timescale)) .* (this.fs*this.timescale);
            para = [this.timescale(:) trem(:)];
            tsRescale = arrayfun(@(x) reshape(this.ts(1:para(x, 2)), this.fs*para(x, 1), []), 1:size(para, 1), ...
                'UniformOutput', 0);
        end
        
        function stft(this, tsRescale)
            this.amplitudeSpectrum = cellfun(@(x) stftCell(x, this.fs, ...
                'Window', this.window, 'OverlapLength', 0), ...
                tsRescale, 'UniformOutput', 0);
        end
        
        function aci(this)
            this.aciF = cellfun(@(x) aciFCell(x, this.acousticComplexity), ...
                this.amplitudeSpectrum, 'UniformOutput', 0);
            
            this.aciT = cellfun(@(x) aciTCell(x, this.acousticComplexity), ...
                this.amplitudeSpectrum, 'UniformOutput', 0);
        end
    end
    
    methods
        % +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        % +++++++   common implementations shared for all    ++++++++++++++
        % +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        function aciEvenness(this)
            this.aciFEvenness = cellfun(@doAciEvenness, this.aciF, 'UniformOutput', 0);
            this.aciTEvenness = cellfun(@doAciEvenness, this.aciT, 'UniformOutput', 0);
        end
        
        function aciTotal(this)
            this.aciFTo = cellfun(@nansum, this.aciF, 'UniformOutput', 0);
            this.aciTTo = cellfun(@nansum, this.aciT, 'UniformOutput', 0);
        end
        
        function aciTotalMax(this)
            this.aciTToMax = cellfun(@max, this.aciTTo);
        end
    end
    
    methods
        % +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        % +++++++                output                      ++++++++++++++
        % +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        function aciWriteSeperate(this, savept)
            for iS = 1:length(this.timescale)
                curTbl = [this.aciFTo{iS}(:), this.aciTTo{iS}(:), ...
                    this.aciFEvenness{iS}(:), this.aciTEvenness{iS}(:)];
                newFolder = fullfile(savept, ['scale_' num2str(this.timescale(iS)) 's'], 'ACI');
                if ~(exist(newFolder, 'dir') == 7)
                    mkdir(newFolder);
                end
                fid = fopen(fullfile(newFolder, ['CODES_' num2str(this.timescale(iS)) '.txt']), 'w');
                fprintf(fid, '%f\t%f\t%f\t%f\r\n', curTbl');
                fclose(fid);
            end
        end
        
        function aciWriteMax(this, savept)
            curTbl = table(this.timescale(:), this.aciTToMax(:), 'VariableNames', {'timescale_in_sec', 'max_acift'});
            writetable(curTbl, fullfile(savept, 'ACIFtMax.txt'), 'Delimiter', 'tab');
        end
        
        function aciWriteMat(this, savept)
            aciTTo__       = this.aciTTo;
            aciTToMax__    = this.aciTToMax;
            aciTEvenness__ = this.aciTEvenness;
            aciFEvenness__ = this.aciFEvenness;
            save(fullfile(savept, 'cache.mat'), 'aciTTo__', 'aciTToMax__', 'aciTEvenness__', 'aciFEvenness__');
        end
        
        function aciWrite(this, filename)
            % write template
            % aciFTo, aciTTo, aciFEveness, aciTEvenness
            % 
            for iS = 1:length(this.timescale)
                % make table
                curTbl = table(this.aciFTo{iS}(:), this.aciTTo{iS}(:), ...
                    this.aciFEvenness{iS}(:), this.aciTEvenness{iS}(:), ...
                    'VariableNames', {'ACItfSum', 'ACIftSum', 'ACItfEvenness', 'ACIftEvenness'});
                writetable(curTbl, filename, 'Sheet', "scale_"+num2str(this.timescale(iS)));
            end
        end
    end
    
    
    methods (Hidden = true, Access = private)
        % +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        % +++++++    threw temporarily, under development    ++++++++++++++
        % +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        function tsRescale = rescale_(this)
            tsRescale = arrayfun(@(x) ...
                doRescale(this.ts, this.fs, this.windowLength, x), ...
                this.timescale, ...
                'UniformOutput', 0);
            
%             % lower using for
%             for iS = length(this.timescale):-1:1
%                 temp = reshape(this.ts, this.fs*this.timescale(iS), []);
%                 temp(floor(this.fs*this.timescale(iS)/this.windowLength)*this.windowLength+1:end, :) = [];
%                 tsRescale{iS} = reshape(temp, this.windowLength, []);
%             end
        end
        
        
    end
    
    % methods works on single scale
    methods
        function stft_(this, curScale)
            tsRescale = reshape(this.ts, this.fs*curScale, []);
            ampSpec   = stft(tsRescale, 'Window', this.window, 'OverlapLength', 0);
            
            halfway   = ceil(length(ampSpec)/2);
            singleS   = abs(ampSpec(halfway:end, :, :));
            singleS(2:end, :, :) = 2 * singleS(2:end, :, :);
            
            aciCell(singleS, this.acousticComplexity);
        end
    end
    
    methods
        function this = ecoacousticAnalysis
        end
    end
    
    % get. and set. for dependent variables
    methods
        function val = get.amplitudeSpectrum(this)
            val = this.amplitudeSpectrum_;
        end
        
        function set.amplitudeSpectrum(this, val)
            this.amplitudeSpectrum_ = val;
        end
        
        function val = get.aciF(this)
            val = this.aciF_;
        end
        
        function set.aciF(this, val)
            this.aciF_ = val;
        end
        
        function val = get.aciT(this)
            val = this.aciT_;
        end
        
        function set.aciT(this, val)
            this.aciT_ = val;
        end
        
        function val = get.aciFEvenness(this)
            val = this.aciFEvenness_;
        end
        
        function set.aciFEvenness(this, val)
            this.aciFEvenness_ = val;
        end
        
        function val = get.aciTEvenness(this)
            val = this.aciTEvenness_;
        end
        
        function set.aciTEvenness(this, val)
            this.aciTEvenness_ = val;
        end
        
        function val = get.aciTTo(this)
            val = this.aciTTo_;
        end
        
        function set.aciTTo(this, val)
            this.aciTTo_ = val;
        end
        
        function val = get.aciTToMax(this)
            val = this.aciTToMax_;
        end
        
        function set.aciTToMax(this, val)
            this.aciTToMax_ = val;
        end
        
        function val = get.aciFTo(this)
            val = this.aciFTo_;
        end
        
        function set.aciFTo(this, val)
            this.aciFTo_ = val;
        end
    end
end

%% helper functions
function aciF = doAciF(ampSpec, fs, scale)
    % in case not divisible
    if mod(size(ampSpec, 2), (fs/1000*scale)) ~= 0
        ampSpec(:, floor(size(ampSpec, 2)/(fs/1000*scale))*(fs/1000*scale)+1:end) = [];
    end
    
    % rescale to page, based on time scale
    ampSpec = reshape(ampSpec, size(ampSpec, 1), fs/1000*scale, []);
    
    numerator = abs(ampSpec(:, 1:end-1, :) - ampSpec(:, 2:end, :));
    
    % per rule of ACI, set result to zero if either one is zero
    numerator(ampSpec(:, 1:end-1, :) == 0 | ampSpec(:, 2:end, :) == 0) = 0;
    
    denominator = ampSpec(:, 1:end-1, :) + ampSpec(:, 2:end, :);
    
    aciF = squeeze(nansum(numerator ./ denominator, 2));
end

function aciT = doAciT(ampSpec, fs, scale)
    % in case not divisible
    if mod(size(ampSpec, 2), (fs/1000*scale)) ~= 0
        ampSpec(:, floor(size(ampSpec, 2)/(fs/1000*scale))*(fs/1000*scale)+1:end) = [];
    end
    
    % rescale to page, based on time scale
    ampSpec = reshape(ampSpec, size(ampSpec, 1), fs/1000*scale, []);

    numerator = abs(ampSpec(1:end-1, :, :) - ampSpec(2:end, :, :));
    numerator(ampSpec(1:end-1, :, :) == 0 | ampSpec(2:end, :, :) == 0) = 0;

    denominator = ampSpec(1:end-1, :, :) + ampSpec(2:end, :, :);

    aciT   = squeeze(nansum(numerator ./ denominator, 1));
    
    % in case time scale == data length in sec, no rescale will happen to
    % ampSpec, and aciT will be a row vector, force it to be a column
    if size(aciT, 1) == 1
        aciT = aciT(:);
    end
end

function evenness = doAciEvenness(aciMatrix)
    p = aciMatrix ./ nansum(aciMatrix, 1);
    evenness = (1  ./ nansum(p .* p, 1) - 1) ./ (size(aciMatrix, 1) - 1);
end

function rts = doRescale(ts, fs, windLength, s)
    temp = reshape(ts, fs*s, []);
    temp(floor(fs*s/windLength)*windLength+1:end, :) = [];
    rts  = reshape(temp, windLength, []);
end

function out = stftCell(sig, Fs, varargin)
    [S, F, T] = stft(sig, Fs, varargin{:});
    
    halfway   = ceil(length(F)/2);
    singleS   = abs(S(halfway:end-1, :, :)); % threw last frequency line to be consistent with sfractal
    singleS(2:end, :, :) = 2 * singleS(2:end, :, :);
    
    % out       = [{singleS}, {F(halfway:end)}, {T}];
    out       = singleS;
end

function aciF = aciFCell(ampSpec, parameter)
    % clumping
    if ~isempty(parameter.clumping)
        intBlock  = floor(size(ampSpec, 2) / parameter.clumping)...
            *parameter.clumping;
        
        temp      = reshape(ampSpec(:, 1:intBlock, :), ...
            size(ampSpec, 1), parameter.clumping, [], size(ampSpec, 3));
        
        if intBlock < size(ampSpec, 2)
            ampSpec = [squeeze(sum(temp, 2)) squeeze(sum(temp(:, intBlock+1:end, :, :), 2))];
        else
            ampSpec = squeeze(sum(temp, 2));
        end
    end
    
    % filtering
    if ~isempty(parameter.minEnergy)
        ampSpec(ampSpec <= parameter.minEnergy) = 0;
    end
    if ~isempty(parameter.cutOffFreqLine)
        ampSpec(1:parameter.cutOffFreqLine, :, :) = 0;
    end
    
    % do calc
    numerator = abs(ampSpec(:, 1:end-1, :) - ampSpec(:, 2:end, :));
    
    % per rule of ACI, set result to zero if either one is zero
    numerator(ampSpec(:, 1:end-1, :) == 0 | ampSpec(:, 2:end, :) == 0) = 0;
    
    denominator = ampSpec(:, 1:end-1, :) + ampSpec(:, 2:end, :);
    
    aciF = squeeze(nansum(numerator ./ denominator, 2));
end

function aciT = aciTCell(ampSpec, parameter)
    % clumping
    if ~isempty(parameter.clumping)
        intBlock  = floor(size(ampSpec, 2) / parameter.clumping)...
            *parameter.clumping;
        
        temp      = reshape(ampSpec(:, 1:intBlock, :), ...
            size(ampSpec, 1), parameter.clumping, [], size(ampSpec, 3));
        
        if intBlock < size(ampSpec, 2)
            ampSpec = [squeeze(sum(temp, 2)) squeeze(sum(temp(:, intBlock+1:end, :, :), 2))];
        else
            ampSpec = squeeze(sum(temp, 2));
        end
    end
    
    % filtering
    if ~isempty(parameter.minEnergy)
        ampSpec(ampSpec <= parameter.minEnergy) = 0;
    end
    if ~isempty(parameter.cutOffFreqLine)
        ampSpec(1:parameter.cutOffFreqLine, :, :) = 0;
    end
    
    % do calc
    numerator = abs(ampSpec(1:end-1, :, :) - ampSpec(2:end, :, :));
    numerator(ampSpec(1:end-1, :, :) == 0 | ampSpec(2:end, :, :) == 0) = 0;

    denominator = ampSpec(1:end-1, :, :) + ampSpec(2:end, :, :);

    aciT = squeeze(nansum(numerator ./ denominator, 1));
    
    % in case time scale == data length in sec, no rescale will happen to
    % ampSpec, and aciT will be a row vector, force it to be a column
    if size(aciT, 1) == 1
        aciT = aciT(:);
    end
end


% currently no use
function out = aciFor(singleS, parameter)
    [r, c, p]  = size(singleS);
    tf = nan(p, r);
    ft = nan(p, c);
    
    for iP = 1:p
        tf(iP, :) = aci(singleS(:, :, iP), parameter.minEnergy, 'tf');
        ft(iP, :) = aci(singleS(:, :, iP), parameter.minEnergy, 'ft')';
    end
    
    out = [{tf}, {ft}];
end

function res = aci(fftMat, minEnergy, option)
%ACI

fftMat = fftMat'; % make time as row and frequency lines as column
fftMat(fftMat <= minEnergy) = 0;

switch option
    case 'tf'
        numerator   = abs(fftMat(1:end-1, :) - fftMat(2:end, :));
        
        % per rule of ACI, set result to zero if either one is zero
        numerator(fftMat(1:end-1, :) == 0 | fftMat(2:end, :) == 0) = 0;
        
        denominator = fftMat(1:end-1, :) + fftMat(2:end, :);
        res = nansum(numerator ./ denominator);
    case 'ft'
        numerator   = abs(fftMat(:, 1:end-1) - fftMat(:, 2:end));
        
        % per rule of ACI, set result to zero if either one is zero
        numerator(fftMat(:, 1:end-1) == 0 | fftMat(:, 2:end) == 0) = 0;
        
        denominator = fftMat(:, 1:end-1) + fftMat(:, 2:end);
        res = nansum(numerator ./ denominator, 2);
end
end