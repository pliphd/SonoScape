% Option
% 
% Descriptions tba
% 
%   $Author:  Peng Li, Ph.D.
%                   Division of Sleep Medicine, Brigham & Women's Hospital
%                   Division of Sleep Medicine, Harvard Medical School
%   $Date:    Jun 17, 2020
% 
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%                      (C) Peng Li 2020 -
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% 
classdef optionWindow < handle
    properties (Access = private)
        WizardFigure
        TabGroup
        ImportTab
        SaveTab
        
        TimeSectionText
        TimeButtonGroup
        TimeFilenameButton
        TimeFilenameEdit
        TimeFileButton
        TimeFileSelect
        
        SaveSectionText
        SavePanel
        SaveACITotalCheck
        SaveACIEvennessCheck
        SaveACIIntermediateCheck
        
        ImportButton
        CancelButton
    end
    
    properties
        time = struct('format', {'HHmm-ddMMYYYY'}, 'value', [])
        save = struct('ACITotal', 1, 'ACIEvenness', 1, 'ACIIntermediate', 0)
        imported = 0
    end
    
    methods
        function app = optionWindow
            createComponents(app);
        end
    end
    
    methods (Access = private)
        function createComponents(app)
            Pos = CenterFig(350, 250, 'pixels');
            app.WizardFigure = uifigure('Color', 'w', ...
                'Units', 'pixels', 'Position', Pos, ...
                'Name', 'Soundscape Options', ...
                'NumberTitle', 'off', 'Resize', 'off');
            
            gFigure = uigridlayout(app.WizardFigure);
            gFigure.RowHeight   = repmat({'1x'}, 1, 8);
            gFigure.ColumnWidth = repmat({'1x'}, 1, 5);
            
            app.TabGroup  = uitabgroup(gFigure, ...
                'TabLocation', 'left');
            app.TabGroup.Layout.Row    = [1 length(gFigure.RowHeight)-1];
            app.TabGroup.Layout.Column = [1 5];
            app.ImportTab = uitab(app.TabGroup, 'Title', 'Import');
            app.SaveTab   = uitab(app.TabGroup, 'Title', 'Save');
            
            % layout ImportTab
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
                'Text', 'Select');
            
            % layout SaveTab
            gSave = uigridlayout(app.SaveTab);
            gSave.RowHeight   = repmat({'1x'}, 1, 6);
            gSave.ColumnWidth = {'fit', '2x'};
            
            % 1. section title
            app.SaveSectionText = uilabel(gSave, ...
                'Text', 'What files to save', 'HorizontalAlignment', 'left', ...
                'BackgroundColor', [.75 .75 .75]);
            app.SaveSectionText.Layout.Row    = 1;
            app.SaveSectionText.Layout.Column = [1 2];
            
            % 2. section content
            app.SavePanel = uipanel(gSave);
            app.SavePanel.Layout.Row    = [2 6];
            app.SavePanel.Layout.Column = [1 2];
            
            gSaveContent = uigridlayout(app.SavePanel);
            gSaveContent.RowHeight   = repmat({'1x'}, 1, 5);
            gSaveContent.ColumnWidth = {'fit'};
            
            % 2.1 
            app.SaveACITotalCheck = uicheckbox(gSaveContent, ...
                'Value', 1, ...
                'Text', 'ACI total vectors', ...
                'Enable', 'off');
            app.SaveACIEvennessCheck = uicheckbox(gSaveContent, ...
                'Value', 1, ...
                'Text', 'ACI evenness vectors', ...
                'Enable', 'off');
            app.SaveACIIntermediateCheck = uicheckbox(gSaveContent, ...
                'Value', 0, ...
                'Text', 'FFT matrix and ACI matrix', ...
                'ValueChangedFcn', @(source, event) SaveACIIterCallback(app, source, event));
            
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
        
        function app = ImportButtonCallback(app, source, event)
            app.imported = 1;
            closereq;
        end
        
        function app = CancelButtonCallback(app, source, event)
            app.imported = 0;
            closereq;
        end
    end
end