function bake_callback(obj,~,~)
    % This callback runs when the bake button is pressed

    if obj.verbose
        fprintf('In acquisition_view.bake callback\n')
    end

    obj.updateStatusText

    % Temporary HACK: Do not do anything if we are in autoROI mode the
    % autoROI stats do not exist
    if strcmp(obj.model.recipe.mosaic.scanmode,'tiled: auto-ROI')
        if isempty(obj.model.autoROI) || ~isfield(obj.model.autoROI,'stats')
            warndlg('Run autothresh before bake')
            return
        end
    end
    % END HACK
    
    %Check whether it's safe to begin
    [acqPossible, msg]=obj.model.checkIfAcquisitionIsPossible;
    if ~acqPossible
        if ~isempty(msg)
            warndlg(msg,'');
        end
       return
    end

    % Allow the user to confirm they want to bake
    ohYes='Yes!';
    noWay= 'No way';
    choice = questdlg('Are you sure you want to Bake this sample?', '', ohYes, noWay, noWay);

    switch choice
        case ohYes
            % pass
        case noWay
            return
        otherwise
            return
    end


    % Update the preview image in case the recipe has altered since the GUI was opened or
    % since the preview was last taken.
    obj.setUpImageAxes;


    % Force update of the depths and channels because for some reason they 
    % sometimes do not update when the recipe changes. 
    obj.populateDepthPopup
    obj.updateChannelsPopup

    obj.chooseChanToDisplay %By default display the channel shown in ScanImage

    set(obj.button_Pause, obj.buttonSettings_Pause.enabled{:})
    obj.button_BakeStop.Enable='off'; %This gets re-enabled when the scanner starts imaging

    obj.updateImageLUT;
    obj.model.leaveLaserOn=false; % TODO: For now always set the laser to switch off when starting [17/08/2017]

    try
        sectionInd = obj.model.bake; %if the bake loop didn't start, it returns 0
    catch ME
        fprintf('\nBAKE FAILED IN acquisition_view. CAUGHT THE FOLLOWING ERROR:\n %s\n', ME.message)
        for ii=1:length(ME.stack)
            fprintf('Line %d in %s\n', ...
                ME.stack(ii).line, ME.stack(ii).file)
        end
        fprintf('\n')
        rethrow(ME)
        return
    end

    obj.button_BakeStop.Enable='on'; 

    if obj.checkBoxLaserOff.Value && sectionInd>0
        % If the laser was slated to turn off then we also close
        % the acquisition GUI. This is because a lot of silly bugs
        % seem to crop up after an acquisition but they go away if
        % the user closes and re-opens the window. 
        obj.delete
    end

end %bake_callback
