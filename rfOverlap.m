% rfOverlap
% Grab Transect Data for V1 and SC
% Plots heatmap of joint impairment by location
% Plots heatmap of the ratio

% Master List of the animal numbers for this project.
% animals = {'2365','2394','2396','2397',...
%     '2401','2452','2453', '2454','2456','2475','2476','2485','2487','2488',...
%     '2588', '2589','2590','2594', '2623', '2624', '2625', '2627'};

% mice that need a second look
animals = {'2588'};

% Minimum Number of Trials For Consideration
trialCutoff = 50;
addpath '/Users/jacksoncone/Documents/GitHub/Transect';

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

%%  Compute Map for V1
for mouse = 1:length(transectDir)
    cd(strcat(filePath,transectDir(mouse).name,'/','MatFiles/','V1'));
    V1Dir = dir('**/*.mat');
    numSessions = length(V1Dir);
    if numSessions == 0
        continue
    end

    stimDesc = [];
    azimuths = [];
    elevations = [];
    stimTrial = [];
    outcomes = [];
    RTs = [];
    contrast = [];
    topUp = [];
    
    % Get Data for this mouse
    for session = 1:numSessions
        load(V1Dir(session).name);

        stimDesc = [trials.stimDesc];
        azimuths = [azimuths, stimDesc.azimuthDeg];
        elevations = [elevations, stimDesc.elevationDeg];
        stimTrial = [stimTrial, stimDesc.powerIndex];
        outcomes = [outcomes, trials.trialEnd];
        RTs = [RTs, trials.reactTimeMS];
        contrast = [contrast, trials.contrastPC];

        if isfield(stimDesc,'topUpStimulus')
            topUp = [topUp, stimDesc.topUpStimulus];
        else
            topUp = [topUp, zeros(1,length(stimDesc))];
        end
    end

    clear trials stimDesc file dParams
    hit = outcomes == 0; fa = outcomes == 1; miss = outcomes == 2;
    V1Table = table(azimuths', elevations', hit', miss', fa', topUp', stimTrial');
    V1Table.Properties.VariableNames = {'azimuths','elevations','hit','miss','fa','topUp','stimTrial'};
    testedLocsV1 = unique(V1Table(:,[1 2]), 'rows');
    numLocs = size(testedLocsV1,1);

    % Change in Perf at each location
    nTrials = [];
    nStimTrials = [];
    nNoStimTrials = [];
    stimHits = [];
    noStimHits = [];
    stimHitRate = [];
    noStimHitRate = [];
    deltaHitRate = [];

    for i = 1:numLocs
        idx = table2array(testedLocsV1(i,:));
        stimLogical = V1Table.azimuths == idx(1) & V1Table.elevations == idx(2);
        subTableV1 = V1Table(stimLogical',3:end);
        subTableV1 = subTableV1(subTableV1.fa ~= 1,[1,2,4,5]);
        subTableV1 = subTableV1(subTableV1.topUp == 0,[1,2,4]);

        nTrials(i,:) = size(subTableV1,1);
        nStimTrials = nTrials(i,:) - sum(subTableV1.stimTrial==0);
        nNoStimTrials = nTrials(i,:) - nStimTrials;
        stimHits = sum(subTableV1.hit==1 & subTableV1.stimTrial==1);
        noStimHits = sum(subTableV1.hit==1 & subTableV1.stimTrial==0);
        stimHitRate(i,:) = stimHits/nStimTrials;
        noStimHitRate(i,:) = noStimHits/nNoStimTrials;
        deltaHitRate(i,:) = stimHitRate(i)-noStimHitRate(i);
    end

    % Add Performance Data To Table
    perfTableV1 = table(stimHitRate, noStimHitRate, deltaHitRate, nTrials);
    % Append to Output Table
    testedLocsV1 = [testedLocsV1, perfTableV1];
    % Only Consider Sessions where trials > trialCutoff
    testedLocsV1 = testedLocsV1(testedLocsV1.nTrials>trialCutoff,:);

    %% Now Repeat for SC
    cd(strcat(filePath,transectDir(mouse).name,'/','MatFiles/','SC'));
    SCDir = dir('**/*.mat');
    numSessions = length(SCDir);
    if numSessions == 0
        continue
    end

    stimDesc = [];
    azimuths = [];
    elevations = [];
    stimTrial = [];
    outcomes = [];
    RTs = [];
    contrast = [];
    topUp = [];

    % Get Data for this mouse
    for session = 1:numSessions
        load(SCDir(session).name);

        stimDesc = [trials.stimDesc];
        azimuths = [azimuths, stimDesc.azimuthDeg];
        elevations = [elevations, stimDesc.elevationDeg];
        stimTrial = [stimTrial, stimDesc.powerIndex];
        outcomes = [outcomes, trials.trialEnd];
        RTs = [RTs, trials.reactTimeMS];
        contrast = [contrast, trials.contrastPC];

        if isfield(stimDesc,'topUpStimulus')
            topUp = [topUp, stimDesc.topUpStimulus];
        else
            topUp = [topUp, zeros(1,length(stimDesc))];
        end
    end

    clear trials stimDesc file dParams
    hit = outcomes == 0; fa = outcomes == 1; miss = outcomes == 2;
    SCTable = table(azimuths', elevations', hit', miss', fa', topUp', stimTrial');
    SCTable.Properties.VariableNames = {'azimuths','elevations','hit','miss','fa','topUp','stimTrial'};
    testedLocsSC = unique(SCTable(:,[1 2]), 'rows');
    numLocs = size(testedLocsSC,1);

    % Change in Perf at each location
    nTrials = [];
    nStimTrials = [];
    nNoStimTrials = [];
    stimHits = [];
    noStimHits = [];
    stimHitRate = [];
    noStimHitRate = [];
    deltaHitRate = [];

    for i = 1:numLocs
        idx = table2array(testedLocsSC(i,:));
        stimLogical = SCTable.azimuths == idx(1) & SCTable.elevations == idx(2);
        subTableSC = SCTable(stimLogical',3:end);
        subTableSC = subTableSC(subTableSC.fa ~= 1,[1,2,4,5]);
        subTableSC = subTableSC(subTableSC.topUp == 0,[1,2,4]);

        nTrials(i,:) = size(subTableSC,1);
        nStimTrials = nTrials(i,:) - sum(subTableSC.stimTrial==0);
        nNoStimTrials = nTrials(i,:) - nStimTrials;
        stimHits = sum(subTableSC.hit==1 & subTableSC.stimTrial==1);
        noStimHits = sum(subTableSC.hit==1 & subTableSC.stimTrial==0);
        stimHitRate(i,:) = stimHits/nStimTrials;
        noStimHitRate(i,:) = noStimHits/nNoStimTrials;
        deltaHitRate(i,:) = stimHitRate(i)-noStimHitRate(i);
    end

    % Add Performance Data To Table
    perfTableSC = table(stimHitRate, noStimHitRate, deltaHitRate, nTrials);
    % Append to Output Table
    testedLocsSC = [testedLocsSC, perfTableSC];
    % Only Consider Sessions where trials > trialCutoff
    testedLocsSC = testedLocsSC(testedLocsSC.nTrials>trialCutoff,:);

%% Combine Data

% 5 degree step sizes on Stimulus Locations
scale = -35:5:35;
colorMapV1 = zeros(length(scale),length(scale));
countMapV1 = zeros(length(scale), length(scale));
colorMapSC = zeros(length(scale),length(scale));
countMapSC = zeros(length(scale), length(scale));

% V1 Data
for i = 1:size(testedLocsV1,1);
    colorMapV1(find(scale==testedLocsV1.elevations(i)), find(scale==testedLocsV1.azimuths(i)))...
        = testedLocsV1.deltaHitRate(i);
    countMapV1(find(scale==testedLocsV1.elevations(i)), find(scale==testedLocsV1.azimuths(i)))...
        = testedLocsV1.nTrials(i);
end

% SC Data
for i = 1:size(testedLocsSC,1);
    colorMapSC(find(scale==testedLocsSC.elevations(i)), find(scale==testedLocsSC.azimuths(i)))...
        = testedLocsSC.deltaHitRate(i);
    countMapSC(find(scale==testedLocsSC.elevations(i)), find(scale==testedLocsSC.azimuths(i)))...
        = testedLocsSC.nTrials(i);
end

% Use Counts to Control Color Saturation
totalCount = countMapSC+countMapV1;
% Fraction of max trial counts
normCounts = totalCount/max(max(totalCount));
% Delete any entries for areas that haven't been tested in both areas
counts = countMapSC == 0 | countMapV1 == 0;
normCounts(counts) = 0;

normCountsV1 = countMapV1/max(max(countMapV1));
normCountsSC = countMapSC/max(max(countMapSC));

% Set any sites that facilitated performance to 0.
% colorMapV1(colorMapV1 > 0) = 0;
% colorMapSC(colorMapSC > 0) = 0;

% Combined Effect Across Both Areas
colorMap = (colorMapV1 + colorMapSC)/2;

% Ratio of V1/SC Effect
% ratioMap = abs(colorMapV1)./abs(colorMapSC);
% % Clean Up any areas where both sites haven't been sampled
% ratioMap(counts)=0;
% ratioMap(ratioMap==Inf)=0;

%% Plot Summary Results
figure('Position', [10 10 1000 1000]);
subplot(1,2,1);
hold on;
axis square;
s = surf(colorMapV1, 'EdgeColor','k', 'EdgeAlpha', 0.1);
s.AlphaData = normCountsV1;    % set vertex transparencies by trial counts (peak normalized)
s.FaceAlpha = 'flat';
title(strcat('Avg Change in Perf V1: Mouse'," ", animals{1,mouse}));
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
xlim([1 length(colorMapV1)]);
ylim([1 length(colorMapV1)]);
ax.XTickLabel = {'-30', '-20', '-10', '0', '+10', '+20', '+30'};
ax.YTickLabel =  {'-30', '-20', '-10', '0', '+10', '+20', '+30'};
caxis([-0.20, 0.10]);
cbh.Ticks = [-0.20, -0.10, 0, 0.10];
cbh.TickLabels ={'-0.20', '-0.10', '0', '0.10'};
hold off;

subplot(1,2,2);
hold on;
axis square;
s = surf(colorMapSC, 'EdgeColor','k', 'EdgeAlpha', 0.1);
s.AlphaData = normCountsSC;    % set vertex transparencies by trial counts (peak normalized)
s.FaceAlpha = 'flat';
title(strcat('Avg Change in Perf SC: Mouse'," ", animals{1,mouse}));
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
xlim([1 length(colorMapSC)]);
ylim([1 length(colorMapSC)]);
ax.XTickLabel = {'-30', '-20', '-10', '0', '+10', '+20', '+30'};
ax.YTickLabel =  {'-30', '-20', '-10', '0', '+10', '+20', '+30'};
caxis([-0.20, 0.10]);
cbh.Ticks = [-0.20, -0.10, 0, 0.10];
cbh.TickLabels ={'-0.20', '-0.10', '0', '0.10'};
hold off;
% Save Figure
saveas(gcf, [strcat(filePath, 'ComboMaps/', animals{1,mouse},'_','combo','.tif')]);

%% Combined Effects
% comboMap = colorMapV1 + colorMapSC;
% comboCounts = countMapV1 + countMapSC;
% comboCounts(countMapV1 == 0|countMapSC == 0) = 0;
% normCounts = comboCounts/max(max(comboCounts));
% figure;
% hold on;
% axis square;
% s = surf(comboMap, 'EdgeColor','k', 'EdgeAlpha', 0.1);
% s.AlphaData = normCounts;    % set vertex transparencies by trial counts (peak normalized)
% s.FaceAlpha = 'flat';
% title(strcat('Total Change in Perf V1/SC: Mouse'," ", animals{1,mouse}));
% set(gca, 'FontSize', 14);
% colormap("autumn");
% ax = gca;
% grid off;
% cbh = colorbar;
% xlabel('Azimuth');
% ylabel('Elevation');
% ax.FontSize = 14;
% ax.LineWidth = 1;
% ax.TickDir = 'out';
% ax.XTick = [2.5, 4.5, 6.5, 8.5, 10.5, 12.5, 14.5];
% ax.YTick = [2.5, 4.5, 6.5, 8.5, 10.5, 12.5, 14.5];
% xlim([1 length(colorMapSC)]);
% ylim([1 length(colorMapSC)]);
% ax.XTickLabel = {'-30', '-20', '-10', '0', '+10', '+20', '+30'};
% ax.YTickLabel =  {'-30', '-20', '-10', '0', '+10', '+20', '+30'};
% caxis([-0.40, 0.10]);
% cbh.Ticks = [-0.40, -0.20, 0, 0.10];
% cbh.TickLabels ={'-0.40', '-0.20', '0', '0.10'};
% hold off;
% saveas(gcf, [strcat(filePath, 'sumMaps/', animals{1,mouse},'_','summed','.tif')]);

end
