function htmlOut = profview(functionName, profInfo)
%PROFVIEW   Display HTML profiler interface
%   This function is unsupported and might change or be removed without
%   notice in a future version.
%
%   PROFVIEW(FUNCTIONNAME, PROFILEINFO)
%   FUNCTIONNAME can be either a name or an index number into the profile.
%   PROFILEINFO is the profile stats structure as returned by
%   PROFILEINFO = PROFILE('INFO').
%   If the FUNCTIONNAME argument passed in is zero, then profview displays
%   the profile summary page.
%
%   The output for PROFVIEW is an HTML file in the Profiler window. The
%   file listing at the bottom of the function profile page shows four
%   columns to the left of each line of code.
%   * Column 1 (red) is total time spent on the line in seconds.
%   * Column 2 (blue) is number of calls to that line.
%   * Column 3 is the line number
%
%   See also PROFILE.

%   Copyright 1984-2014 The MathWorks, Inc.


persistent profileInfo
% Three possibilities:
% 1) profile info wasn't passed and hasn't been created yet
% 2) profile info wasn't passed in but is persistent
% 3) profile info was passed in

import com.mathworks.mde.profiler.Profiler;

if (nargin < 2) || isempty(profInfo),
    if isempty(profileInfo),
        % 1) profile info wasn't passed and hasn't been created yet
        profile('viewer');
        return
    else
        % 2) profile info wasn't passed in but is persistent
        % No action. profileInfo was created in a previous call to this function
    end
else
    % 3) profile info was passed in
    profileInfo = profInfo;
    Profiler.stop;
end

if nargin < 1,
    % If there's no input argument, just provide the summary
    functionName = 0;
end

% Find the function in the supplied data structure
% functionName can be either a name or an index number
if ischar(functionName),
    functionNameList = {profileInfo.FunctionTable.FunctionName};
    idx = find(strcmp(functionNameList,functionName)==1);
    if isempty(idx)
        error(message('MATLAB:profiler:FunctionNotFound', functionName))
    end
else
    idx = functionName;
end

% Create all the HTML for the page
if idx==0
    s = makesummarypage(profileInfo);
else
    busyLineSortKey = getpref('profiler','busyLineSortKey','time');
    s = makefilepage(profileInfo,idx, busyLineSortKeyStr2Num(busyLineSortKey));
end

sOut = [s{:}];

if nargout==0
    Profiler.setHtmlText(sOut);
else
    htmlOut = sOut;
end


function s = makesummarypage(profileInfo)
% --------------------------------------------------
% Show the main summary page
% --------------------------------------------------

% pixel gif location
fs = filesep;
pixelPath = ['file:///' matlabroot fs 'toolbox' fs 'matlab' fs 'codetools' fs 'private' fs];
cyanPixelGif = [pixelPath 'one-pixel-cyan.gif'];
bluePixelGif = [pixelPath 'one-pixel.gif'];

% Read in preferences
sortMode = getpref('profiler','sortMode','totaltime');

allTimes = [profileInfo.FunctionTable.TotalTime];
maxTime = max(allTimes);

% check if there is any memory data in the profile info
hasMem = hasMemoryData(profileInfo);

% check if there is any hardware performance counter data in the profile info
hwFields = getHwFields(profileInfo);
hasHw = (~isempty(hwFields));

% Calculate self time and optionally self memory and self performance counter list
allSelfTimes = zeros(size(allTimes));
if hasMem
    allSelfMem = zeros(size(allTimes));
end
for i = 1:length(profileInfo.FunctionTable)
    allSelfTimes(i) = profileInfo.FunctionTable(i).TotalTime - ...
        sum([profileInfo.FunctionTable(i).Children.TotalTime]);
    if hasMem
        netMem = (profileInfo.FunctionTable(i).TotalMemAllocated - ...
            profileInfo.FunctionTable(i).TotalMemFreed);
        childNetMem = (sum([profileInfo.FunctionTable(i).Children.TotalMemAllocated]) - ...
            sum([profileInfo.FunctionTable(i).Children.TotalMemFreed]));
        allSelfMem(i) = netMem - childNetMem;
    end
    for j=1:length(hwFields)
        child_hw = sum([profileInfo.FunctionTable(i).Children.(hwFields{j})]);
        allHw{j}(i) = profileInfo.FunctionTable(i).(hwFields{j});
        allSelfHw{j}(i) = allHw{j}(i) - child_hw;
    end
end

totalTimeFontWeight = 'normal';
selfTimeFontWeight = 'normal';
alphaFontWeight = 'normal';
numCallsFontWeight = 'normal';
allocMemFontWeight = 'normal';
freeMemFontWeight = 'normal';
peakMemFontWeight = 'normal';
selfMemFontWeight = 'normal';

% hwFontWeight(i) is for total data
% hwFontWeight(i+length(hwFields)) is for self data
for j=1:2*length(hwFields)
    hwFontWeight{j} = 'normal';
end

% if the sort mode is set to a memory field but we don't have
% any memory data, we need to switch back to time.
if ~hasMem && (strcmp(sortMode, 'allocmem') || ...
        strcmp(sortMode, 'freedmem') || ...
        strcmp(sortMode, 'peakmem')  || ...
        strcmp(sortMode, 'selfmem'))
    sortMode = 'totaltime';
end

badSortMode = false;
if strcmp(sortMode,'totaltime')
    totalTimeFontWeight = 'bold';
    [~,sortIndex] = sort(allTimes,'descend');
elseif strcmp(sortMode,'selftime')
    selfTimeFontWeight = 'bold';
    [~,sortIndex] = sort(allSelfTimes,'descend');
elseif strcmp(sortMode,'alpha')
    alphaFontWeight = 'bold';
    allFunctionNames = {profileInfo.FunctionTable.FunctionName};
    [~,sortIndex] = sort(allFunctionNames);
elseif strcmp(sortMode,'numcalls')
    numCallsFontWeight = 'bold';
    [~,sortIndex] = sort([profileInfo.FunctionTable.NumCalls],'descend');
elseif strcmp(sortMode,'allocmem')
    allocMemFontWeight = 'bold';
    [~,sortIndex] = sort([profileInfo.FunctionTable.TotalMemAllocated],'descend');
elseif strcmp(sortMode,'freedmem')
    freeMemFontWeight = 'bold';
    [~,sortIndex] = sort([profileInfo.FunctionTable.TotalMemFreed],'descend');
elseif strcmp(sortMode,'peakmem')
    peakMemFontWeight = 'bold';
    [~,sortIndex] = sort([profileInfo.FunctionTable.PeakMem],'descend');
elseif strcmp(sortMode,'selfmem')
    selfMemFontWeight = 'bold';
    [~,sortIndex] = sort(allSelfMem,'descend');
elseif strncmp('total_',sortMode,6)
    % check if sort mode is for hardware performance counter
    match = strcmpi(sortMode(7:end), hwFields);
    if any(match)
        idx = 1:length(hwFields);
        j = idx(match);
        hwFontWeight{j} = 'bold';
        [~,sortIndex] = sort(allHw{j},'descend');
    else
        badSortMode = true;
    end
elseif strncmp('self_',sortMode,5)
    % check if sort mode is for hardware performance counter
    match = strcmpi(sortMode(6:end),hwFields);
    if any(match)
        idx = 1:length(hwFields);
        j = idx(match);
        hwFontWeight{j+length(hwFields)} = 'bold';
        [~,sortIndex] = sort(allSelfHw{j},'descend');
    else
        badSortMode = true;
    end
end

if badSortMode
    error(message('MATLAB:profiler:BadSortMode', sortMode));
end

s = {}; %#ok<*AGROW>
s{1} = makeheadhtml;
s{end+1} = ['<title>', getString(message('MATLAB:profiler:ProfileSummaryName')), '</title>'];
cssfile = which('matlab-report-styles.css');
s{end+1} = sprintf('<link rel="stylesheet" href="file:///%s" type="text/css" />',cssfile);
s{end+1} = '</head>';
s{end+1} = '<body>';

% Summary info

status = profile('status');
s{end+1} = ['<span style="font-size: 14pt; background: #FFE4B0">', getString(message('MATLAB:profiler:ProfileSummaryName')), '</span><br/>'];
s{end+1} = ['<i>', getString(message('MATLAB:profiler:GeneratedUsing', datestr(now), status.Timer)), '</i><br/>'];

if isempty(profileInfo.FunctionTable)
    s{end+1} = ['<p><span style="color:#F00">', getString(message('MATLAB:profiler:NoProfileInfo')), '</span><br/>'];
    s{end+1} = [getString(message('MATLAB:profiler:NoteAboutBuiltins')), '<p>'];
end

s{end+1} = '<table border=0 cellspacing=0 cellpadding=6>';
s{end+1} = '<tr>';
s{end+1} = '<td class="td-linebottomrt" bgcolor="#F0F0F0" valign="top">';
s{end+1} = '<a href="matlab: setpref(''profiler'',''sortMode'',''alpha'');profview(0)">';
s{end+1} = sprintf(['<span style="font-weight:%s">', getString(message('MATLAB:profiler:FunctionNameTableElement')) , '</span></a></td>'],alphaFontWeight);
s{end+1} = '<td class="td-linebottomrt" bgcolor="#F0F0F0" valign="top">';
s{end+1} = '<a href="matlab: setpref(''profiler'',''sortMode'',''numcalls'');profview(0)">';
s{end+1} = sprintf(['<span style="font-weight:%s">', getString(message('MATLAB:profiler:CallsTableElement')), '</span></a></td>'],numCallsFontWeight);
s{end+1} = '<td class="td-linebottomrt" bgcolor="#F0F0F0" valign="top">';
s{end+1} = '<a href="matlab: setpref(''profiler'',''sortMode'',''totaltime'');profview(0)">';
s{end+1} = sprintf(['<span style="font-weight:%s">', getString(message('MATLAB:profiler:TotalTimeTableElement')), '</span></a></td>'],totalTimeFontWeight);
s{end+1} = '<td class="td-linebottomrt" bgcolor="#F0F0F0" valign="top">';
s{end+1} = '<a href="matlab: setpref(''profiler'',''sortMode'',''selftime'');profview(0)">';
s{end+1} = sprintf(['<span style="font-weight:%s">', getString(message('MATLAB:profiler:SelfTimeTableElement')), '</span></a>*</td>'],selfTimeFontWeight);

% Add column headings for memory data.
if hasMem
    s{end+1} = '<td class="td-linebottomrt" bgcolor="#F0F0F0" valign="top">';
    s{end+1} = '<a href="matlab: setpref(''profiler'',''sortMode'',''allocmem'');profview(0)">';
    s{end+1} = sprintf(['<span style="font-weight:%s">', getString(message('MATLAB:profiler:AllocatedMemoryTableElement')), '</span></a></td>'],allocMemFontWeight);
    
    s{end+1} = '<td class="td-linebottomrt" bgcolor="#F0F0F0" valign="top">';
    s{end+1} = '<a href="matlab: setpref(''profiler'',''sortMode'',''freedmem'');profview(0)">';
    s{end+1} = sprintf(['<span style="font-weight:%s">', getString(message('MATLAB:profiler:FreedMemoryTableElement')), '</span></a></td>'],freeMemFontWeight);
    
    s{end+1} = '<td class="td-linebottomrt" bgcolor="#F0F0F0" valign="top">';
    s{end+1} = '<a href="matlab: setpref(''profiler'',''sortMode'',''selfmem'');profview(0)">';
    s{end+1} = sprintf(['<span style="font-weight:%s">', getString(message('MATLAB:profiler:SelfMemoryTableElement')), '</span></a></td>'],selfMemFontWeight);
    
    s{end+1} = '<td class="td-linebottomrt" bgcolor="#F0F0F0" valign="top">';
    s{end+1} = '<a href="matlab: setpref(''profiler'',''sortMode'',''peakmem'');profview(0)">';
    s{end+1} = sprintf(['<span style="font-weight:%s">', getString(message('MATLAB:profiler:PeakMemoryTableElement')), '</span></a></td>'],peakMemFontWeight);
end

% Add column headings for hardware performance counter data.
for j=1:length(hwFields)
    s{end+1} = '<td class="td-linebottomrt" bgcolor="#F0F0F0" valign="top">';
    s{end+1} = sprintf('<a href="matlab: setpref(''profiler'',''sortMode'',''total_%s'');profview(0)">', lower(hwFields{j}));
    s{end+1} = sprintf(['<span style="font-weight:%s">', getString(message('MATLAB:profiler:TotalTableElement',  hwFields{j}(4:end))), '</span></a></td>'], hwFontWeight{j});
    
    s{end+1} = '<td class="td-linebottomrt" bgcolor="#F0F0F0" valign="top">';
    s{end+1} = sprintf('<a href="matlab: setpref(''profiler'',''sortMode'',''self_%s'');profview(0)">', lower(hwFields{j}));
    s{end+1} = sprintf(['<span style="font-weight:%s">', getString(message('MATLAB:profiler:SelfTableElement', hwFields{j}(4:end))) ,'</span></a></td>'], hwFontWeight{j+length(hwFields)});
end

s{end+1} = ['<td class="td-linebottomrt" bgcolor="#F0F0F0" valign="top">', getString(message('MATLAB:profiler:TotalTimePlotTableElement')), '<br/>'];
s{end+1} = [getString(message('MATLAB:profiler:DarkBandSelfTime')), '</td>'];
s{end+1} = '</tr>';

for i = 1:length(profileInfo.FunctionTable),
    n = sortIndex(i);
    
    name = profileInfo.FunctionTable(n).FunctionName;
    
    s{end+1} = '<tr>';
    
    % Truncate the name if it gets too long
    displayFunctionName = truncateDisplayName(name, 40);
    
    s{end+1} = sprintf('<td class="td-linebottomrt"><a href="matlab: profview(%d);">%s</a>', ...
        n, displayFunctionName);
    
    if isempty(regexp(profileInfo.FunctionTable(n).Type,'^M-','once'))
        s{end+1} = sprintf(' (%s)</td>', ...
            typeToDisplayValue(profileInfo.FunctionTable(n).Type));
    else
        s{end+1} = '</td>';
    end
    
    s{end+1} = sprintf('<td class="td-linebottomrt">%d</td>', ...
        profileInfo.FunctionTable(n).NumCalls);
    
    
    % Don't display the time if it's zero
    if profileInfo.FunctionTable(n).TotalTime > 0,
        s{end+1} = sprintf('<td class="td-linebottomrt">%4.3f s</td>', ...
            profileInfo.FunctionTable(n).TotalTime);
    else
        s{end+1} = '<td class="td-linebottomrt">0 s</td>';
    end
    
    if maxTime > 0,
        timeRatio = profileInfo.FunctionTable(n).TotalTime/maxTime;
        selfTime = profileInfo.FunctionTable(n).TotalTime - sum([profileInfo.FunctionTable(n).Children.TotalTime]);
        selfTimeRatio = selfTime/maxTime;
    else
        timeRatio = 0;
        selfTime = 0;
        selfTimeRatio = 0;
    end
    
    s{end+1} = sprintf('<td class="td-linebottomrt">%4.3f s</td>',selfTime);
    
    % Add column data for memory
    if hasMem
        % display alloc, freed, self and peak mem on summary page
        totalAlloc = profileInfo.FunctionTable(n).TotalMemAllocated;
        totalFreed = profileInfo.FunctionTable(n).TotalMemFreed;
        netMem = totalAlloc - totalFreed;
        childAlloc = sum([profileInfo.FunctionTable(n).Children.TotalMemAllocated]);
        childFreed = sum([profileInfo.FunctionTable(n).Children.TotalMemFreed]);
        childMem = childAlloc - childFreed;
        selfMem = netMem - childMem;
        peakMem = profileInfo.FunctionTable(n).PeakMem;
        s{end+1} = sprintf('<td class="td-linebottomrt">%s</td>',formatData(2,totalAlloc));
        s{end+1} = sprintf('<td class="td-linebottomrt">%s</td>',formatData(2,totalFreed));
        s{end+1} = sprintf('<td class="td-linebottomrt">%s</td>',formatData(2,selfMem));
        s{end+1} = sprintf('<td class="td-linebottomrt">%s</td>',formatData(2,peakMem));
    end
    
    % Add column data for hardware performance counters
    for j=1:length(hwFields)
        total = profileInfo.FunctionTable(n).(hwFields{j});
        child_total = sum([profileInfo.FunctionTable(n).Children.(hwFields{j})]);
        s{end+1} = sprintf('<td class="td-linebottomrt">%s</td>',formatData(3,total));
        s{end+1} = sprintf('<td class="td-linebottomrt">%s</td>',formatData(3,total-child_total));
    end
    
    s{end+1} = sprintf('<td class="td-linebottomrt"><img src="%s" width=%d height=10><img src="%s" width=%d height=10></td>', ...
        bluePixelGif, round(100*selfTimeRatio), ...
        cyanPixelGif, round(100*(timeRatio-selfTimeRatio)));
    
    s{end+1} = '</tr>';
end
s{end+1} = '</table>';

if profileInfo.Overhead==0
    s{end+1} = sprintf(['<p><a name="selftimedef"></a>', getString(message('MATLAB:profiler:SelfTime1st')) ' ']);
else
    s{end+1} = sprintf(['<p><a name="selftimedef"></a>', getString(message('MATLAB:profiler:SelfTime2nd', profileInfo.Overhead))]);
end
s{end+1} = '</body>';

s{end+1} = '</html>';



% --------------------------------------------------
% Show the function details page
% --------------------------------------------------
function s = makefilepage(profileInfo,idx,key_data_field)
% profileInfo - the profiling data structure from callstats
% idx - index of the function to generate details for
% key_data_field - an integer representing which type of
%                  collected data to sort the details by.
%                  this controls what lines are displayed
%                  as the top 5 busy lines.
%   1 - sort by time
%   2 - sort by allocated memory
%   3 - sort by freed memory
%   4 - sort by peak memory
%   5+ - sort by HW event data

ftItem = profileInfo.FunctionTable(idx);
hasMem = hasMemoryData(ftItem);
hwFields = getHwFields(ftItem);
hasHw = ~isempty(hwFields);

% Select the column order and unit strings depending on the
% sort type.
%
% The field_order controls how the columns of time and memory
% are laid out left to right.  Each entry in the field order
% vector corresponds to the key_data_field for that item.
% The first entry in the field order is always the item we are
% currently sorting on.
%
% The key_unit and key_unit_up variables are used to parameterize
% the values of some strings depending on what we a
%
if ~hasMem && ~hasHw
    % if we have no memory or HW data, default to time
    key_data_field = 1;
    field_order = 1;
    key_unit = 'time';
    key_unit_up = getString(message('MATLAB:profiler:Time1'));
else
    num_fields = 1 + length(hwFields);
    last = 1;
    if hasMem
        num_fields = num_fields + 3;
        last = 4;
    end
    field_order = 1:num_fields;
    if key_data_field == 1
        key_unit = 'time';
        key_unit_up = getString(message('MATLAB:profiler:Time1'));
    elseif hasMem && key_data_field <= 4
        % if we have memory data, reorder the first 4 fields
        % keeping the memory data grouped together.
        switch(key_data_field)
            case 2
                field_order(1:4) = [2 3 4 1];
                key_unit = 'allocated memory';
                key_unit_up = getString(message('MATLAB:profiler:AllocatedMemoryTableElement'));
            case 3
                field_order(1:4) = [3 4 2 1];
                key_unit = 'freed memory';
                key_unit_up = getString(message('MATLAB:profiler:FreedMemoryTableElement'));
            case 4
                field_order(1:4) = [4 2 3 1];
                key_unit = 'peak memory';
                key_unit_up = getString(message('MATLAB:profiler:PeakMemoryTableElement'));
        end
    else
        % if we have HW data then move the selected column to the front.
        % leave everything else in its original order.
        if(key_data_field <= num_fields)
            field_order(key_data_field) = [];
            field_order = [key_data_field field_order];
            key_unit_up = hwFields{key_data_field-last}(4:end);
            key_unit = lower(key_unit_up);
        else
            error(message('MATLAB:profiler:BadSortKey', key_data_field));
        end
    end
end

% pixel gif location
bluePixelGif = ['file:///' which('one-pixel.gif')];

% totalData holds all the totals for each type of data (time & memory & hw counters)
% for the current function.  It is indexed by key_data_field or entries
% in field_order.
totalData(1) = ftItem.TotalTime;
last = 1;
if hasMem
    totalData(2) = ftItem.TotalMemAllocated;
    totalData(3) = ftItem.TotalMemFreed;
    totalData(4) = ftItem.PeakMem;
    last = 4;
end
for j=1:length(hwFields)
    totalData(j+last) = ftItem.(hwFields{j});
end

% Build up function name target list from the children table
targetHash = [];
for n = 1:length(ftItem.Children)
    targetName = profileInfo.FunctionTable(ftItem.Children(n).Index).FunctionName;
    % Don't link to Opaque-functions with dots in the name
    if ~any(targetName=='.') && ~any(targetName=='@')
        % Build a hashtable for the target strings
        % Ensure that targetName is a legal MATLAB identifier.
        targetName = regexprep(targetName,'^([a-z_A-Z0-9]*[^a-z_A-Z0-9])+','');
        if ~isempty(targetName) && targetName(1) ~= '_'
            targetHash.(targetName) = ftItem.Children(n).Index;
        end
    end
end

% MATLAB code files are the only files we can list.
mFileFlag = 1;
pFileFlag = 0;
filteredFileFlag = false;
if (isempty(regexp(ftItem.Type,'^M-','once')) || ...
        strcmp(ftItem.Type,'M-anonymous-function') || ...
        isempty(ftItem.FileName))
    mFileFlag = 0;
else
    % Make sure it's not a P-file
    if ~isempty(regexp(ftItem.FileName,'\.p$','once'))
        pFileFlag = 1;
        pFullName = ftItem.FileName;
        
        % Replace ".p" string with ".m" string.
        fullName = regexprep(ftItem.FileName,'\.p$','.m');
        
        %g1004325 - if the m file is newer than the p file we know it is
        %out of sync, treat it as if the m file isn't there.
        mTimeDir = dir(fullName);
        pTimeDir = dir(pFullName);
        
        % Check if mfile doesn't exist or mfile is newer than the pfile 
        % (out of sync), then treat it as if the m file isn't there.
        if isempty(mTimeDir) || mTimeDir.datenum > pTimeDir.datenum
            mFileFlag = 0;
        end
    else
        fullName = ftItem.FileName;
    end
    % g894021 - Make sure the MATLAB code file still exists
    if ~exist(fullName, 'file')
        mFileFlag = 0;
    end
end

badListingDisplayMode = false;
if mFileFlag
    f = getmcode(fullName);
    
    if isempty(ftItem.ExecutedLines) && ftItem.NumCalls > 0
        % If the executed lines array is empty but the number of calls
        % is not 0 then the body of this function must have been filtered
        % for some reason.  We do not want to display the MATLAB code in this
        % case.
        f = [];
        filteredFileFlag = true;
    elseif length(f) < ftItem.ExecutedLines(end,1)
        % This is a simple (non-comprehensive) test to see if the file has been
        % altered since it was profiled. The variable f contains every line of
        % the file, and ExecutedLines points to those line numbers. If
        % ExecutedLines points to lines outside that range, something is wrong.
        badListingDisplayMode = true;
    end
else
    %g894021 - If the mFileFlag is false than the file does not exist, set the
    %badListing flag.
    badListingDisplayMode = true;
end

s = {};
s{1} = makeheadhtml;
s{end+1} = ['<title>' getString(message('MATLAB:profiler:FunctionDetailsFor', escapeHtml(ftItem.FunctionName))) '</title>'];
cssfile = which('matlab-report-styles.css');
s{end+1} = sprintf('<link rel="stylesheet" href="file:///%s" type="text/css" />',cssfile);
s{end+1} = '</head>';
s{end+1} = '<body>';

% Summary info
displayName = escapeHtml(ftItem.FunctionName);
s{end+1} = sprintf('<span style="font-size:14pt; background:#FFE4B0">%s', ...
    displayName);

if ftItem.NumCalls==1,
    callStr = getString(message('MATLAB:profiler:Call'));
else
    callStr = getString(message('MATLAB:profiler:Calls'));
end
status = profile('status');

% set up column data for the summary
str = sprintf(' (%d %s, %4.3f sec',  ftItem.NumCalls, callStr, totalData(1));
last = 1;

if hasMem
    str = [str sprintf(', %s, %s, %s', formatData(2,totalData(2)), ...
        formatData(2,totalData(3)), ...
        formatData(2,totalData(4)))];
    last = 4;
end

for j=1:length(hwFields)
    str = [str sprintf(', %s', formatData(3,totalData(j+last)))];
end

str = [str ')</span><br/>'];
s{end+1} = str;
s{end+1} = ['<i>', getString(message('MATLAB:profiler:GeneratedUsing', datestr(now), status.Timer)), '</i><br/>'];

if mFileFlag
    s{end+1} = [getString(message('MATLAB:profiler:InFile', typeToDisplayValue(ftItem.Type))) ' ' sprintf('<a href="matlab: edit(urldecode(''%s''))">%s</a><br/>', ...
        urlencode(fullName), fullName)];
elseif isequal(ftItem.Type,'M-subfunction')
    s{end+1} =  [getString(message('MATLAB:profiler:AnonymousFunction')), '<br/>'];
else
    s{end+1} = [getString(message('MATLAB:profiler:InFile1', typeToDisplayValue(ftItem.Type), ftItem.FileName)) '<br/>'];
end

s{end+1} = ['<a href="matlab: stripanchors">', getString(message('MATLAB:profiler:CopyToNewWindow')), '</a>'];

if pFileFlag && ~mFileFlag
    s{end+1} =['<p><span class="warning">', getString(message('MATLAB:profiler:PFileWithNoMATLABCode')), '</span></p>'];
end

didChange = callstats('has_changed',ftItem.CompleteName);
if didChange
    s{end+1} = ['<p><span class="warning">', getString(message('MATLAB:profiler:FileChangedDuringProfiling1')), '</span></p>'];
end

s{end+1} = '<div class="grayline"/>';


% --------------------------------------------------
% Manage all the checkboxes
% Read in preferences
parentDisplayMode = getpref('profiler','parentDisplayMode',1);
busylineDisplayMode = getpref('profiler','busylineDisplayMode',1);
childrenDisplayMode = getpref('profiler','childrenDisplayMode',1);
mlintDisplayMode = getpref('profiler','mlintDisplayMode',1);
coverageDisplayMode = getpref('profiler','coverageDisplayMode',1);
listingDisplayMode = getpref('profiler','listingDisplayMode',1);

% disable the source listing if the file has changed in a major way
oldListingDisplayMode = listingDisplayMode;
if badListingDisplayMode
    listingDisplayMode = false;
end

s{end+1} = '<form method="GET" action="matlab:profviewgateway">';
s{end+1} = ['<input type="submit" value="', getString(message('MATLAB:profiler:Refresh')), '" />'];
s{end+1} = sprintf('<input type="hidden" name="profileIndex" value="%d" />',idx);

s{end+1} = '<table>';
s{end+1} = '<tr><td>';


checkOptions = {'','checked'};

s{end+1} = sprintf('<input type="checkbox" name="parentDisplayMode" %s />', ...
    checkOptions{parentDisplayMode+1});
s{end+1} = [getString(message('MATLAB:profiler:ShowParentFunctions')), '</td><td>'];

s{end+1} = sprintf('<input type="checkbox" name="busylineDisplayMode" %s />', ...
    checkOptions{busylineDisplayMode+1});
s{end+1} = [getString(message('MATLAB:profiler:ShowBusyLines')), '</td><td>'];

s{end+1} = sprintf('<input type="checkbox" name="childrenDisplayMode" %s />', ...
    checkOptions{childrenDisplayMode+1});
s{end+1} = [getString(message('MATLAB:profiler:ShowChildFunctions')), '</td></tr><tr><td>'];

s{end+1} = sprintf('<input type="checkbox" name="mlintDisplayMode" %s />', ...
    checkOptions{mlintDisplayMode+1});
s{end+1} = [getString(message('MATLAB:profiler:ShowCodeAnalyzerResults')), '</td><td>'];

s{end+1} = sprintf('<input type="checkbox" name="coverageDisplayMode" %s />', ...
    checkOptions{coverageDisplayMode+1});
s{end+1} = [getString(message('MATLAB:profiler:ShowFileCoverage')), '</td><td>'];

s{end+1} = sprintf('<input type="checkbox" name="listingDisplayMode" %s />', ...
    checkOptions{listingDisplayMode+1});
s{end+1} = [getString(message('MATLAB:profiler:ShowFunctionListing')), '</td>'];

s{end+1} = '</tr></table>';

s{end+1} = '</form>';

if hasMem || hasHw
    %
    % if we have more than just time data, insert a callback tied to a pulldown
    % menu which allows the user to select between data sorting methods
    % todo this menu needs to be moved somewhere nicer
    %
    s{end+1} = '<form method="GET" action="matlab:profviewgateway">';
    s{end+1} = [getString(message('MATLAB:profiler:SortBusyLines')) ' '];
    s{end+1} = sprintf('<input type="hidden" name="profileIndex" value="%d" />',idx);
    s{end+1} = '<select name="busyLineSortKey" onChange="this.form.submit()">';
    optionsList = { };
    optionsList{end+1} = 'time';
    if hasMem
        optionsList{end+1} = 'allocated memory';
        optionsList{end+1} = 'freed memory';
        optionsList{end+1} = 'peak memory';
    end
    for j=1:length(hwFields)
        optionsList{end+1} = lower(hwFields{j}(4:end));
    end
    for n = 1:length(optionsList)
        if strcmp(busyLineSortKeyNum2Str(key_data_field), optionsList{n})
            selectStr=getString(message('MATLAB:profiler:Selected'));
        else
            selectStr = '';
        end
        s{end+1} = sprintf('<option %s>%s</option>', selectStr, optionsList{n});
    end
    s{end+1} = '</select>';
    s{end+1} = '</form>';
end

s{end+1} = '<div class="grayline"/>';
% --------------------------------------------------


% --------------------------------------------------
% Parent list
% --------------------------------------------------
if parentDisplayMode
    parents = ftItem.Parents;
    
    s{end+1} = [getString(message('MATLAB:profiler:Parents')), '<br/>'];
    if isempty(parents)
        s{end+1} = [' ' getString(message('MATLAB:profiler:NoParent')) ' '];
    else
        s{end+1} = '<p><table border=0 cellspacing=0 cellpadding=6>';
        s{end+1} = '<tr>';
        s{end+1} = ['<td class="td-linebottomrt" bgcolor="#F0F0F0">', getString(message('MATLAB:profiler:FunctionNameTableElement')), '</td>'];
        s{end+1} = ['<td class="td-linebottomrt" bgcolor="#F0F0F0">', getString(message('MATLAB:profiler:FunctionType')), '</td>'];
        s{end+1} = ['<td class="td-linebottomrt" bgcolor="#F0F0F0">', getString(message('MATLAB:profiler:CallsTableElement')), '</td>'];
        s{end+1} = '</tr>';
        
        for n = 1:length(parents),
            s{end+1} = '<tr>';
            
            displayName = truncateDisplayName(profileInfo.FunctionTable(parents(n).Index).FunctionName,40);
            s{end+1} = sprintf('<td class="td-linebottomrt"><a href="matlab: profview(%d);">%s</a></td>', ...
                parents(n).Index, displayName);
            
            s{end+1} = sprintf('<td class="td-linebottomrt">%s</td>', ...
                typeToDisplayValue(profileInfo.FunctionTable(parents(n).Index).Type));
            
            s{end+1} = sprintf('<td class="td-linebottomrt">%d</td>', ...
                parents(n).NumCalls);
            
            s{end+1} = '</tr>';
        end
        
        s{end+1} = '</table>';
    end
    s{end+1} = '<div class="grayline"/>';
end
% --------------------------------------------------
% End parent list section
% --------------------------------------------------

% --------------------------------------------------
% Busy line list section
% --------------------------------------------------

% the index into ExecutedLines is always key_data_field + 2
% (i.e. 3 is time, 4 is allocated memory, 5 is freed memory, 6 is peak)
ln_index = key_data_field + 2;

% sort the data by the selected data kind.
[sortedDataList(:,key_data_field), sortedDataIndex] = sort(ftItem.ExecutedLines(:,ln_index));
sortedDataList = flipud(sortedDataList);

maxDataLineList = flipud(ftItem.ExecutedLines(sortedDataIndex,1));
maxDataLineList = maxDataLineList(1:min(5,length(maxDataLineList)));
maxNumCalls = max(ftItem.ExecutedLines(:,2));
dataSortedNumCallsList = flipud(ftItem.ExecutedLines(sortedDataIndex,2));

% sort all the rest of the line data based on the indices of the original
% sort.
for i=1:length(field_order)
    fi = field_order(i);
    if fi == key_data_field, continue; end
    sortedDataList(:,fi) = flipud(ftItem.ExecutedLines(sortedDataIndex,fi+2));
end

% Link directly to the busiest lines
% ----------------------------------------------

% set formats for each column (format is 1 for time, 2 for mem and 3 for other)
fmt = ones(1,length(field_order));

% The column names
data_fields = {getString(message('MATLAB:profiler:TotalTimeTableElement'))};
last = 1;

% memory column names
if hasMem
    fmt(2:4) = 2;
    data_fields = [ data_fields getString(message('MATLAB:profiler:AllocatedMemoryTableElement')) getString(message('MATLAB:profiler:FreedMemoryTableElement')) getString(message('MATLAB:profiler:PeakMemoryTableElement')) ];
    last = 4;
end

% hw counter column names (strip off the 'HW_')
for j=1:length(hwFields)
    fmt(j+last) = 3;
    data_fields = [ data_fields hwFields{j}(4:end) ];
end

if busylineDisplayMode
    s{end+1} = ['<strong>', getString(message('MATLAB:profiler:LinesSpent', lower(key_unit_up))), '</strong><br/> '];
    
    if ~mFileFlag || filteredFileFlag
        s{end+1} = getString(message('MATLAB:profiler:NoMATLABCodeToDisplay'));
    else
        if totalData(key_data_field) == 0
            s{end+1} = getString(message('MATLAB:profiler:NoMeasurableSpentInThisFunction', lower(key_unit_up)));
        end
        
        s{end+1} = '<p><table border=0 cellspacing=0 cellpadding=6>';
        
        s{end+1} = '<tr>';
        s{end+1} = ['<td class="td-linebottomrt" bgcolor="#F0F0F0">',  getString(message('MATLAB:profiler:LineNumber')), '</td>'];
        s{end+1} = ['<td class="td-linebottomrt" bgcolor="#F0F0F0">', getString(message('MATLAB:profiler:Code')), '</td>'];
        s{end+1} = ['<td class="td-linebottomrt" bgcolor="#F0F0F0">', getString(message('MATLAB:profiler:CallsTableElement')), '</td>'];
        
        % output the column names in the right order
        for fi=1:length(field_order)
            fidx = field_order(fi);
            s{end+1} = ['<td class="td-linebottomrt" bgcolor="#F0F0F0">' data_fields{fidx} '</td>'];
        end
        
        % the percentage and histogram bar always come last.
        s{end+1} = ['<td class="td-linebottomrt" bgcolor="#F0F0F0">% ' key_unit_up '</td>'];
        s{end+1} = ['<td class="td-linebottomrt" bgcolor="#F0F0F0">' key_unit_up ' ' getString(message('MATLAB:profiler:Plot')), '</td>'];
        s{end+1} = '</tr>';
        
        for n = 1:length(maxDataLineList),
            s{end+1} = '<tr>';
            if listingDisplayMode
                s{end+1} = sprintf('<td class="td-linebottomrt"><a href="#Line%d">%d</a></td>', ...
                    maxDataLineList(n),maxDataLineList(n));
            else
                s{end+1} = sprintf('<td class="td-linebottomrt">%d</td>', ...
                    maxDataLineList(n));
            end
            
            if maxDataLineList(n) > length(f)   % insurance
                codeLine = '';                    % file must have changed
            else
                codeLine = f{maxDataLineList(n)};
            end
            
            % Squeeze out the leading spaces
            codeLine(cumsum(1-isspace(codeLine))==0)=[];
            % Replace angle brackets
            codeLine = code2html(codeLine);
            
            maxLineLen = 30;
            if length(codeLine) > maxLineLen
                s{end+1} = sprintf('<td class="td-linebottomrt"><pre>%s...</pre></td>',codeLine(1:maxLineLen));
            else
                s{end+1} = sprintf('<td class="td-linebottomrt"><pre>%s</pre></td>',codeLine);
            end
            
            s{end+1} = sprintf('<td class="td-linebottomrt">%d</td>',dataSortedNumCallsList(n));
            
            % output each column of data in the proper order
            for fi=1:length(field_order)
                fidx = field_order(fi);
                t = sortedDataList(n,fidx);
                s{end+1} = sprintf('<td class="td-linebottomrt">%s</td>', formatData(fmt(fidx),t));
            end
            
            % output the percentage based on the key sort type.
            s{end+1} = sprintf('<td class="td-linebottomrt" class="td-linebottomrt">%s</td>',...
                formatNicePercent(sortedDataList(n,key_data_field), totalData(key_data_field)));
            
            if totalData(key_data_field) > 0
                dataRatio = sortedDataList(n,key_data_field)/totalData(key_data_field);
            else
                dataRatio = 0;
            end
            
            % generate histogram bar based on the key sort type.
            s{end+1} = sprintf('<td class="td-linebottomrt"><img src="%s" width=%d height=10></td>', ...
                bluePixelGif, round(100*dataRatio));
            
            s{end+1} = '</tr>';
            
        end
        
        % Now add a row for everything else
        s{end+1} = '<tr>';
        s{end+1} = ['<td class="td-linebottomrt">', getString(message('MATLAB:profiler:AllOtherLines')), '</td>'];
        s{end+1} = '<td class="td-linebottomrt">&nbsp;</td>';
        s{end+1} = '<td class="td-linebottomrt">&nbsp;</td>';
        
        % compute totals for remaining time & memory
        for fi=1:length(field_order)
            fidx = field_order(fi);
            if ~hasMem || fidx ~= 4
                % this doesn't work for peaks
                allOtherLineData(fidx) = totalData(fidx) - sum(sortedDataList(1:length(maxDataLineList), fidx));
            else
                % peak memory needs max.
                allOtherLineData(fidx) = max(sortedDataList(1:length(maxDataLineList), fidx));
            end
            s{end+1} = sprintf('<td class="td-linebottomrt">%s</td>',formatData(fmt(fidx), allOtherLineData(fidx)));
        end
        
        % output percentage of "all other lines" by key sort type.
        s{end+1} = sprintf('<td class="td-linebottomrt">%s</td>',formatNicePercent(allOtherLineData(key_data_field),totalData(key_data_field)));
        
        if totalData(key_data_field) > 0,
            dataRatio = allOtherLineData(key_data_field)/totalData(key_data_field);
        else
            dataRatio= 0;
        end
        
        % generate histogram bar for "all other lines" by key sort type.
        s{end+1} = sprintf('<td class="td-linebottomrt"><img src="%s" width=%d height=10></td>', ...
            bluePixelGif, round(100*dataRatio));
        s{end+1} = '</tr>';
        
        % Totals line
        s{end+1} = '<tr>';
        s{end+1} = ['<td class="td-linebottomrt" bgcolor="#F0F0F0">', getString(message('MATLAB:profiler:Totals')), '</td>'];
        s{end+1} = '<td class="td-linebottomrt" bgcolor="#F0F0F0">&nbsp;</td>';
        s{end+1} = '<td class="td-linebottomrt" bgcolor="#F0F0F0">&nbsp;</td>';
        
        % output totals for each column
        for fi=1:length(field_order)
            fidx = field_order(fi);
            s{end+1} = sprintf('<td class="td-linebottomrt" bgcolor="#F0F0F0">%s</td>',formatData(fmt(fidx),totalData(fidx)));
        end
        if totalData(key_data_field) > 0,
            s{end+1} = '<td class="td-linebottomrt" bgcolor="#F0F0F0">100%</td>';
        else
            s{end+1} = '<td class="td-linebottomrt" bgcolor="#F0F0F0">0%</td>';
        end
        
        % no histogram bar here
        s{end+1} = '<td class="td-linebottomrt" bgcolor="#F0F0F0">&nbsp;</td>';
        
        s{end+1} = '</tr>';
        
        s{end+1} = '</table>';
    end
    s{end+1} = '<div class="grayline"/>';
    
end
% --------------------------------------------------
% End line list section
% --------------------------------------------------


% --------------------------------------------------
% Children list
% --------------------------------------------------
if childrenDisplayMode
    % Sort children by key data field (i.e. time, allocated mem, freed mem or peak mem)
    
    children = ftItem.Children;
    s{end+1} = [getString(message('MATLAB:profiler:Children')), '<br/>'];
    
    if isempty(children)
        s{end+1} = getString(message('MATLAB:profiler:NoChildren'));
    else
        % Children are sorted by the current key
        childrenData(:,1)   = [ftItem.Children.TotalTime];
        last = 1;
        if hasMem
            childrenData(:,2) = [ftItem.Children.TotalMemAllocated];
            childrenData(:,3) = [ftItem.Children.TotalMemFreed];
            childrenData(:,4) = [ftItem.Children.PeakMem];
            last = 4;
        end
        for j=1:length(hwFields)
            childrenData(:,j+last) = [ftItem.Children.(hwFields{j})];
        end
        [~, dataSortIndex] = sort(childrenData(:,key_data_field));
        
        s{end+1} = '<p><table border=0 cellspacing=0 cellpadding=6>';
        s{end+1} = '<tr>';
        s{end+1} = ['<td class="td-linebottomrt" bgcolor="#F0F0F0">', getString(message('MATLAB:profiler:FunctionNameTableElement')), '</td>'];
        s{end+1} = ['<td class="td-linebottomrt" bgcolor="#F0F0F0">', getString(message('MATLAB:profiler:FunctionType')), '</td>'];
        s{end+1} = ['<td class="td-linebottomrt" bgcolor="#F0F0F0">', getString(message('MATLAB:profiler:CallsTableElement')), '</td>'];
        
        % output column headers for children
        for fi=1:length(field_order)
            fidx = field_order(fi);
            s{end+1} = ['<td class="td-linebottomrt" bgcolor="#F0F0F0">' data_fields{fidx} '</td>'];
        end
        
        % percentage and histogram always go last
        s{end+1} = ['<td class="td-linebottomrt" bgcolor="#F0F0F0">% ' key_unit_up '</td>'];
        s{end+1} = ['<td class="td-linebottomrt" bgcolor="#F0F0F0">' key_unit_up ' ' getString(message('MATLAB:profiler:Plot')) '</td>'];
        s{end+1} = '</tr>';
        
        for i = length(children):-1:1,
            n = dataSortIndex(i);
            s{end+1} = '<tr>';
            
            % Truncate the name if it gets too long
            displayFunctionName = truncateDisplayName(profileInfo.FunctionTable(children(n).Index).FunctionName,40);
            
            s{end+1} = sprintf('<td class="td-linebottomrt"><a href="matlab: profview(%d);">%s</a></td>', ...
                children(n).Index, displayFunctionName);
            
            s{end+1} = sprintf('<td class="td-linebottomrt">%s</td>', ...
                typeToDisplayValue(profileInfo.FunctionTable(children(n).Index).Type));
            
            s{end+1} = sprintf('<td class="td-linebottomrt">%d</td>', ...
                children(n).NumCalls);
            
            % output data for each column in the correct order
            for fi=1:length(field_order)
                fidx = field_order(fi);
                t = childrenData(n,fidx);
                s{end+1} = sprintf('<td class="td-linebottomrt">%s</td>', formatData(fmt(fidx),t));
            end
            
            % output percentage based on key sort type.
            s{end+1} = sprintf('<td class="td-linebottomrt">%s</td>', ...
                formatNicePercent(childrenData(n,key_data_field), totalData(key_data_field)));
            
            if totalData(key_data_field) > 0,
                dataRatio = childrenData(n,key_data_field)/totalData(key_data_field);
            else
                dataRatio= 0;
            end
            
            % generate histogram based on key sort type
            s{end+1} = sprintf('<td class="td-linebottomrt"><img src="%s" width=%d height=10></td>', ...
                bluePixelGif, round(100*dataRatio));
            s{end+1} = '</tr>';
        end
        
        % Now add a row with self-timing information
        s{end+1} = '<tr>';
        s{end+1} = ['<td class="td-linebottomrt">', getString(message('MATLAB:profiler:SelfBuiltIns', lower(key_unit_up))), '</td>'];
        s{end+1} = '<td class="td-linebottomrt">&nbsp;</td>';
        s{end+1} = '<td class="td-linebottomrt">&nbsp;</td>';
        
        % output self information for each type of data (time, memory)
        for fi=1:length(field_order)
            fidx = field_order(fi);
            if fidx ~= 4
                % not for peak
                selfData(fidx) = totalData(fidx) - sum(childrenData(:,fidx));
            else
                % peaks need something different.  (is this meaningless?)
                selfData(fidx) = totalData(fidx);
            end
            s{end+1} = sprintf('<td class="td-linebottomrt">%s</td>',formatData(fmt(fidx),selfData(fidx)));
        end
        
        % output percentage
        s{end+1} = sprintf('<td class="td-linebottomrt">%s</td>',formatNicePercent(selfData(key_data_field),totalData(key_data_field)));
        
        if totalData(key_data_field) > 0,
            dataRatio = selfData(key_data_field)/totalData(key_data_field);
        else
            dataRatio= 0;
        end
        
        % generate histogram
        s{end+1} = sprintf('<td class="td-linebottomrt"><img src="%s" width=%d height=10></td>', ...
            bluePixelGif, round(100*dataRatio));
        s{end+1} = '</tr>';
        
        % Totals row
        s{end+1} = '<tr>';
        s{end+1} = ['<td class="td-linebottomrt" bgcolor="#F0F0F0">' getString(message('MATLAB:profiler:Totals')) '</td>'];
        s{end+1} = '<td class="td-linebottomrt" bgcolor="#F0F0F0">&nbsp;</td>';
        s{end+1} = '<td class="td-linebottomrt" bgcolor="#F0F0F0">&nbsp;</td>';
        
        % output totals for each kind of data
        for fi=1:length(field_order)
            fidx = field_order(fi);
            s{end+1} = sprintf('<td class="td-linebottomrt" bgcolor="#F0F0F0">%s</td>',formatData(fmt(fidx),totalData(fidx)));
        end
        
        % percentage is always 100% or 0%
        if totalData(key_data_field) > 0,
            s{end+1} = '<td class="td-linebottomrt" bgcolor="#F0F0F0">100%</td>';
        else
            s{end+1} = '<td class="td-linebottomrt" bgcolor="#F0F0F0">0%</td>';
        end
        
        % no histogram for totals
        s{end+1} = '<td class="td-linebottomrt" bgcolor="#F0F0F0">&nbsp;</td>';
        
        s{end+1} = '</tr>';
        
        s{end+1} = '</table>';
    end
    
    s{end+1} = '<div class="grayline"/>';
end
% --------------------------------------------------
% End children list section
% --------------------------------------------------

try
  if mFileFlag && ~filteredFileFlag
    % Calculate beginning and ending lines for the current function
    
    % In the expression ftok = xmtok(f), ftok returns information
    % about line continuations.
    
    ftok = xmtok(f);
    try
        runnableLineIndex = callstats('file_lines',ftItem.FileName);
    catch e
        warning(message('MATLAB:profiler:NoCoverageInfo', ftItem.FileName, e.message));
        runnableLineIndex= [];
    end
    runnableLines = zeros(size(f));
    runnableLines(runnableLineIndex) = runnableLineIndex;
    
    % getmcode and callstats don't necessarily agree on line counting
    % (particularly when analyzing a p-coded file).  Force consistency
    % of the array dimensions to prevent error (g462077).
    if length(runnableLines) > length(f)
        runnableLines = runnableLines(1:length(f));
    end
    
    % FunctionName takes one of several forms:
    % 1. foo
    % 2. foo>bar
    % 3. foo1\private\foo2
    % 4. foo1/private/foo2>bar
    %
    % We need to strip off everything except for the very last \w+ string
    
    fname = regexp(ftItem.FunctionName,'(\w+)$','tokens','once');

    try
      strc = getcallinfo(fullName,'-v7.8');
      fcnList = {strc.name};
      fcnIdx = find(strcmp(fcnList,fname)==1);
    catch err
      fcnIdx = [];
    end
      
    if length(fcnIdx) > 1
        % In rare situations, two nested functions can have exactly the
        % same name twice in the same file. In these situations, I will
        % default to the first occurrence.
        fcnIdx = fcnIdx(1);
        warning(message('MATLAB:profiler:FunctionAppearsMoreThanOnce', fname{ 1 }));
    end
    
    if isempty(fcnIdx)
        % ANONYMOUS FUNCTIONS
        % If we can't find the function name on the list of functions
        % and subfunctions, assume this is an anonymous
        % function. Just display the entire file in this case.
        startLine = 1;
        endLine = length(f);
        lineMask = (startLine:endLine)';
    else
        startLine = strc(fcnIdx).firstline;
        endLine = strc(fcnIdx).lastline;
        lineMask = strc(fcnIdx).linemask;
    end
    
    % Christian Dorion’s hack 
    if startLine==0 && endLine==0; startLine = 1; end;

    runnableLines = runnableLines .* lineMask;
    
    moreSubfunctionsInFileFlag = 0;
    if endLine < length(f)
        moreSubfunctionsInFileFlag = 1;
    end
    
    % hiliteOption = [ time | numcalls | coverage | noncoverage | allocmem | freedmem | peakmem | none ]
    
    % getpref doesn't like spaces in the option names. is there a way around this?
    hiliteOption = getpref('profiler','hiliteOption',key_unit);
    
    % if we have no memory data but the current hiliteOption is
    % memory related, we must default back to the current type
    % we are sorting by (i.e. memory).
    if ~hasMem && (strcmp(hiliteOption, 'allocated memory') || ...
            strcmp(hiliteOption, 'freed memory') || ...
            strcmp(hiliteOption, 'peak memory'))
        hiliteOption = key_unit;
    end
    
    mlintstrc = [];
    if strcmp(hiliteOption,'mlint') || mlintDisplayMode
        mlintstrc = mlint(fullName,'-struct');
        
        % Sometimes the number of lines reported for a single mlint message
        % is greater than one. When this is true, we will split the single
        % message into two similar messages, each with its own line number.
        sortFlag = false;
        for i = 1:length(mlintstrc)
            if length(mlintstrc(i).line)>1
                mlintLineList = mlintstrc(i).line;
                % The original mlint message gets one of the line numbers.
                % Deal the rest of the messages out to new messages at the
                % end of the structure.
                sortFlag = true;
                mlintstrc(i).line = mlintLineList(1);
                for j = 2:length(mlintLineList)
                    mlintstrc(end+1) = mlintstrc(i);
                    mlintstrc(end).line = mlintLineList(j);
                end
            end
        end
        
        % Only sort the mlint structure if multiple lines per message were
        % encountered.
        if sortFlag
            % Sort the result so they go in order of line number
            mlintLines = [mlintstrc.line];
            [~,sortIndex] = sort(mlintLines);
            mlintstrc = mlintstrc(sortIndex);
        end
        
    end
  end
catch err
  warning('Analyzing %s:\n%s',ftItem.FileName,err.message)
  filteredFileFlag = true;
end
  
% --------------------------------------------------
% Code Analyzer list section
% --------------------------------------------------
if mlintDisplayMode
    s{end+1} = ['<strong>', getString(message('MATLAB:profiler:CodeAnalyzerResults')), '</strong><br/>'];
    
    if ~mFileFlag || filteredFileFlag
        s{end+1} = getString(message('MATLAB:profiler:NoMATLABCodeToDisplay'));
    else
        if isempty(mlintstrc)
            s{end+1} = getString(message('MATLAB:profiler:NoCodeAnalyzerMessages'));
        else
            % Remove mlint messages outside the function region
            mlintLines = [mlintstrc.line];
            mlintstrc([find(mlintLines < startLine) find(mlintLines > endLine)]) = [];
            s{end+1} = '<table border=0 cellspacing=0 cellpadding=6>';
            s{end+1} = '<tr>';
            s{end+1} = ['<td class="td-linebottomrt" bgcolor="#F0F0F0">', getString(message('MATLAB:profiler:LineNumberSoft')), '</td>'];
            s{end+1} = ['<td class="td-linebottomrt" bgcolor="#F0F0F0">', getString(message('MATLAB:profiler:Message')), '</td>'];
            s{end+1} = '</tr>';
            
            for n = 1:length(mlintstrc)
                if (mlintstrc(n).line <= endLine) && (mlintstrc(n).line >= startLine)
                    s{end+1} = '<tr>';
                    if listingDisplayMode
                        s{end+1} = sprintf('<td class="td-linebottomrt"><a href="#Line%d">%d</a></td>', mlintstrc(n).line, mlintstrc(n).line);
                    else
                        s{end+1} = sprintf('<td class="td-linebottomrt">%d</td>', mlintstrc(n).line);
                    end
                    s{end+1} = sprintf('<td class="td-linebottomrt"><span class="mono">%s</span></td>', mlintstrc(n).message);
                    s{end+1} = '</tr>';
                end
            end
            s{end+1} = '</table>';
        end
    end
    s{end+1} = '<div class="grayline"/>';
end
% --------------------------------------------------
% End Code Analyzer list section
% --------------------------------------------------


% --------------------------------------------------
% Coverage section
% --------------------------------------------------
if coverageDisplayMode
    s{end+1} = ['<strong>', getString(message('MATLAB:profiler:CoverageResults')), '</strong><br/>'];
    
    if ~mFileFlag || filteredFileFlag
        s{end+1} = getString(message('MATLAB:profiler:NoMATLABCodeToDisplay'));
    else
        s{end+1} = sprintf(['<a href="matlab: coveragerpt(fileparts(urldecode(''%s'')))">', getString(message('MATLAB:profiler:ShowCoverageForParentDir')), '</a> <br/>'], ...
            urlencode(fullName));
        
        linelist = (1:length(f))';
        canRunList = find(linelist(startLine:endLine)==runnableLines(startLine:endLine)) + startLine - 1;
        didRunList = ftItem.ExecutedLines(:,1);
        notRunList = setdiff(canRunList,didRunList);
        neverRunList = find(runnableLines(startLine:endLine)==0);
        
        s{end+1} = '<table border=0 cellspacing=0 cellpadding=6>';
        s{end+1} = ['<tr><td class="td-linebottomrt" bgcolor="#F0F0F0">', getString(message('MATLAB:profiler:TotalLinesInFunction')), '</td>'];
        s{end+1} = sprintf('<td class="td-linebottomrt">%d</td></tr>', endLine-startLine+1);
        s{end+1} = ['<tr><td class="td-linebottomrt" bgcolor="#F0F0F0">', getString(message('MATLAB:profiler:NoncodeLines')), '</td>'];
        s{end+1} = sprintf('<td class="td-linebottomrt">%d</td></tr>', length(neverRunList));
        s{end+1} = ['<tr><td class="td-linebottomrt" bgcolor="#F0F0F0">', getString(message('MATLAB:profiler:CodeLines')), '</td>'];
        s{end+1} = sprintf('<td class="td-linebottomrt">%d</td></tr>', length(canRunList));
        s{end+1} = ['<tr><td class="td-linebottomrt" bgcolor="#F0F0F0">', getString(message('MATLAB:profiler:CodeLinesThatDidRun')), '</td>'];
        s{end+1} = sprintf('<td class="td-linebottomrt">%d</td></tr>', length(didRunList));
        s{end+1} = ['<tr><td class="td-linebottomrt" bgcolor="#F0F0F0">', getString(message('MATLAB:profiler:CodeLinesThatDidNotRun')), '</td>'];
        s{end+1} = sprintf('<td class="td-linebottomrt">%d</td></tr>', length(notRunList));
        s{end+1} = ['<tr><td class="td-linebottomrt" bgcolor="#F0F0F0">', getString(message('MATLAB:profiler:CoverageDidCanRun')), '</td>'];
        if ~isempty(canRunList)
            s{end+1} = sprintf('<td class="td-linebottomrt">%4.2f %%</td></tr>', 100*length(didRunList)/length(canRunList));
        else
            s{end+1} = sprintf('<td class="td-linebottomrt">N/A</td></tr>');
        end
        s{end+1} = '</table>';
        
    end
    s{end+1} = '<div class="grayline"/>';
end
% --------------------------------------------------
% End Coverage section
% --------------------------------------------------


% --------------------------------------------------
% File listing
% --------------------------------------------------
% Make a lookup table to speed index identification
% The executedLines table is as long as the file and stores the index
% value for every executed line.

% check if the file changed in some major way
if oldListingDisplayMode && badListingDisplayMode
    s{end+1} = ['<p><span class="warning">', getString(message('MATLAB:profiler:FileModifiedDuringProfiling')), '</span></p>'];
end

if listingDisplayMode
    s{end+1} = ['<b>',  getString(message('MATLAB:profiler:FunctionListing')), '</b><br/>'];
    
    if ~mFileFlag || filteredFileFlag
        s{end+1} = getString(message('MATLAB:profiler:NoMATLABCodeToDisplay'));
    else
        
        executedLines = zeros(length(f),1);
        executedLines(ftItem.ExecutedLines(:,1)) = 1:size(ftItem.ExecutedLines,1);
        
        % Enumerate all alphanumeric values for later use in linking code
        alphanumericList = ['a':'z' 'A':'Z' '0':'9' '_'];
        alphanumericArray = zeros(1,128);
        alphanumericArray(alphanumericList) = 1;
        
        [bgColorCode,bgColorTable,textColorCode,textColorTable] = makeColorTables( ...
            f,hiliteOption, ftItem, ftok, startLine, endLine, executedLines, runnableLines,...
            mlintstrc, maxNumCalls);
        
        % ----------------------------------------------
        s{end+1} = '<form method="GET" action="matlab:profviewgateway">';
        s{end+1} = [getString(message('MATLAB:profiler:ColorHighlightCodeAccordingTo')) ' '];
        s{end+1} = sprintf('<input type="hidden" name="profileIndex" value="%d" />',idx);
        s{end+1} = '<select name="hiliteOption" onChange="this.form.submit()">';
        optionsList = { };
        shownString = { };
        %the optionsList is the string value used by the report to select
        %what is highlighted in the profile report. shownString is the
        %user-visible string in the html
        optionsList{end+1} = 'time';
        shownString{end+1} = getString(message('MATLAB:profiler:Time'));
        optionsList{end+1} = 'numcalls';
        shownString{end+1} = getString(message('MATLAB:profiler:Numcalls'));
        optionsList{end+1} = 'coverage';
        shownString{end+1} = getString(message('MATLAB:profiler:Coverage'));
        optionsList{end+1} = 'noncoverage';
        shownString{end+1} = getString(message('MATLAB:profiler:Noncoverage'));
        optionsList{end+1} = 'mlint';
        shownString{end+1} = getString(message('MATLAB:profiler:CodeAnalyzer'));
        if hasMem
            % add more highlight options when memory data is available
            optionsList{end+1} = 'allocated memory';
            shownString{end+1} = getString(message('MATLAB:profiler:AllocatedMemory'));
            optionsList{end+1} = 'freed memory';
            shownString{end+1} = getString(message('MATLAB:profiler:FreedMemory'));
            optionsList{end+1} = 'peak memory';
            shownString{end+1} = getString(message('MATLAB:profiler:PeakMemory'));
        end
        for j=1:length(hwFields)
            optionsList{end+1} = lower(hwFields{j}(4:end));
            shownString{end+1} = lower(hwFields{j}(4:end));
        end
        optionsList{end+1} = 'none';
        shownString{end+1} = getString(message('MATLAB:profiler:None'));
        for n = 1:length(optionsList)
            if strcmp(hiliteOption, optionsList{n})
                selectStr=getString(message('MATLAB:profiler:Selected'));
            else
                selectStr = '';
            end
            s{end+1} = sprintf('<option %s value="%s">%s</option>', selectStr, optionsList{n}, shownString{n});
        end
        s{end+1} = '</select>';
        s{end+1} = '</form>';
        
        
        % --------------------------------------------------
        %         Table creation
        s{end+1} = '<table id="FunctionListingTable">';
        
        s{end+1} = '<tr style="height:20px;">';
        s{end+1} = '<th>';
        s{end+1} = '<pre>';
        s{end+1} = ['<span style="color:#FF0000;">' getString(message('MATLAB:profiler:Time')) '</span> '];
        s{end+1} = '</pre>';
        s{end+1} = '</th>';
        s{end+1} = '<th>';
        s{end+1} = '<pre>';
        s{end+1} = ['<span style="color:#0000FF;">' getString(message('MATLAB:profiler:Calls')) '</span> '];
        s{end+1} = '</pre>';
        s{end+1} = '</th>';
        
        if hasMem
            s{end+1} = '<th>';
            s{end+1} = '<pre>';
            s{end+1} = '<span style="color:#20AF20;">mem</span> ';
            s{end+1} = '</pre>';
            s{end+1} = '</th>';
        end
        
        
        for j=1:length(hwFields)
            s{end+1} = '<th>';
            s{end+1} = '<pre>';
            s{end+1} = ['<span style="color:#FFA267;">  ' lower(hwFields{j}(4:end)) '</span> '];
            s{end+1} = '</pre>';
            s{end+1} = '</th>';
        end
        
        s{end+1} = '<th class="leftAligned" COLSPAN=2>';
        s{end+1} = '<pre>';
        s{end+1} = ['<span> ' getString(message('MATLAB:profiler:Line')) '</span>'];
        s{end+1} = '</pre>';
        s{end+1} = '</th>';
        s{end+1} = '</tr>';
        
        % Cycle through all the lines
        for n = startLine:endLine
            
            s{end+1} = '<tr>';
            
            lineIdx = executedLines(n);
            if lineIdx>0,
                callsPerLine = ftItem.ExecutedLines(lineIdx,2);
                timePerLine = ftItem.ExecutedLines(lineIdx,3);
                last = 3;
                if hasMem
                    memAlloc = ftItem.ExecutedLines(lineIdx,4);
                    memFreed = ftItem.ExecutedLines(lineIdx,5);
                    peakMem = ftItem.ExecutedLines(lineIdx,6);
                    last = 6;
                end
                for j=1:length(hwFields)
                    hwData(j) = ftItem.ExecutedLines(lineIdx,last+j);
                end
            else
                timePerLine = 0;
                callsPerLine = 0;
                memAlloc = 0;
                memFreed = 0;
                peakMem = 0;
                hwData = zeros(1,length(hwFields));
            end
            
            % Display the mlint message if necessary
            color = bgColorTable{bgColorCode(n)};
            textColor = textColorTable{textColorCode(n)};
            
            if mlintDisplayMode
                if any([mlintstrc.line]==n)
                    s{end+1} = sprintf('<a name="Line%d"></a>',n);
                end
            end
            
            if strcmp(hiliteOption,'mlint')
                % Use the color as the indicator that an mlint message
                % occurred on this line
                if ~strcmp(color,'#FFFFFF')
                    % Mark this line for in-document linking from the mlint
                    % list
                    mlintIdx = find([mlintstrc.line]==n);
                    for nMsg = 1:length(mlintIdx)
                        s{end+1} = sprintf('<td> <span style="color: #F00">%s</span><br/> </td>', ...
                            mlintstrc(mlintIdx(nMsg)).message);
                    end
                end
            end
            
            % Modify text so that < and > don't cause problems
            if n > length(f)    % insurance
                codeLine = '';    % file must have changed
            else
                codeLine = code2html(f{n});
            end
            
            % Display the time
            s{end+1} = '<td>';
            s{end+1} = '<pre>';
            if timePerLine > 0.01,
                s{end+1} = sprintf('<span style="color: #FF0000"> %5.2f </span>', ...
                    timePerLine);
            elseif timePerLine > 0
                s{end+1} = '<span style="color: #FF0000">&lt; 0.01 </span>';
            end
            s{end+1} = '</pre>';
            s{end+1} = '</td>';
            
            % Display the number of calls
            s{end+1} = '<td>';
            s{end+1} = '<pre>';
            if callsPerLine > 0,
                s{end+1} = sprintf('<span style="color: #0000FF">%7d </span>', ...
                    callsPerLine);
            end
            s{end+1} = '</pre>';
            s{end+1} = '</td>';
            
            % Display memory data
            if hasMem
                s{end+1} = '<td>';
                s{end+1} = '<pre>';
                if memAlloc > 0 || memFreed > 0 || peakMem > 0
                    
                    str = sprintf('%s/%s/%s', ...
                        toKb(memAlloc,'%0.3g',true), ...
                        toKb(memFreed,'%0.3g',true), ...
                        toKb(peakMem,'%0.3g',true));
                    % 3 5-digit numbers, 2 slashes, 2 spaces = 19 spaces
                    str = sprintf('<span style="color: #20AF20">%19s </span>', str);
                end
                s{end+1} = str;
                s{end+1} = '</pre>';
                s{end+1} = '</td>';
            end
            
            % display hardware counter data for this line
            if hasHw
                s{end+1} = '<td>';
                s{end+1} = '<pre>';
                str = '';
                for j=1:length(hwData)
                    if(hwData(j))
                        str = [str sprintf('<span style="color: #FFA267">%9d </span>', hwData(j))];
                    end
                end
                s{end+1} = str;
                s{end+1} = '</pre>';
                s{end+1} = '</td>';
            end
            
            % Display the line number
            s{end+1} = '<td>';
            s{end+1} = '<pre>';
            if callsPerLine > 0
                s{end+1} = sprintf('<span style="color: #000000; font-weight: bold; margin:0; "><a href="matlab: opentoline(urldecode(''%s''),%d)">%4d</a></span> ', ...
                    urlencode(fullName), n, n);
            else
                s{end+1} = sprintf('<span style="color: #A0A0A0; margin:0;">%4d</span> ', n);
            end
            
            if ~isempty(find(n==maxDataLineList, 1)),
                % Mark the busy lines in the file with an anchor
                s{end+1} = sprintf('<a name="Line%d"></a>',n);
            end
            s{end+1} = '</pre>';
            s{end+1} = '</td>';
            
            if callsPerLine > 0
                % Need to add a space to the end to make sure the last
                % character is an identifier.
                codeLine = [codeLine ' '];
                % Use state machine to substitute in linking code
                codeLineOut = '';
                
                state = 'between';
                
                substr = [];
                for m = 1:length(codeLine),
                    ch = codeLine(m);
                    % Deal with the line with identifiers and Japanese comments .
                    % 128 characters are from 0 to 127 in ASCII
                    if ch >= 0 && ch <= 127
                        alphanumeric = alphanumericArray(ch);
                    else
                        alphanumeric = 0;
                    end
                    
                    switch state
                        case 'identifier'
                            if alphanumeric,
                                substr = [substr ch];
                            else
                                state = 'between';
                                if isfield(targetHash,substr)
                                    substr = sprintf('<a href="matlab: profview(%d);">%s</a>', targetHash.(substr), substr);
                                end
                                codeLineOut = [codeLineOut substr ch];
                            end
                        case 'between'
                            if alphanumeric,
                                substr = ch;
                                state = 'identifier';
                            else
                                codeLineOut = [codeLineOut ch];
                            end
                        otherwise
                            
                            error(message('MATLAB:profiler:UnexpectedState', state));
                            
                    end
                end
                codeLine = codeLineOut;
            end
            
            % Display the line
            s{end+1} = '<td class="leftAligned">';
            s{end+1} = '<pre>';
            s{end+1} = sprintf('<span style="color: %s; background: %s; padding:1px;">%s</span><br/>', ...
                textColor, color, codeLine);
            s{end+1} = '</pre>';
            s{end+1} = '</td>';
            
            s{end+1} = '</tr>';
            
        end
        
        s{end+1} = '</table>';
        if moreSubfunctionsInFileFlag
            s{end+1} = ['<p><p>', getString(message('MATLAB:profiler:SubfunctionsNotIncluded'))];
        end
    end
end

% --------------------------------------------------
% End file list section
% --------------------------------------------------

s{end+1} = '</body>';
s{end+1} = '</html>';

function escapedString = escapeHtml(originalString)
%ESCAPEHTML Escapes the characters in a String using HTML entities
 
escapedString = char(org.apache.commons.lang.StringEscapeUtils.escapeHtml(originalString));

% --------------------------------------------------
function shortFileName = truncateDisplayName(longFileName,maxNameLen)
%TRUNCATEDISPLAYNAME  Truncate the name if it gets too long

shortFileName = escapeHtml(longFileName);
if length(longFileName) > maxNameLen,
    shortFileName = char(com.mathworks.util.FileUtils.truncatePathname( ...
        shortFileName, maxNameLen));
end


% --------------------------------------------------
function b = hasMemoryData(s)
% Does this profiler data structure have memory profiling information in it?
b = (isfield(s, 'PeakMem') || ...
    (isfield(s, 'FunctionTable') && isfield(s.FunctionTable, 'PeakMem')));
% --------------------------------------------------

function f = getHwFields(s)
% Get the field names for any hardware performance counter data
if isfield(s, 'FunctionTable')
    names = fieldnames(s.FunctionTable);
else
    names = fieldnames(s);
end
f = names(strncmp('HW',names,2));

% --------------------------------------------------
function s = formatData(key_data_field, num)
% Format a number as seconds or bytes depending on the
% value of key_data_field (1 = time, 2 = memory, 3 = other)
switch(key_data_field)
    case 1
        if num > 0
            s = sprintf('%4.3f s', num);
        else
            s = '0 s';
        end
    case 2
        num = num ./ 1024;
        s = sprintf('%4.2f Kb', num);
    case 3
        s = num2str(num);
end

% --------------------------------------------------
function s = formatNicePercent(a, b)
% Format the ratio of two numbers as a percentage.
% Use 0% when either number is zero.
if b > 0 && a > 0
    s = sprintf('%3.1f%%', 100*a/b);
else
    s = '0%';
end

% --------------------------------------------------
function x = toKb(y,fmt,terse)
% convert number of bytes into a nice printable string

values   = { 1 1024 1024 1024 1024 };
if nargin == 3 && terse
    suffixes = {'b' 'k' 'm' 'g' 't'};
else
    suffixes = { ' bytes' ' Kb' ' Mb' ' Gb' ' Tb' };
end

suff = suffixes{1};

for i = 1:length(values)
    if abs(y) >= values{i}
        suff = suffixes{i};
        y = y ./ values{i};
    else
        break;
    end
end

if nargin == 1
    if strcmp(suff, suffixes{1})
        fmt = '%4.0f';
    else
        fmt = '%4.2f';
    end
end

x = sprintf([fmt suff], y);

% --------------------------------------------------
function n = busyLineSortKeyStr2Num(str)
% Convert between string names and profile data sort types
% (see key_data_field)
if strcmp(str, 'time')
    n = 1;
    return;
elseif strcmp(str, 'allocated memory')
    n = 2;
    return;
elseif strcmp(str, 'freed memory')
    n = 3;
    return;
elseif strcmp(str, 'peak memory')
    n = 4;
    return;
else
    hw_events = callstats('hw_events');
    match = strcmpi(['hw_' str],hw_events);
    if any(match)
        idx = 1:length(hw_events);
        if callstats('memory') > 1
            n = idx(match) + 4;
        else
            n = idx(match) + 1;
        end
        return;
    end
end

error(message('MATLAB:profiler:UnknownSortKind', str));

% --------------------------------------------------
function str = busyLineSortKeyNum2Str(n)
% Convert from data sort types to string name.
% (see key_data_field)
strs = { 'time' };

% Cheat a bit here.  Only add the memory fields if the profiler
% is recording memory information.
if (callstats('memory') > 1)
    strs = [strs 'allocated memory' 'freed memory' 'peak memory' ];
end

% Cheat a bit here.  Check the profiler for the current set of
% hardware event counters being measured.
events = callstats('hw_events');
for j=1:length(events)
    events{j} = lower(events{j}(4:end));
end
strs = [strs events];

str = strs{n};

% --------------------------------------------------
function [bgColorCode,bgColorTable,textColorCode,textColorTable] = makeColorTables( ...
    f, hiliteOption, ftItem, ftok, startLine, endLine, executedLines, ...
    runnableLines, mlintstrc, maxNumCalls)

hwFields = getHwFields(ftItem);

% Take a first pass through the lines to figure out the line color
bgColorCode = ones(length(f),1);
textColorCode = ones(length(f),1);
textColorTable = {'#228B22','#000000','#A0A0A0'};

% Ten shades of green
memColorTable = { '#FFFFFF' '#00FF00' '#00EE00' '#00DD00' '#00CC00' ...
    '#00BB00' '#00AA00' '#009900' '#008800' '#007700'};

switch hiliteOption
    case 'time'
        % Ten shades of red
        bgColorTable = {'#FFFFFF','#FFF0F0','#FFE2E2','#FFD4D4', '#FFC6C6', ...
            '#FFB8B8','#FFAAAA','#FF9C9C','#FF8E8E','#FF8080'};
        key_data_field = 1;
    case 'numcalls'
        % Ten shades of blue
        bgColorTable = {'#FFFFFF','#F5F5FF','#ECECFF','#E2E2FF', '#D9D9FF', ...
            '#D0D0FF','#C6C6FF','#BDBDFF','#B4B4FF','#AAAAFF'};
    case 'coverage'
        bgColorTable = {'#FFFFFF','#E0E0FF'};
    case 'noncoverage'
        bgColorTable = {'#FFFFFF','#E0E0E0'};
    case 'mlint'
        bgColorTable = {'#FFFFFF','#FFE0A0'};
        
    case 'allocated memory'
        bgColorTable = memColorTable;
        key_data_field = 2;
        
    case 'freed memory'
        bgColorTable = memColorTable;
        key_data_field = 3;
        
    case 'peak memory'
        bgColorTable = memColorTable;
        key_data_field = 4;
        
    case 'none'
        bgColorTable = {'#FFFFFF'};
    otherwise
        match = strcmpi(['hw_' hiliteOption],hwFields);
        if any(match)
            % use 10 different shades of copper
            bgColorTable = {'#FFFFFF', '#FFC77F', '#FFBB77', '#FFAE6F', '#FFA267', ...
                '#EF955F', '#DB8957', '#C77D4F', '#B37047', '#9F643F'};
            idx = 1:length(hwFields);
            if hasMemoryData(ftItem)
                key_data_field = 4 + idx(match);
            else
                key_data_field = 1 + idx(match);
            end
        else
            error(message('MATLAB:profiler:UnknownHiliteOption', hiliteOption));
        end
end

maxData(1) = max(ftItem.ExecutedLines(:,3));
last = 3;
if hasMemoryData(ftItem)
    maxData(2) = max(ftItem.ExecutedLines(:,4));
    maxData(3) = max(ftItem.ExecutedLines(:,5));
    maxData(4) = max(ftItem.ExecutedLines(:,6));
    last = 6;
end
for j=1:length(hwFields)
    maxData(end+1) = max(ftItem.ExecutedLines(:,last+j));
end

for n = startLine:endLine
    
    if ftok(n) == 0
        % Non-code line, comment or empty. Color is green
        textColorCode(n) = 1;
    elseif ftok(n) < n
        % This is a continuation line. Make it the same color
        % as the originating line
        bgColorCode(n) = bgColorCode(ftok(n));
        textColorCode(n) = textColorCode(ftok(n));
    else
        % This is a new executable line
        lineIdx = executedLines(n);
        
        if (strcmp(hiliteOption,'time') || ...
                strcmp(hiliteOption,'allocated memory') || ...
                strcmp(hiliteOption,'freed memory') || ...
                strcmp(hiliteOption,'peak memory') || ...
                any(strcmpi(['hw_' hiliteOption],hwFields)))
            
            if lineIdx > 0
                textColorCode(n) = 2;
                if ftItem.ExecutedLines(lineIdx,key_data_field+2) > 0
                    dataPerLine = ftItem.ExecutedLines(lineIdx,key_data_field+2);
                    ratioData = dataPerLine/maxData(key_data_field);
                    bgColorCode(n) = ceil(10*ratioData);
                else
                    % The amount of time (or memory) spent on the line was negligible
                    bgColorCode(n) = 1;
                end
            else
                % The line was not executed
                textColorCode(n) = 3;
                bgColorCode(n) = 1;
            end
            
        elseif strcmp(hiliteOption,'numcalls')
            
            if lineIdx > 0
                textColorCode(n) = 2;
                if ftItem.ExecutedLines(lineIdx,2)>0;
                    callsPerLine = ftItem.ExecutedLines(lineIdx,2);
                    ratioNumCalls = callsPerLine/maxNumCalls;
                    bgColorCode(n) = ceil(10*ratioNumCalls);
                else
                    % This line was not called
                    bgColorCode(n) = 1;
                end
            else
                % The line was not executed
                textColorCode(n) = 3;
                bgColorCode(n) = 1;
            end
            
        elseif strcmp(hiliteOption,'coverage')
            
            if lineIdx > 0
                textColorCode(n) = 2;
                bgColorCode(n) = 2;
            else
                % The line was not executed
                textColorCode(n) = 3;
                bgColorCode(n) = 1;
            end
            
        elseif strcmp(hiliteOption,'noncoverage')
            
            % If the line did execute or it is a
            % non-breakpointable line, then it should not be
            % flagged
            if (lineIdx > 0) || (runnableLines(n) == 0)
                textColorCode(n) = 2;
                bgColorCode(n) = 1;
            else
                % The line was not executed
                textColorCode(n) = 2;
                bgColorCode(n) = 2;
            end
            
        elseif strcmp(hiliteOption,'mlint')
            
            if any([mlintstrc.line]==n)
                bgColorCode(n) = 2;
                textColorCode(n) = 2;
            else
                bgColorCode(n) = 1;
                if lineIdx > 0
                    textColorCode(n) = 2;
                else
                    % The line was not executed
                    textColorCode(n) = 3;
                end
            end
            
        elseif strcmp(hiliteOption,'none')
            
            if lineIdx > 0
                textColorCode(n) = 2;
            else
                % The line was not executed
                textColorCode(n) = 3;
            end
            
        end
    end
end

function str = typeToDisplayValue(type)
%convert function info table TYPE strings to display strings
switch type
    case 'M-function'
        str = getString(message('MATLAB:profiler:Function'));
    case 'M-subfunction'
        str = getString(message('MATLAB:profiler:Subfunction'));
    case 'M-anonymous-function'
        str = getString(message('MATLAB:profiler:AnonymousFunctionShort'));
    case 'M-nested-function'
        str = getString(message('MATLAB:profiler:NestedFunction'));
    case 'M-script'
        str = getString(message('MATLAB:profiler:Script'));
    case 'MEX-function',
        str = getString(message('MATLAB:profiler:MEXfile'));
    case 'Builtin-function'
        str = getString(message('MATLAB:profiler:BuiltinFunction'));
    case 'Java-method'
        str = getString(message('MATLAB:profiler:JavaMethod'));
    case 'constructor-overhead'
        str = getString(message('MATLAB:profiler:ConstructorOverhead'));
    case 'MDL-function'
        str = getString(message('MATLAB:profiler:SimulinkModelFunction'));
    case 'Root'
        str = getString(message('MATLAB:profiler:Root'));
    otherwise
        str = type;
end


%%#########################################################################
% From /Applications/MATLAB_R2015a.app/toolbox/matlab/codetools/private/
%%#########################################################################

function htmlOut = makeheadhtml()
% MAKEHEADHTML  Add a head for HTML report file.
%   Use locale to determine the appropriate charset encoding.
%
%   Note: <html> and <head> tags have been opened but not closed. 
%   Be sure to close them in your HTML file.

%   Copyright 1984-2014 MathWorks, Inc.

h1 = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">';
h2 = '<html xmlns="http://www.w3.org/1999/xhtml">';

% Use charset=UTF-8, g589137 g589371
encoding = 'UTF-8';
h3 = sprintf('<head><meta http-equiv="Content-Type" content="text/html; charset=%s" />',encoding);

% Add cascading style sheet link
cssfile = which('matlab-report-styles.css');
h4 = sprintf('<link rel="stylesheet" href="file:///%s" type="text/css" />',cssfile);

htmlOut = [h1 h2 h3 h4];


function matlabCodeAsCellArray = getmcode(filename)
%GETMCODE  Returns a cell array of the text in a MATLAB code file
%   matlabCodeAsCellArray = getmcode(filename)

% Copyright 1984-2013 The MathWorks, Inc.

fileContentsAsString = matlab.internal.getCode(filename);
if (isempty(fileContentsAsString))
  matlabCodeAsCellArray ={};
else
  fileContentsAsCellArray = textscan(fileContentsAsString,'%s','delimiter','\n','whitespace','');
  % "textscan" returns a cell array of cell arrays.  
  % Each cell inside the first cell corresponds to one line in the file
  matlabCodeAsCellArray = fileContentsAsCellArray{1}; 
end
