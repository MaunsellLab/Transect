function [mouseList] = getMice(brainArea)

% returns a List of mice by Genotype
    if strcmp(brainArea, 'SC')
        mouseList = {};
    elseif strcmp(brainArea, 'V1')
        mouseList = {'2401','2454','2487','2488'};
    elseif strcmp(brainArea, 'all')
        mouseList = {};
    else 
        msg = 'brainArea must be V1, SC, or all';
        error(msg);
    end
end


