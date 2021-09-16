% install App from packaged app source code
% 
% $Author:  Peng Li
% $Date:    Dec 30, 2019
% $Modif.:  Feb 02, 2021
%               removing old paths if exist (from search path and
%               physically)
%           May 17, 2021
%               update to tolerate other OS
% 

clc; clear; close all;

%% define production
Production = 'SonoScape';
Version    = '1.1.0719';

%% uninstall first
if ispc
    allPath = strsplit(path, ';');
else
    allPath = strsplit(path, ':');
end
oldPath = contains(allPath, Production);

if any(oldPath)
    disp('removing old files ...')
    path2Rm = allPath(oldPath);
    for iP  = numel(path2Rm):-1:1
        rmpath(path2Rm{iP});
        rmdir(path2Rm{iP}, 's');
        disp([path2Rm{iP} ' removed!']);
    end
end

%% unzip
disp('unzipping package ...');
unzip([Production '_' Version '.zip']);

disp('installing app ...');
curPt = fullfile(cd, [Production '_' Version]);
addpath(curPt); savepath;

subPt = dir(curPt);
for iS = 3:length(subPt)
    if subPt(iS).isdir
        addpath(fullfile(curPt, subPt(iS).name)); savepath
    end
end

disp('installation finished!');