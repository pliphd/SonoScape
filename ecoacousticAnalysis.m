% ACI analysis
% 
% Descriptions tba
% 
%   $Author:  Peng Li, Ph.D.
%                   Division of Sleep Medicine, Brigham & Women's Hospital
%                   Division of Sleep Medicine, Harvard Medical School
%   $Date:    Mar 01, 2020
%   $Modif.:  Jun 30, 2023
%                   Adapt the writing of ACITf to allow the process of long
%                     files.
% 
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%                      (C) Peng Li 2020 -
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% 
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
            'clumping',     [], ...
            'energyFilter', struct('field', {'near'}, 'lowEnergy', [], 'highEnergy', []), ...
            'freqFilter',   struct('lowFreq', [], 'highFreq', []));
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
        amplitudeSpectrum                % 512 * #windows * #segments
        aciF                             % collapse dim 2 --> 512      * #segments * #highEnergyFilters
        aciT                             % collapse dim 1 --> #windows * #segments * #highEnergyFilters
    end
    
    properties (Dependent = true)
        aciFTot                          % collapse dim 2 from aciF --> 512 * 1         * #highEnergyFilters
        aciFTo                           % collapse dim 1 from aciF --> 1   * #segments * #highEnergyFilters
        aciTTo                           % collapse dim 1 from aciT --> 1   * #segments * #highEnergyFilters
        aciTToMax
        aciFEvenness
        aciTEvenness
    end
    
    % shadow
    properties (Hidden = true)
        amplitudeSpectrum_
        aciF_
        aciT_
        
        aciFTot_
        aciFTo_
        aciTTo_
        aciTToMax_
        
        aciFEvenness_
        aciTEvenness_
    end
    
    % visible methods
    methods
        function ecoAna(this)
            tsRescale = this.rescale;
            this.stft(tsRescale);
            this.aci;
            this.aciEvenness;
            this.aciTotal;
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
            this.aciFTot = cellfun(@(x) nansum(x, 2), this.aciF, 'UniformOutput', 0);
            
            this.aciFTo  = cellfun(@nansum, this.aciF, 'UniformOutput', 0);
            this.aciTTo  = cellfun(@nansum, this.aciT, 'UniformOutput', 0);
        end
        
        function aciTotalMax(this)
            this.aciTToMax = cellfun(@(x) max(x, [], 2), this.aciTTo, 'UniformOutput', 0);
        end
    end
    
    methods
        % +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        % +++++++                output                      ++++++++++++++
        % +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        function aciWriteSeperate(this, savept, sep)
            for iS = 1:length(this.timescale)
                % loop filters
                [LOW, HIGH] = ndgrid(this.acousticComplexity.energyFilter.lowEnergy, this.acousticComplexity.energyFilter.highEnergy);
                filter = [LOW(:) HIGH(:)];
                for iF = 1:size(filter, 1)
                    % codes
                    curTbl = [this.aciFTo{iS}(:, :, iF)', this.aciTTo{iS}(:, :, iF)', ...
                        this.aciFEvenness{iS}(:, :, iF)', this.aciTEvenness{iS}(:, :, iF)'];
                    newFolder = fullfile(savept, ['scale_' num2str(this.timescale(iS)) 's'], 'ACI');
                    if ~(exist(newFolder, 'dir') == 7)
                        mkdir(newFolder);
                    end
                    
                    switch this.acousticComplexity.energyFilter.field
                        case 'near'
                            fid = fopen(fullfile(newFolder, ...
                                "CODES_"  + num2str(this.timescale(iS)) ...
                                + '_near_' + num2str(filter(iF, 2)) + '.txt'), 'w');
                        case 'far'
                            fid = fopen(fullfile(newFolder, ...
                                "CODES_"  + num2str(this.timescale(iS)) ...
                                + '_far_' + num2str(filter(iF, 1)) ...
                                + '_'     + num2str(filter(iF, 2)) + '.txt'), 'w');
                    end
                            
                    fprintf(fid, "%f"+sep+"%f"+sep+"%f"+sep+"%f\r\n", curTbl');
                    fclose(fid);
                end
            end
        end
        
        function aciWriteMax(this, savept, sep)
            tempAciTToMax = squeeze(cat(1, this.aciTToMax{:}));
            
            [SCALE, LOW, HIGH] = ndgrid(this.timescale, this.acousticComplexity.energyFilter.lowEnergy, this.acousticComplexity.energyFilter.highEnergy);
            temp   = [SCALE(:) LOW(:) HIGH(:)];
            outTbl = [array2table(temp, 'VariableNames', {'timescale_in_sec', 'low_energy', 'high_energy'}), ...
                table(tempAciTToMax(:), 'VariableNames', {'max_acift'})];
            
            writetable(outTbl, fullfile(savept, 'ACIFtMax_' + string(this.acousticComplexity.energyFilter.field) + '.txt'), 'Delimiter', sep);
        end
        
        function aciWriteMat(this, savept)
            aciTimescale__ = this.timescale;
            aciPara__      = this.acousticComplexity;
            aciTTo__       = this.aciTTo;
            aciTToSum__    = cellfun(@(x) sum(x, 2), aciTTo__, 'UniformOutput', 0);
            aciFTot__      = this.aciFTot;
            aciTToMax__    = this.aciTToMax;
            aciTEvenness__ = this.aciTEvenness;
            aciFEvenness__ = this.aciFEvenness;
            aciF__         = this.aciF;
            aciT__         = this.aciT;
            save(fullfile(savept, 'cache.mat'), ...
                'aciTimescale__', 'aciPara__', 'aciTTo__', 'aciTToSum__', 'aciFTot__', 'aciTToMax__', 'aciTEvenness__', 'aciFEvenness__', 'aciF__', 'aciT__');
        end
        
        function aciWriteACIMatrix(this, savept, sep, varargin)
            switch nargin
                case 3
                    writeMode = 'collate';
                case 4
                    writeMode = 'subdivide';
                    per       = varargin{1};
            end

            for iS = 1:length(this.timescale)
                newFolder = fullfile(savept, ['scale_' num2str(this.timescale(iS)) 's'], 'ACI');
                if ~(exist(newFolder, 'dir') == 7)
                    mkdir(newFolder);
                end
                
                % gran total files location
                [resFolder, filename] = fileparts(savept);
                
                % loop filters
                [LOW, HIGH] = ndgrid(this.acousticComplexity.energyFilter.lowEnergy, this.acousticComplexity.energyFilter.highEnergy);
                filter      = [LOW(:) HIGH(:)];
                
                for iF = 1:size(filter, 1)
                    switch this.acousticComplexity.energyFilter.field
                        case 'near'
                            nameParts = "_near_" + num2str(filter(iF, 2)) + '.txt';
                        case 'far'
                            nameParts = "_far_"  + num2str(filter(iF, 1)) + "_" + num2str(filter(iF, 2)) + '.txt';
                    end
                    
                    % acift
                    filept = fullfile(newFolder, ...
                        "ACIFt_" + num2str(this.timescale(iS)) + nameParts);
                    writematrix(this.aciT{iS}(:, :, iF), filept, 'Delimiter', sep);
                    
                    % acitf
                    filept = fullfile(newFolder, ...
                        "ACITf_" + num2str(this.timescale(iS)) + nameParts);
                    switch writeMode
                        case 'collate'
                            writematrix(this.aciF{iS}(:, :, iF)', filept, 'Delimiter', sep);
                        case 'subdivide'
                            % replace file name .txt with .xlsx
                            fileptx = extractBefore(filept, strlength(filept)-4)+"xlsx";

                            secondSeries = (1:this.timescale(iS):(size(this.aciF{iS}(:, :, iF), 2)*this.timescale(iS)))';
                            firstSeries  = floor((secondSeries - 1) / per / 60) + 1;
                            % writematrix([firstSeries secondSeries this.aciF{iS}(:, :, iF)'], filept, 'Delimiter', sep);

                            aciFtemp  = this.aciF{iS}(:, :, iF)';

                            % separate sheet
                            allSheets = unique(firstSeries);
                            for iSS = 1:numel(allSheets)
                                currentAciF = aciFtemp(firstSeries == allSheets(iSS), :);
                                writematrix(currentAciF, fileptx, 'FileType', 'spreadsheet', 'Sheet', "seg_"+num2str(allSheets(iSS)));
                            end

                            % tot
                            totAciF = splitapply(@(x) sum(x, 1, 'omitnan'), aciFtemp, firstSeries(:));
                            writematrix([allSheets(:) totAciF], fileptx, 'FileType', 'spreadsheet', 'Sheet', "tot");
                    end
                    
                    % acift_tot
                    filept = fullfile(newFolder, ...
                        "ACIFt_Tot_" + num2str(this.timescale(iS)) + nameParts);
                    writematrix(this.aciTTo{iS}(:, :, iF), filept, 'Delimiter', sep);
                    
                    % acitf_tot
                    filept = fullfile(newFolder, ...
                        "ACITf_Tot_" + num2str(this.timescale(iS)) + nameParts);
                    writematrix(this.aciFTot{iS}(:, :, iF)', filept, 'Delimiter', sep);
                    
                    % acift_ttot
                    filept = fullfile(resFolder, ...
                        "ACIFt_TTot_" + num2str(this.timescale(iS)) + nameParts);
                    writetable([table(filename) array2table([this.aciTTo{iS}(:, :, iF) sum(this.aciTTo{iS}(:, :, iF))])], ...
                        filept, 'Delimiter', sep, 'WriteMode', 'append', 'WriteVariableNames', 0);
                    
                    % writematrix([this.aciTTo{iS}(:, :, iF) sum(this.aciTTo{iS}(:, :, iF))], ...
                    %     filept, 'Delimiter', sep, 'WriteMode', 'append');
                    
                    % acitf_ttot
                    filept = fullfile(resFolder, ...
                        "ACITf_TTot_" + num2str(this.timescale(iS)) + nameParts);
                    writetable([table(filename) array2table(this.aciFTot{iS}(:, :, iF)')], ...
                        filept, 'Delimiter', sep, 'WriteMode', 'append', 'WriteVariableNames', 0);
                    
                    % writematrix(this.aciFTot{iS}(:, :, iF)', ...
                    %     filept, 'Delimiter', sep, 'WriteMode', 'append');
                end
            end
        end
        
        function aciWriteIntermediate(this, savept, sep)
            for iS = 1:length(this.timescale)
                newFolder = fullfile(savept, ['scale_' num2str(this.timescale(iS)) 's'], 'ACI');
                if ~(exist(newFolder, 'dir') == 7)
                    mkdir(newFolder);
                end
                
                for iF = 1:size(this.amplitudeSpectrum{iS}, 3)
                    filept = fullfile(newFolder, ['FFT_' num2str(this.timescale(iS)) '_' num2str(iF) '.txt']);
                    writematrix(this.amplitudeSpectrum{iS}(:, :, iF), filept, 'Delimiter', sep);
                end
            end
        end
    end
    
    %% development paused
    % upper level
    methods (Hidden = true)
        function ecoAnaFast(this)
            this.stftOverlap;
            this.aciCalc;
            this.aciEvenness;
            this.aciTotal
        end
    end
    
    % private
    % not updated for vectorized filters
    methods (Hidden = true)
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
            if strcmp(this.acousticComplexity.energyFilter.field, 'near')
                ampSpec(ampSpec <= this.acousticComplexity.energyFilter.highEnergy) = 0;
            else
                ampSpec(ampSpec >= this.acousticComplexity.energyFilter.highEnergy | ampSpec <= this.acousticComplexity.energyFilter.lowEnergy) = 0;
            end
            if ~isempty(this.acousticComplexity.freqFilter.lowFreq)
                ampSpec(1:this.acousticComplexity.freqFilter.lowFreq, :)  = 0;
            end
            if ~isempty(this.acousticComplexity.freqFilter.highFreq)
                ampSpec(this.acousticComplexity.freqFilter.highFreq:end, :)  = 0;
            end
            
            % acitf and acift
            this.aciF = arrayfun(@(x) doAciF(ampSpec, this.fs, x), scaleAfterClumping, ...
                'UniformOutput', 0);
            
            this.aciT = arrayfun(@(x) doAciT(ampSpec, this.fs, x), scaleAfterClumping, ...
                'UniformOutput', 0);
        end
    end
    
    methods (Hidden = true)
        % +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        % +++++++          output other options              ++++++++++++++
        % +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
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
    methods (Hidden = true)
        function stft_(this, curScale)
            tsRescale = reshape(this.ts, this.fs*curScale, []);
            ampSpec   = stft(tsRescale, 'Window', this.window, 'OverlapLength', 0);
            
            halfway   = ceil(length(ampSpec)/2);
            singleS   = abs(ampSpec(halfway:end, :, :));
            singleS(2:end, :, :) = 2 * singleS(2:end, :, :);
            
            aciCell(singleS, this.acousticComplexity);
        end
    end
    
    %% constructor
    methods
        function this = ecoacousticAnalysis
        end
    end
    
    %% other dependencies
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
        
        function val = get.aciFTot(this)
            val = this.aciFTot_;
        end
        
        function set.aciFTot(this, val)
            this.aciFTot_ = val;
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
    
    % filtering --- frequency filters
    if ~isempty(parameter.freqFilter.lowFreq)
        ampSpec(1:parameter.freqFilter.lowFreq, :, :) = 0;
    end
    if ~isinf(parameter.freqFilter.highFreq)
        ampSpec(parameter.freqFilter.highFreq:end, :, :) = 0;
    end
    
    % calc
    [LOW, HIGH] = ndgrid(parameter.energyFilter.lowEnergy, parameter.energyFilter.highEnergy);
    aciF = arrayfun(@(x, y) aciFEachFilter(ampSpec, parameter.energyFilter.field, x, y), ...
        LOW, HIGH, 'UniformOutput', 0);
    aciF = cat(3, aciF{:});
    
    function aciF = aciFEachFilter(ampSpec, field, lowEnergy, highEnergy)
        % filtering --- amplitude filters
        if strcmp(field, 'near')
            ampSpec(ampSpec <= highEnergy) = 0;
        else
            ampSpec(ampSpec >= highEnergy | ampSpec <= lowEnergy) = 0;
        end
        
        % do calc
        numerator = abs(ampSpec(:, 1:end-1, :) - ampSpec(:, 2:end, :));
        
        % per rule of ACI, set result to zero if either one is zero
        numerator(ampSpec(:, 1:end-1, :) == 0 | ampSpec(:, 2:end, :) == 0) = 0;
        
        denominator = ampSpec(:, 1:end-1, :) + ampSpec(:, 2:end, :);
        
        aciF = squeeze(nansum(numerator ./ denominator, 2));
    end
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
    
    % filtering --- frequency filters
    if ~isempty(parameter.freqFilter.lowFreq)
        ampSpec(1:parameter.freqFilter.lowFreq, :, :) = 0;
    end
    if ~isinf(parameter.freqFilter.highFreq)
        ampSpec(parameter.freqFilter.highFreq:end, :, :) = 0;
    end
    
    % calc
    [LOW, HIGH] = ndgrid(parameter.energyFilter.lowEnergy, parameter.energyFilter.highEnergy);
    aciT = arrayfun(@(x, y) aciTEachFilter(ampSpec, parameter.energyFilter.field, x, y), ...
        LOW, HIGH, 'UniformOutput', 0);
    aciT = cat(3, aciT{:});
    
    function aciT = aciTEachFilter(ampSpec, field, lowEnergy, highEnergy)
        % filtering --- amplitude filters
        if strcmp(field, 'near')
            ampSpec(ampSpec <= highEnergy) = 0;
        else
            ampSpec(ampSpec >= highEnergy | ampSpec <= lowEnergy) = 0;
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
end

%% currently no use
function out = aciFor(singleS, parameter)
    [r, c, p]  = size(singleS);
    tf = nan(p, r);
    ft = nan(p, c);
    
    for iP = 1:p
        tf(iP, :) = aci(singleS(:, :, iP), parameter.energyFilter, 'tf');
        ft(iP, :) = aci(singleS(:, :, iP), parameter.energyFilter, 'ft')';
    end
    
    out = [{tf}, {ft}];
end

function res = aci(fftMat, energyFilter, option)
%ACI

fftMat = fftMat'; % make time as row and frequency lines as column

if strcmp(energyFilter, 'near')
    fftMat(fftMat <= energyFilter.highEnergy) = 0;
else
    fftMat(fftMat >= energyFilter.highEnergy | fftMat <= energyFilter.lowEnergy) = 0;
end

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