function [datetimestr, format] = parsetime(str, format)
% PARSETIME parse date time from string using format
% 
% $Author: Peng Li
% $Date:   Apr. 5, 2021
% 

ind = strfind(format, '*');

if numel(ind) == 1
    if ind == 1
        datetimestr = str(end-length(format)+1+1:end);
    else
        datetimestr = str(1:ind-1);
    end
else
    datetimestr = str(setxor(1:length(str), ind));
end

format = format(setxor(1:length(format), ind));
end