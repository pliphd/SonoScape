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
                argStrip = find(strcmpi(allArg, 'NumberStrip'));
                if ~isempty(argStrip)
                    numStrip = allArg{argStrip + 1};
                    allArg([argStrip, argStrip+1]) = [];
                else
                    numStrip = 10;
                end
                
                argFig = find(strcmpi(allArg, 'Parent'));
                if ~isempty(argFig)
                    h = allArg{argFig + 1};
                    h.NextPlot = 'add';
                    allArg([argFig, argFig+1]) = [];
                else
                    h = axes('NextPlot', 'add');
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
            elseif nargin == 3
                numStrip = 10;
                h = axes('NextPlot', 'add');
                occu     = [];
                occuSize = [];
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
            
            plot(h, [a(1) b(1)], [a(2) b(2)], 'LineStyle', '-', 'LineWidth', 2, 'Color', 'k');
            plot(h, [a(1) c(1)], [a(2) c(2)], 'LineStyle', '-', 'LineWidth', 2, 'Color', 'k');
            plot(h, [c(1) b(1)], [c(2) b(2)], 'LineStyle', '-', 'LineWidth', 2, 'Color', 'k');
            
            set(h.Parent, 'Color', 'w');
            h.XColor = 'none'; h.YColor = 'none';
            axis(h, 'square');
            
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
                
                % scale size: max 200 fix
                occuSize = (occu - min(occu)) ./ (max(occu) - min(occu)) .* 199 + 1;
            else
                allPU = [aA(:) aB(:) aC(:)];
            end
            
            % 4. convert apexes to 2-D plain
            XData = numStrip - allPU(:, 2) - allPU(:, 1) .* cos(pi/3);
            YData = allPU(:, 1) .* sin(pi/3);
            
            scatter(h, XData, YData, occuSize, occu, ...
                'filled');
            
            colormap(h, 'cool');
            colorbar(h);
        end
    end
end