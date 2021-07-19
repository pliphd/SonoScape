% About
% 
% Descriptions tba
% 
%   $Author:  Peng Li, Ph.D.
%                   Division of Sleep Medicine, Brigham & Women's Hospital
%                   Division of Sleep Medicine, Harvard Medical School
%   $Date:    May 16, 2018
%   $Modif.:  Mar 03, 2021
%               modified for SonoScape
% 
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%                      (C) Peng Li 2020 -
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% 
classdef about < handle
    properties (Access = private)
        AboutEZFigure
        icanAxes
        logButton
        verLabel
        rightLabel
        ackLabel
    end
    
    methods (Access = public)
        function app = about(varargin)
            createComponents(app);
            
            if nargin == 0
                icon2Read = 'sc.jpg';
                app.AboutEZFigure.Name = 'About SonoScape';
            elseif nargin >= 2
                app.AboutEZFigure.Name = varargin{1};
                icon2Read = varargin{2};
            end
            
            im = imread(icon2Read);
            image(imresize(im, 0.3), 'Parent', app.icanAxes);
            app.icanAxes.XLim = [1 200];
            app.icanAxes.YLim = [1 160];
            app.icanAxes.XTick = [];
            app.icanAxes.YTick = [];
            app.icanAxes.XColor = 'none';
            app.icanAxes.YColor = 'none';
            app.icanAxes.Toolbar.Visible = 'off';
            
            if nargin == 3
                app.verLabel.Text = varargin{3};
            end
        end
    end
    
    methods (Access = private)
        function createComponents(app)
            % center fig
            screenUn = get(0, 'Units');
            set(0, 'Units', 'pixels');
            screensz = get(0, 'ScreenSize');
            figLeft  = (screensz(3) - 428)/2;
            figBot   = (screensz(4) - 240)/2;
            set(0, 'Units', screenUn);
            
            Pos = [figLeft figBot 428 240];

            app.AboutEZFigure = uifigure('Color', 'w', 'Units', 'pixels', 'Position', Pos, ...
                'Name', 'About SonoScape', ...
                'NumberTitle', 'off', 'Resize', 'off');
            
            app.icanAxes = uiaxes(app.AboutEZFigure, 'Position', [5 60 200 160], ...
                'BackgroundColor', 'w');
            
            app.logButton = uibutton(app.AboutEZFigure, 'Position', [100 20 105 20], 'Text', 'Develop log', ...
                'BackgroundColor', 'w', 'ButtonPushedFcn', @(source, event) logButtonPushedFcn(app, source, event));
            
            % sonoscape 0.1.0303
            app.verLabel = uilabel(app.AboutEZFigure, 'Position', [220 180 200 45], 'BackgroundColor', 'w', ...
                'Text', {'Version: 1.1.0719'; 'July 19, 2021'; 'Licence: CC BY-NC-ND 4.0'});
            
            app.rightLabel = uilabel(app.AboutEZFigure, 'Position', [220 120 200 45], 'BackgroundColor', 'w', ...
                'Text', {'© 2020- Peng Li & Almo Farina'; ''; ''}); % empty strings to be filled
            
            app.ackLabel = uilabel(app.AboutEZFigure, 'Position', [220 20 200 85], 'BackgroundColor', 'w', ...
                'Text', {'Acknowledgment:'; 'MATLAB is registered trademarks'; 'of The MathWorks, Inc.'; ''; ''; ''}); % empty strings to be filled
        end
    end
    
    methods (Access = private)
        function app = logButtonPushedFcn(app, source, event)
            
        end
    end
end