function [SD,medbg,stats] = obtainCleanBackgroundSD(im,settings)
    % Calculate the SD and mean or median of the background
    %
    % function [SD,medbg,stats] = autoROI.obtainCleanBackgroundSD(im,settings)
    %
    % Purpose
    % Takes as input a 2D image and returns the SD and median (or mean) of the 
    % background pixel values. This function has various ways of obtaining this
    % value. The best approach is "dimmest_gmm", which uses a Gaussian mixture
    % model fitted to the dimmest pixels. This function is called by autoROI
    %
    % Inputs
    % im - 2d image
    % settings - optional. The output of autoROI.readSettings
    %
    % Outputs
    % SD - the SD of the background
    % medbg - the median or mean of the background
    % stats - details that can be used for logging and debugging
    %
    % 
    %
    % Rob Campbell - SWC 2021




    if isempty(im)
        SD=[];
        medbg=[];
        minThresh=[];
        return
    end

    if nargin<2
        settings = autoROI.readSettings;
    end

    method =  'dimmest_gmm'; %TODO -- add as an option or delete all other options and stick with just this (LATTER BETTER)

    switch method
    case 'border_vanilla'
        BG = borderPixGetter(im,settings);
        SD = std(BG);
        medbg = median(BG);
        minThresh=[];
    case 'border_gmm'
        BG = borderPixGetter(im,settings);
        SD = gmmSD(BG);
        medbg = median(BG);
        minThresh=[];
    case 'whole_gmm'
        [SD,medbg] = gmmSD(im);
        minThresh = medbg + SD*3;
    case 'dimmest_gmm'
        % Ensure no background pixels play a role in the calculation
        [BG,statsBrightBlocks] = autoROI.removeBrightBlocks(im,settings);
        BG = BG(:);
        BG(BG == -42) = [];
        BG(BG == 0) = [];

        [SD,medbg,statsGMM] = gmmSD(BG);
    end


    if nargout>2
        stats.statsBrightBlocks = statsBrightBlocks;
        stats.statsGMM = statsGMM;
    end

    end


    function [SD,mu,stats] =gmmSD(data)

        data = single(data(:));

        thresh=max(data(:)) - (range(data(:))*0.05);
        data(data>thresh)=[];
        % Trim away the top 10% of data

        options = statset('MaxIter',250);
        try
            rng( sum(double('Uma wags on')) ); % For reproducibility
            gm_f = fitgmdist(data,2,'Replicates',1,'Regularize', 0.3, 'Options',options);

        catch ME
            size(data)
            gm_f = [];
            disp(ME.message)
        end

        [~,sorted_ind] = sort(gm_f.mu,'ascend');
        SD = gm_f.Sigma(sorted_ind(1))^0.5;
        mu = gm_f.mu(sorted_ind(1));

        if nargout>2
            stats.gm_f = gm_f;
            x=linspace(-1000,2^15,2000);
            [n,x]=hist(data,x);
            stats.hist.x = x;
            stats.hist.n = n;
        end
    end



    function BG = borderPixGetter(im,settings)


        b = settings.main.borderPixSize;
        BG = [im(1:b,:), im(:,1:b)', im(end-b+1:end,:), im(:,end-b+1:end)'];
        BG = BG(:);

        % Remove any non-imaged pixels
        BG(BG == -42) = [];
        BG(BG == 0) = [];

    end