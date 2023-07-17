% Option
% 
% Descriptions tba
% 
%   $Author:  Peng Li, Ph.D.
%                   Division of Sleep Medicine, Brigham & Women's Hospital
%                   Division of Sleep Medicine, Harvard Medical School
%   $Date:    Jun 17, 2020
%   $Modif.:  Jun 28, 2023
%                   Allow an option to collate or subdivide long files
% 
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%                      (C) Peng Li 2020 -
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% 
classdef optionWindow < handle
    properties (Access = private)
        TabGroup
        ImportTab
        SaveTab
        ComputeTab
        
        TimeSectionText
        TimeButtonGroup
        TimeFilenameButton
        TimeFilenameEdit
        TimeFileButton
        TimeFileSelect
        
        InfoText
        InfoPanel
        ImportTemperatureCheck
        
        SaveSectionText
        SavePanel
        SaveACITotalCheck
        SaveACIEvennessCheck
        SaveACIMatrixCheck
        SaveACIIntermediateCheck
        SaveEETernaryPlotCheck

        LongFileSectionText
        SubColButtonGroup
        SubdivideRadio
        SubdividePerMinuteEdit
        SubdividePerMinuteLabel
        SubdividePerMinuteUnit
        CollateRadio
        
        AsciiFormatText
        AsciiButtonG
        AsciiTabCheck
        AsciiComCheck
        
        ACISectionText
        ACIButtonGroup
        ACIAdaptButton
        ACIFixButton
        ACIFixValueEdit
        
        ImportButton
        CancelButton
    end
    
    properties
        WizardFigure
        
        % pre-read parameter order
        % {1}
        time = struct('format', {'HHmm-ddMMYYYY'}, 'value', [])
        
        % {2}
        save = struct('ACITotal', 1, ...
            'ACIEvenness', 1, ...
            'ACIMatrix', 1, ...
            'ACIIntermediate', 0, ...
            'EETernaryPlot', 0)
        
        % {3}
        asciiSep = '\t';
        
        % {4}
        compute = struct('ACIFtMax', {'adaptive'}, 'value', []);
        
        % {5}
        info = struct('Temperature', 1);

        % {6} -- added Jun 28, 2023
        colSub = struct('LongFileOpt', {'Subdivide'}, 'Per', 5);
        
        imported = 0
    end
    
    methods
        function app = optionWindow(varargin)
            createComponents(app);
            
            % load preset
            switch nargin
                case 6
                    app.time = varargin{1};
                    app.TimeFilenameEdit.Value = app.time.format;
                    
                    app.save = varargin{2};
                    app.asciiSep = varargin{3};
                    app.SaveACIIntermediateCheck.Value = app.save.ACIIntermediate;
                    app.SaveEETernaryPlotCheck.Value   = app.save.EETernaryPlot;
                    
                    if contains(app.asciiSep, '\t')
                        app.AsciiTabCheck.Value = 1;
                        app.AsciiComCheck.Value = 0;
                    else
                        app.AsciiTabCheck.Value = 0;
                        app.AsciiComCheck.Value = 1;
                    end
                    
                    app.compute = varargin{4};
                    switch app.compute.ACIFtMax
                        case 'adaptive'
                            app.ACIButtonGroup.SelectedObject = app.ACIAdaptButton;
                            app.ACIFixValueEdit.Enable = 'off';
                        case 'fixed'
                            app.ACIButtonGroup.SelectedObject = app.ACIFixButton;
                            app.ACIFixValueEdit.Enable = 'on';
                            app.ACIFixValueEdit.Value  = num2str(app.compute.value);
                    end
                    
                    app.info = varargin{5};
                    app.ImportTemperatureCheck.Value = app.info.Temperature;

                    app.colSub = varargin{6};
                    switch app.colSub.LongFileOpt
                        case 'Subdivide'
                            app.SubdivideRadio.Value = 1;
                            app.SubdividePerMinuteEdit.Value = num2str(app.colSub.Per);

                            app.SubdividePerMinuteEdit.Enable  = 'on';
                            app.SubdividePerMinuteLabel.Enable = 'on';
                            app.SubdividePerMinuteUnit.Enable  = 'on';
                        case 'Collate'
                            app.CollateRadio.Value = 1;

                            app.SubdividePerMinuteEdit.Enable  = 'off';
                            app.SubdividePerMinuteLabel.Enable = 'off';
                            app.SubdividePerMinuteUnit.Enable  = 'off';
                    end
            end
        end
    end
    
    methods (Access = private)
        function createComponents(app)
            Pos = CenterFig(350, 250, 'pixels');
            app.WizardFigure = uifigure('Color', 'w', ...
                'Units', 'pixels', 'Position', Pos, ...
                'Name', 'SonoScape Options', ...
                'NumberTitle', 'off', 'Resize', 'off');
            
            gFigure = uigridlayout(app.WizardFigure);
            gFigure.RowHeight   = repmat({'1x'}, 1, 8);
            gFigure.ColumnWidth = repmat({'1x'}, 1, 5);
            
            app.TabGroup  = uitabgroup(gFigure, ...
                'TabLocation', 'left');
            app.TabGroup.Layout.Row    = [1 length(gFigure.RowHeight)-1];
            app.TabGroup.Layout.Column = [1 5];
            
            % tab 1
            app.ImportTab  = uitab(app.TabGroup, 'Title', 'Import');
            
            % tab 2
            app.SaveTab    = uitab(app.TabGroup, 'Title', 'Save');
            
            % tab 3
            app.ComputeTab = uitab(app.TabGroup, 'Title', 'Compute');
            
            %% layout ImportTab
            gImport = uigridlayout(app.ImportTab);
            gImport.RowHeight   = repmat({'1x'}, 1, 6);
            gImport.ColumnWidth = {'fit', '2x'};
            
            % 1. section title
            app.TimeSectionText = uilabel(gImport, ...
                'Text', 'Gauge time from', 'HorizontalAlignment', 'left', ...
                'BackgroundColor', [.75 .75 .75]);
            app.TimeSectionText.Layout.Row    = 1;
            app.TimeSectionText.Layout.Column = [1 2];
            
            % 2. section content
            app.TimeButtonGroup = uibuttongroup(gImport, ...
                'SelectionChangedFcn', @(source, event) TimeBGCallback(app, source, event));
            app.TimeButtonGroup.Layout.Row    = [2 3];
            app.TimeButtonGroup.Layout.Column = [1 2];
            
            % 2.1. 
            app.TimeFilenameButton = uiradiobutton(app.TimeButtonGroup, ...
                'Text', 'Filename', ...
                'Position', [6 28 100 20]);
            app.TimeFilenameEdit   = uieditfield(app.TimeButtonGroup, ...
                'Tooltip', 'define file naming style such as YYYYMMddHHmmss', ...
                'Position', [80 28 125 20], ...
                'Value', 'HHmm-ddMMYYYY', ...
                'HorizontalAlignment', 'right', ...
                'ValueChangedFcn', @(source, event) TimeFNCallback(app, source, event));
            
            % 2.2.
            app.TimeFileButton = uiradiobutton(app.TimeButtonGroup, ...
                'Text', 'File', ...
                'Position', [6 3 100 20]);
            app.TimeFileSelect = uibutton(app.TimeButtonGroup, ...
                'Tooltip', 'select a file that contains time info for each file', ...
                'Position', [125 3 80 20], ...
                'Text', 'Select', 'Enable', 'off');
            
            % 3. section title
            app.InfoText = uilabel(gImport, ...
                'Text', 'Import file information', 'HorizontalAlignment', 'left', ...
                'BackgroundColor', [.75 .75 .75]);
            app.InfoText.Layout.Row    = app.TimeButtonGroup.Layout.Row(2) + 1;
            app.InfoText.Layout.Column = [1 2];
            
            % 4. section content
            app.InfoPanel = uipanel(gImport);
            app.InfoPanel.Layout.Row    = app.InfoText.Layout.Row + [1 2];
            app.InfoPanel.Layout.Column = [1 2];
            
            gInfoContent = uigridlayout(app.InfoPanel);
            gInfoContent.RowHeight   = repmat({'1x'}, 1, 1);
            gInfoContent.ColumnWidth = {'fit'};
            
            % 4.1 
            app.ImportTemperatureCheck = uicheckbox(gInfoContent, ...
                'Value', 1, ...
                'Text', 'Temperature', ...
                'Enable', 'on', ...
                'ValueChangedFcn', @(source, event) ImportTemperatureCallback(app, source, event));
            
            %% layout SaveTab
            gSave = uigridlayout(app.SaveTab);
            gSave.RowHeight   = gSave.Parent.Position(4)./10 .* ones(20, 1); % to make it scrollable
            gSave.ColumnWidth = {'fit', '2x'};
            gSave.Scrollable  = 'on';
            
            % 1.1 section title
            app.SaveSectionText = uilabel(gSave, ...
                'Text', 'What files to save', 'HorizontalAlignment', 'left', ...
                'BackgroundColor', [.75 .75 .75]);
            app.SaveSectionText.Layout.Row    = 1;
            app.SaveSectionText.Layout.Column = [1 2];
            
            % 1.2 section content
            app.SavePanel = uipanel(gSave);
            app.SavePanel.Layout.Row    = [2 6];
            app.SavePanel.Layout.Column = [1 2];
            
            gSaveContent = uigridlayout(app.SavePanel);
            gSaveContent.RowHeight   = repmat({'1x'}, 1, 5);
            gSaveContent.ColumnWidth = {'fit'};
            
            % 1.2.1 
            app.SaveACITotalCheck = uicheckbox(gSaveContent, ...
                'Value', 1, ...
                'Text', 'ACI total vectors', ...
                'Enable', 'off');
            app.SaveACIEvennessCheck = uicheckbox(gSaveContent, ...
                'Value', 1, ...
                'Text', 'ACI evenness vectors', ...
                'Enable', 'off');
            app.SaveACIMatrixCheck = uicheckbox(gSaveContent, ...
                'Value', 1, ...
                'Text', 'ACI matrix', ...
                'Enable', 'off');
            app.SaveACIIntermediateCheck = uicheckbox(gSaveContent, ...
                'Value', 0, ...
                'Text', 'FFT matrix', ...
                'ValueChangedFcn', @(source, event) SaveACIIterCallback(app, source, event));
            app.SaveEETernaryPlotCheck = uicheckbox(gSaveContent, ...
                'Value', 0, ...
                'Text', 'EE ternary plot', ...
                'ValueChangedFcn', @(source, event) SaveEETernaryCallback(app, source, event));
            
            % 2.1 section title
            app.LongFileSectionText = uilabel(gSave, ...
                'Text', 'Operating long files', 'HorizontalAlignment', 'left', ...
                'BackgroundColor', [.75 .75 .75]);
            app.LongFileSectionText.Layout.Row    = app.SavePanel.Layout.Row(2) + 1;
            app.LongFileSectionText.Layout.Column = [1 2];
            
            % 2.2 section content
            app.SubColButtonGroup = uibuttongroup(gSave, ...
                'SelectionChangedFcn', @(source, event) SubColBGCallback(app, source, event));
            app.SubColButtonGroup.Layout.Row    = app.LongFileSectionText.Layout.Row + [1 2];
            app.SubColButtonGroup.Layout.Column = [1 2];
            
            % 2.2.1 
            app.SubdivideRadio = uiradiobutton(app.SubColButtonGroup, ...
                'Text', 'To subdivide');
            app.SubdivideRadio.Position = app.SubdivideRadio.Position + [0 15 0 0];

            app.SubdividePerMinuteEdit = uieditfield(app.SubColButtonGroup, ...
                'Tooltip', 'define segment length in the unit of minute', ...
                'Position', [80 3 30 20], ...
                'Value', '5', ...
                'HorizontalAlignment', 'right', ...
                'ValueChangedFcn', @(source, event) SubdividePerCallback(app, source, event));
            p = app.SubdividePerMinuteEdit.Position;
            p(2) = app.SubdivideRadio.Position(2)+2;
            p(1) = app.SubdivideRadio.Position(3) + 40;
            app.SubdividePerMinuteEdit.Position = p;

            app.SubdividePerMinuteLabel = uilabel(app.SubColButtonGroup, ...
                'Text', 'Per', ...
                'HorizontalAlignment', 'right');
            p = [app.SubdivideRadio.Position(3) + 15 app.SubdivideRadio.Position(2)+2 20 20];
            app.SubdividePerMinuteLabel.Position = p;

            app.SubdividePerMinuteUnit = uilabel(app.SubColButtonGroup, ...
                'Text', 'Min.', ...
                'HorizontalAlignment', 'left');
            p = [app.SubdivideRadio.Position(3) + 75 app.SubdivideRadio.Position(2)+2 40 20];
            app.SubdividePerMinuteUnit.Position = p;
            
            % 2.2.2
            app.CollateRadio = uiradiobutton(app.SubColButtonGroup, ...
                'Text', 'To collate');
            app.CollateRadio.Position = app.CollateRadio.Position - [0 5 0 0];

            % 3.1 section title
            app.AsciiFormatText = uilabel(gSave, ...
                'Text', 'ASCII file seperator', 'HorizontalAlignment', 'left', ...
                'BackgroundColor', [.75 .75 .75]);
            app.AsciiFormatText.Layout.Row    = app.SubColButtonGroup.Layout.Row(2) + 1;
            app.AsciiFormatText.Layout.Column = [1 2];
            
            % 3.2 section content
            app.AsciiButtonG  = uibuttongroup(gSave, ...
                'SelectionChangedFcn', @(source, event) AsciiButtonGSelectChgCallback(app, source, event));
            app.AsciiButtonG.Layout.Row = app.AsciiFormatText.Layout.Row + [1 2];
            app.AsciiButtonG.Layout.Column = [1 2];
            
            app.AsciiTabCheck = uiradiobutton(app.AsciiButtonG, ...
                'Value', 1, ...
                'Text', 'tab (\t)');
            app.AsciiTabCheck.Position = app.AsciiTabCheck.Position + [0 15 0 0];
            app.AsciiComCheck = uiradiobutton(app.AsciiButtonG, ...
                'Value', 0, ...
                'Text', 'comma (,)');
            app.AsciiComCheck.Position = app.AsciiComCheck.Position - [0 5 0 0];
            
            %% layout ComputeTab
            gCompute = uigridlayout(app.ComputeTab);
            gCompute.RowHeight   = repmat({'1x'}, 1, 6);
            gCompute.ColumnWidth = {'fit', '2x'};
            
            % 1. section title
            app.ACISectionText = uilabel(gCompute, ...
                'Text', 'Acoustic complexity index (ACI) Ft Max', 'HorizontalAlignment', 'left', ...
                'BackgroundColor', [.75 .75 .75]);
            app.ACISectionText.Layout.Row    = 1;
            app.ACISectionText.Layout.Column = [1 2];
            
            % 2. section content
            app.ACIButtonGroup = uibuttongroup(gCompute, ...
                'SelectionChangedFcn', @(source, event) ACIBGCallback(app, source, event));
            app.ACIButtonGroup.Layout.Row    = [2 3];
            app.ACIButtonGroup.Layout.Column = [1 2];
            
            % 2.1. 
            app.ACIAdaptButton = uiradiobutton(app.ACIButtonGroup, ...
                'Text', 'Adaptive', ...
                'Position', [6 28 100 20]);
            
            % 2.2.
            app.ACIFixButton = uiradiobutton(app.ACIButtonGroup, ...
                'Text', 'Fixed', ...
                'Position', [6 3 100 20]);
            app.ACIFixValueEdit = uieditfield(app.ACIButtonGroup, ...
                'Tooltip', 'type in a single value for ACIFtMax at timescale 1 sec', ...
                'Position', [80 3 125 20], ...
                'Value', '7000', ...
                'HorizontalAlignment', 'right', ...
                'ValueChangedFcn', @(source, event) ACIFVCallback(app, source, event), ...
                'Enable', 'off');
            
            %% return
            % confirm
            app.ImportButton = uibutton(gFigure, 'Text', 'OK', ...
                'ButtonPushedFcn', @(source, event) ImportButtonCallback(app, source, event));
            app.ImportButton.Layout.Row    = length(gFigure.RowHeight);
            app.ImportButton.Layout.Column = 4;
            
            % cancel
            app.CancelButton = uibutton(gFigure, 'Text', 'Cancel', ...
                'ButtonPushedFcn', @(source, event) CancelButtonCallback(app, source, event));
            app.CancelButton.Layout.Row    = length(gFigure.RowHeight);
            app.CancelButton.Layout.Column = 5;
        end
    end
    
    methods
        function TimeBGCallback(app, source, event)
            switch event.NewValue.Text
                case 'File'
                    app.TimeFilenameEdit.Enable = 'off';
                    app.TimeFileSelect.Enable = 'on';
                case 'Filename'
                    app.TimeFilenameEdit.Enable = 'on';
                    app.TimeFileSelect.Enable = 'off';
            end
        end
        
        function TimeFNCallback(app, source, event)
            app.time.format = event.Value;
        end
        
        function SaveACIIterCallback(app, source, event)
            app.save.ACIIntermediate = event.Value;
        end
        
        function SaveEETernaryCallback(app, source, event)
            app.save.EETernaryPlot = event.Value;
        end
        
        function ImportTemperatureCallback(app, source, event)
            app.info.Temperature = event.Value;
        end

        function SubColBGCallback(app, source, event)
            if contains(event.NewValue.Text, 'subdivide')
                app.SubdividePerMinuteEdit.Enable  = 'on';
                app.SubdividePerMinuteLabel.Enable = 'on';
                app.SubdividePerMinuteUnit.Enable  = 'on';
                app.SubdividePerMinuteEdit.Value   = '5';

                app.colSub.LongFileOpt = 'Subdivide';
                app.colSub.Per = 5;
            else
                app.SubdividePerMinuteEdit.Enable  = 'off';
                app.SubdividePerMinuteLabel.Enable = 'off';
                app.SubdividePerMinuteUnit.Enable  = 'off';

                app.colSub.LongFileOpt = 'Collate';
            end
        end

        function SubdividePerCallback(app, source, event)
            app.colSub.Per = str2double(event.Value);
        end
        
        function AsciiButtonGSelectChgCallback(app, source, event)
            if contains(event.NewValue.Text, 'comma')
                app.asciiSep = ',';
            elseif contains(event.NewValue.Text, 'tab')
                app.asciiSep = '\t';
            end
        end
        
        function ACIBGCallback(app, source, event)
            switch event.NewValue.Text
                case 'Adaptive'
                    app.ACIFixValueEdit.Enable = 'off';
                    app.compute.ACIFtMax = 'adaptive';
                case 'Fixed'
                    app.ACIFixValueEdit.Enable = 'on';
                    app.compute.ACIFtMax = 'fixed';
                    app.compute.value = 7000;
            end
        end
        
        function ACIFVCallback(app, source, event)
            app.compute.value = eval(event.Value);
        end
        
        function app = ImportButtonCallback(app, source, event)
            app.imported = 1;
            
            timeConf     = app.time;
            saveConf     = app.save;
            asciiSepConf = app.asciiSep;
            computeConf  = app.compute;
            infoConf     = app.info;
            colSubConf   = app.colSub;
            save('scConfig.mat', 'timeConf', 'saveConf', 'asciiSepConf', 'computeConf', 'infoConf', 'colSubConf'); %#ok
            
            closereq;
        end
        
        function app = CancelButtonCallback(app, source, event)
            app.imported = 0;
            closereq;
        end
    end
end