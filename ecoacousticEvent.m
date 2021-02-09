classdef ecoacousticEvent < handle
    properties
        aciTTo
        aciTEvenness
        aciFEvenness
    end
    
    properties (Hidden = true)
        timescale
        lowEnergy
        highEnergy
        aciTToMax
    end
    
    properties
        ee
    end
    
    methods
        function eeCalc(this)
            aciTToNorm = cellfun(@(x, y) x ./ y, this.aciTTo, this.aciTToMax, 'UniformOutput', 0);
            
            binEdge = 0:.1:1;
            
            firstPlace  = cellfun(@(x) discretize(x, binEdge)-1, aciTToNorm,        'UniformOutput', 0);
            secondPlace = cellfun(@(x) discretize(x, binEdge)-1, this.aciTEvenness, 'UniformOutput', 0);
            thirdPlace  = cellfun(@(x) discretize(x, binEdge)-1, this.aciFEvenness, 'UniformOutput', 0);
            
            this.ee     = cellfun(@(x, y, z) string(x)+string(y)+string(z), ...
                firstPlace, secondPlace, thirdPlace, 'UniformOutput', 0);
        end
        
        function eeWrite(this, savept)
            for iS = 1:length(this.timescale)
                newFolder = fullfile(savept, ['scale_' num2str(this.timescale(iS)) 's'], 'ACI');
                if ~(exist(newFolder, 'dir') == 7)
                    mkdir(newFolder);
                end
                [LOW, HIGH] = ndgrid(this.lowEnergy, this.highEnergy);
                filter = [LOW(:) HIGH(:)];
                for iF = 1:size(filter, 1)
                    fid = fopen(fullfile(newFolder, ...
                        "EE_" + num2str(this.timescale(iS)) ...
                        + '_LE' + num2str(filter(iF, 1)) ...
                        + '_HE' + num2str(filter(iF, 2)) + '.txt'), 'w');
                    fprintf(fid, '%s\r\n', this.ee{iS}(:, :, iF));
                    fclose(fid);
                end
            end
        end
        
        function eeWriteMat(this, savept)
            ee__ = this.ee;
            save(fullfile(savept, 'cache_ee.mat'), 'ee__');
        end
    end
    
    methods
        function this = ecoacousticEvent
        end
    end
end