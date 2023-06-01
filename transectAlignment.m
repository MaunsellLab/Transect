function transectAlignment(brainArea, trialCutoff)
addpath '/Users/jacksoncone/Documents/GitHub/Transect';
% Grab Transect Data and plot a heatmap of impairment by location
% trialCutoff = Min Number of Trials at Each Visual Location

% Master List of the animal numbers for this project.
animals = {'2339','2365','2394','2396','2397',...
    '2401','2452','2453', '2454','2456','2475','2476','2485','2487','2488',...
    '2588', '2589','2594'};

% Set this to the location of the transect data files on your machine
[~, name] = system('hostname');
name = lower(name);
if contains(name, 'nrb')
    filePath = '/Users/jacksoncone/Documents/GitHub/Transect/';
else
    filePath = '/Users/Shared/Data/Transect/';
end

% Get all Folders on the filePath
transectDir = dir(filePath);
% Filter Folders by the list of animals
transectDir = transectDir(ismember({transectDir.name}, animals));

%% Loop Through Mouse Folders
for mouse = 1:length(transectDir)
    cd(strcat(filePath,transectDir(mouse).name,'/','MatFiles/',brainArea));
    % How Many Sessions for This Mouse?
    mouseDir = dir('**/*.mat');
    numSessions = length(mouseDir);

    if numSessions == 0
        continue
    end
    
    % Init 
    stimDesc = [];
    azimuths = [];
    elevations = [];
    stimTrial = [];
    outcomes = [];
    RTs = [];
    contrast = [];
    topUp = [];
    %% Get Data for this mouse
    for session = 1:numSessions
        % Load Session MatFile
        load(mouseDir(session).name);

        stimDesc = [trials.stimDesc];
        azimuths = [azimuths, stimDesc.azimuthDeg];
        elevations = [elevations, stimDesc.elevationDeg];
        stimTrial = [stimTrial, stimDesc.powerIndex];
        outcomes = [outcomes, trials.trialEnd];
        RTs = [RTs, trials.reactTimeMS];
        contrast = [contrast, trials.contrastPC];

        % Some Sessions Had TopUps Others Didn't
        if isfield(stimDesc,'topUpStimulus')
            topUp = [topUp, stimDesc.topUpStimulus];
        else
            topUp = [topUp, zeros(1,length(stimDesc))];
        end
    end

    % Clean Up
    clear trials stimDesc file dParams

    % Get Outcomes and Filter
    hit = outcomes == 0; fa = outcomes == 1; miss = outcomes == 2;

    % Create Table Of all trials
    masterTable = table(azimuths', elevations', hit', miss', fa', topUp', stimTrial');
    masterTable.Properties.VariableNames = {'azimuths','elevations','hit','miss','fa','topUp','stimTrial'};

    % Unique Stimulus Locations
    testedLocs = unique(masterTable(:,[1 2]), 'rows');
    % Find all stimulus conditions that match
    numLocs = size(testedLocs,1);

    %% Change in Perf at each location
    nTrials = [];
    nStimTrials = [];
    nNoStimTrials = [];
    stimHits = [];
    noStimHits = [];
    stimHitRate = [];
    noStimHitRate = [];
    deltaHitRate = [];

    for i = 1:numLocs
        % Stim indexes for this Loc
        idx = table2array(testedLocs(i,:));
        % Logical For Indexing
        stimLogical = masterTable.azimuths == idx(1) & masterTable.elevations == idx(2);
        % Sub Select Table
        subTable = masterTable(stimLogical',3:end);
        % Delete False Alarms
        subTable = subTable(subTable.fa ~= 1,[1,2,4,5]);
        % Delete TopUp Trials
        subTable = subTable(subTable.topUp == 0,[1,2,4]);

        % Number of Trials
        nTrials(i,:) = size(subTable,1);
        % Opto Trials
        nStimTrials = nTrials(i,:) - sum(subTable.stimTrial==0);
        % No-Opto Trials
        nNoStimTrials = nTrials(i,:) - nStimTrials;
        % stimHits
        stimHits = sum(subTable.hit==1 & subTable.stimTrial==1);
        % noStimHits
        noStimHits = sum(subTable.hit==1 & subTable.stimTrial==0);
        % stimHitRate
        stimHitRate(i,:) = stimHits/nStimTrials;
        % noStimHitRate
        noStimHitRate(i,:) = noStimHits/nNoStimTrials;
        % Delta Hit Rate
        deltaHitRate(i,:) = stimHitRate(i)-noStimHitRate(i);
    end

    % Add Performance Data To Table
    perfTable = table(stimHitRate, noStimHitRate, deltaHitRate, nTrials);
    % Append to Output Table
    testedLocs = [testedLocs, perfTable];
    % Only Consider Sessions with more than 100 trials
    testedLocs = testedLocs(testedLocs.nTrials>trialCutoff,:);
    %% Plot HeatMap For This Mouse

    % 5 degree step sizes on Stimulus Locations
    scale = -35:5:35;
    % Init Color and trial count maps
    colorMap = zeros(length(scale),length(scale));
    countMap = zeros(length(scale), length(scale));

    for i = 1:size(testedLocs,1);
        colorMap(find(scale==testedLocs.elevations(i)), find(scale==testedLocs.azimuths(i)))...
            = testedLocs.deltaHitRate(i);

        countMap(find(scale==testedLocs.elevations(i)), find(scale==testedLocs.azimuths(i)))...
            = testedLocs.nTrials(i);
    end

    % Fraction of max trial counts
    normCounts = countMap/max(max(countMap));
    
    clearvars testedLocs perfTable masterTable subTable

    % Plot Summary Results
    figure('Position', [10 10 500 500]);
    hold on;
    axis square;
    s = surf(colorMap, 'EdgeColor','k', 'EdgeAlpha', 0.1);
    s.AlphaData = normCounts;    % set vertex transparencies by trial counts (peak normalized)
    s.FaceAlpha = 'flat';
    title(strcat('Change in Prop Detected: Mouse'," ", animals{1,mouse}," ", brainArea));
    set(gca, 'FontSize', 14);
    colormap("autumn");
    ax = gca;
    grid off;
    cbh = colorbar;
    xlabel('Azimuth');
    ylabel('Elevation');
    ax.FontSize = 14;
    ax.LineWidth = 1;
    ax.TickDir = 'out';
    ax.XTick = [2.5, 4.5, 6.5, 8.5, 10.5, 12.5, 14.5];
    ax.YTick = [2.5, 4.5, 6.5, 8.5, 10.5, 12.5, 14.5];
    xlim([1 length(colorMap)]);
    ylim([1 length(colorMap)]);
    ax.XTickLabel = {'-30', '-20', '-10', '0', '+10', '+20', '+30'};
    ax.YTickLabel =  {'-30', '-20', '-10', '0', '+10', '+20', '+30'};
    caxis([-0.20, 0.10]);
    cbh.Ticks = [-0.20, -0.10, 0, 0.10];
    cbh.TickLabels ={'-0.20', '-0.10', '0', '0.05'};
    hold off;
    % Save Figure
    % saveas(gcf, strcat(animals{1,mouse},"_",string(datetime('today')),'.tif'));
    saveas(gcf, [strcat(filePath, 'Maps/', animals{1,mouse},"_",brainArea,'.tif')]);

end
end
