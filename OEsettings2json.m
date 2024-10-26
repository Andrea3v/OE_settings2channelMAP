% converts settings.xml file gen by Open Ephys during recordings to channel map for Kilosort
% chan map is saved as .json and .mat

clc; clear; close all
[OExmlFile,OExmlPath] = uigetfile({'*.xml'},'select OE settings.xml file','D:\channelmaps');
[~, name0,~] = fileparts(OExmlFile);
name0       = extractAfter(name0,'settings'); % grab
OEinfo      = xml2struct(fullfile(OExmlPath,OExmlFile));

%% xml parserer to structure won't retain the order of the channels as in the xml, making the wrong channel map > use
% raw text reader instead

xmlText = fileread(fullfile(OExmlPath,OExmlFile));
expr = '<(?<type>[!?/]?)(?<name>[\w:.-]+)(?<attributes>[^>]*)>(?<content>[^<]*)';
tokens  = regexp(xmlText, expr, 'names');

%% chan map: grab the chan number and the value
indxChn = contains({tokens.name},'CHANNELS','IgnoreCase',false);
allChnsTxt = tokens(indxChn).attributes;
chNumbers = regexp(allChnsTxt, 'CH(\d+)','tokens');
chNumbers = str2double([chNumbers{:}]);                                     % actual channel order
shankNum = regexp(allChnsTxt, ':\d"', 'match');
shankNum = regexp([shankNum{:}], '\d', 'match');
shankNum = cellfun(@(x) str2double(x), shankNum);                                       % Convert from cell array to numeric vector

% chan x position
indxXpos    = contains({tokens.name},'ELECTRODE_XPOS','IgnoreCase',false);
allXposTxt  = tokens(indxXpos).attributes;
chXNum      = regexp(allXposTxt, 'CH(\d+)','tokens');
chXNum      = str2double([chXNum{:}]);
chXPos      = regexp(allXposTxt, '="(\d+)','tokens');
chXPos      = str2double([chXPos{:}]);

% chan y position
indxYpos    = contains({tokens.name},'ELECTRODE_YPOS','IgnoreCase',false);
allYposTxt  = tokens(indxYpos).attributes;
chYNum      = regexp(allYposTxt, 'CH(\d+)','tokens');
chYNum      = str2double([chYNum{:}]);
chYPos      = regexp(allYposTxt, '="(\d+)','tokens');
chYPos      = str2double([chYPos{:}]);

% fs
fsIndx      = contains({tokens.name},'STREAM','IgnoreCase',false);
fsText      = {tokens(fsIndx).attributes};
fsText      = fsText(~cellfun('isempty', fsText))';
if ~any(contains(fsText,'Neuropixels 2'))
    fsIndxAP    = contains(fsText,'-AP');
else
    fsIndxAP    = contains(fsText,'ProbeA','IgnoreCase',true);
end

fsText      = fsText(fsIndxAP);
fs          = regexp(fsText{1}, 'sample_rate="(\d+)','tokens');
fs          = str2double(fs{:});


%% load the rest of the info - xcoord, ycoord - using parser, then re-sort these info according
% to actual chan map in previous section

if isequal(chNumbers,chXNum) && isequal(chNumbers,chYNum)
    
    chMap0ind   = chNumbers;
    chMap       = chMap0ind+1;
    xcoords     = chXPos;
    ycoords     = chYPos;
    
    % plot chan map
    
    cmap        = winter(numel(chMap0ind));
    f1          = figure('Name','Probe','Color','w','NumberTitle','off','Position',[295 50 649 946],'Renderer','painters');
    scatter(xcoords(chMap),ycoords(chMap),50,cmap,'s', 'filled');
    axis('equal')
    
    % find shanks
    
    allxpos     = sort(unique(xcoords));
    
    groups      = [allxpos',zeros(size(allxpos))'];  % Start all in group 0
    groupN      = 0;
    
    for i = 2:length(allxpos)
        if allxpos(i) - allxpos(i-1) > 200 % if site is >0.2mm then it's a different group
            groupN      = groupN + 1;
        end
        groups(i,2)     = groupN;
    end
    
    % assign group
    
    kcoords     = nan(numel(xcoords),1);
    for kj = 1:numel(allxpos)
        indx        = xcoords == groups(kj,1);
        kcoords(indx) = groups(kj,2);
    end
    
    shanks = unique(shankNum)+1;
    shanksName  = sprintf('shank_%s_',num2str(shanks));
    
    % SAVE  .json
    chanMapStruct = struct('chanMap',chNumbers,'xc',xcoords,'yc',ycoords,'kcoords',kcoords,'n_chan',numel(chNumbers));
    jsonChanMap = jsonencode(chanMapStruct);
    name        = 'KS_chanMap';
    jsonName    = fullfile(OExmlPath, [shanksName,name, name0, '.json']);
    fileID      = fopen(jsonName, 'w');
    fprintf(fileID, '%s', jsonChanMap);
    fclose(fileID);
    
    % SAVE .mat
    chMap       = chNumbers+1;
    connected   = true(numel(chNumbers),1);
    save(fullfile(OExmlPath, [shanksName, name, name0, '.mat']), ...
        'chMap', 'connected', 'xcoords', 'ycoords', 'kcoords', 'chNumbers', 'name', 'fs')
    
    % SAVE figure
    
    saveas(f1,fullfile(OExmlPath, [shanksName, name, name0, '_probeView.fig']))
    
else
    error('non-matching channels in x,y coordinates, check settings.xml file')
end