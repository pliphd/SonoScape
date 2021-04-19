classdef ternary < handle
    %TERNARY class defination for ternary plot
    % 
    % $Author: Peng Li
    % $Date:   Apr 12, 2021
    % 
    
    properties (Hidden = true)
        NumberStrip
    end
    
    methods
        function this = ternary(aA, aB, aC, varargin)
            % parse inputs
            allArg = varargin;
            if nargin >= 5
                argFig = find(strcmpi(allArg, 'Parent'));
                if ~isempty(argFig)
                    h = allArg{argFig + 1};
                    h.NextPlot = 'add';
                    allArg([argFig, argFig+1]) = [];
                else
                    h = axes('NextPlot', 'add');
                end
                
                argScale = find(strcmpi(allArg, 'SizeScale'));
                if ~isempty(argScale)
                    sizeScale = allArg{argScale + 1};
                    allArg([argScale, argScale+1]) = [];
                else
                    sizeScale = 'linear';
                end
                
                argStrip = find(strcmpi(allArg, 'NumberStrip'));
                if ~isempty(argStrip)
                    numStrip = allArg{argStrip + 1};
                    allArg([argStrip, argStrip+1]) = [];
                else
                    numStrip = 10;
                end
                
                argOccu = find(strcmpi(allArg, 'Occurance'));
                if ~isempty(argOccu)
                    occu = allArg{argOccu + 1};
                    allArg([argOccu, argOccu+1]) = [];
                else
                    occu = [];
                end
                
                argSize = find(strcmpi(allArg, 'Size'));
                if ~isempty(argSize)
                    occuSize = allArg{argSize + 1};
                    allArg([argSize, argSize+1]) = [];
                else
                    occuSize = [];
                end
                
                argLabel =find(strcmpi(allArg, 'Label'));
                if ~isempty(argLabel)
                    label = allArg{argLabel + 1};
                    allArg([argLabel, argLabel+1]) = [];
                else
                    label = [];
                end
            elseif nargin == 3
                h = axes('NextPlot', 'add');
                sizeScale = 'linear';
                
                numStrip = 10;
                occu     = [];
                occuSize = [];
                
                label    = [];
            end
            
            if numStrip ~= 10
                error('ternary initiation: number of stripps can only be 10 in the current version');
            end
            
            this.NumberStrip = numStrip;
            
            % make template
            % strip lines
            % 1. intercepts on b-c
            x_bc = 1:(numStrip-1);          y_bc = zeros(1, numStrip-1);
            % 2. intercepts on a-b
            x_ab = x_bc.*cos(pi/3);         y_ab = x_bc.*sin(pi/3);
            % 3. intercepts on a-c
            x_ac = numStrip-x_ab;           y_ac = y_ab;
            
            for iS = 1:(numStrip-1)
                plot(h, [x_ab(iS) x_ac(iS)], [y_ab(iS) y_ac(iS)], ...
                    'LineStyle', '--', 'LineWidth', 1, 'Color', [.8 .8 .8]);
                plot(h, [x_ab(iS) x_bc(iS)], [y_ab(iS) y_bc(iS)], ...
                    'LineStyle', '--', 'LineWidth', 1, 'Color', [.8 .8 .8]);
                plot(h, [x_bc(iS) x_ac(numStrip-iS)], [y_bc(iS) y_ac(numStrip-iS)], ...
                    'LineStyle', '--', 'LineWidth', 1, 'Color', [.8 .8 .8]);
            end
            
            % points
            a = [numStrip/2, numStrip*sin(pi/3)];
            b = [0, 0];
            c = [numStrip, 0];
            
            plot(h, [a(1) b(1)], [a(2) b(2)], 'LineStyle', '-', 'LineWidth', 1, 'Color', 'k');
            plot(h, [a(1) c(1)], [a(2) c(2)], 'LineStyle', '-', 'LineWidth', 1, 'Color', 'k');
            plot(h, [c(1) b(1)], [c(2) b(2)], 'LineStyle', '-', 'LineWidth', 1, 'Color', 'k');
            
            set(h.Parent, 'Color', 'w');
            h.XColor = 'none'; h.YColor = 'none';
            
            % labels
            text(h, [b(1) x_bc], [b(2) y_bc]-0.4, num2str((0:numStrip-1)'), 'Rotation', 60, 'HorizontalAlignment', 'center')
            text(h, [x_ab a(1)]-0.4, [y_ab a(2)], num2str((numStrip-1:-1:0)'), 'Rotation', -60, 'HorizontalAlignment', 'center');
            text(h, [x_ac a(1)]+0.9, [y_ac a(2)]-sin(pi/3), num2str((0:numStrip-1)'), 'HorizontalAlignment', 'center');
            
            % place points
            % 1. parse points
            % if ~all(aA+aB+aC == 10)
            %     error('ternary initiation: mismatched inputs: apexes should sum up to 1');
            % end
            
            if isempty(occu) || isempty(occuSize) % overwrite another input
                % 2. unique combinations
                allP  = [aA(:) aB(:) aC(:)];
                [allPU, ~, indu] = unique(allP, 'rows', 'stable');
                occu = accumarray(indu, 1);
                
                % 3. sort by occurance
                [occu, indOccu] = sort(occu);
                allPU = allPU(indOccu, :);
            else
                allPU = [aA(:) aB(:) aC(:)];
            end
            
            % 4. convert apexes to 2-D plain
            XData = numStrip - allPU(:, 2) - allPU(:, 1) .* cos(pi/3);
            YData = allPU(:, 1) .* sin(pi/3);
            
            switch sizeScale
                case 'log'
                    occuLog  = log10(occu+1);
                    occuSize = occuLog .* (200 ./ max(occuLog));
                    
                    % note
                    text(h, 0, 10*sin(pi/3), 'Note: Dot size is log scaled', 'FontSize', 8);
                case 'linear'
                    occuSize = occu .* (200 ./ max(occu));
            end
            
            scatter(h, XData, YData, occuSize, occu, ...
                'filled');
            
            % 5. label
            if ~isempty(label)
                text(h, 4.5, -sin(pi/3), label{1});
                text(h, 1, 4*sin(pi/3),  label{2}, 'Rotation', 60);
                text(h, 8, 6*sin(pi/3),  label{3}, 'Rotation', -60);
            end
            
            colormap(h, 'jet');
            colorbar(h);
            axis(h, 'square');
        end
    end
end