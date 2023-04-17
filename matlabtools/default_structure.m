function out = default_structure (cfg,data)
%% NAME OF FUNCTION
% function out = default_structure (cfg,data)
%
% *DESCRIPTION*
%A description of the function,usually a single paragraph to describe what
%it does, why you use it, what is the outcome, and things to take into
%account.
%
% *INPUT*
%Information on the variables / data to feed into this function must
%contain info about the expected / possible configuration settings, and
%possibly a default / example variable
%
%Configuration Options
%cfg.variable1 = Info about this configuration variable
%cfg.variable2 = (OPTIONAL) Info about an optional configuration variable
%           default = 1;
%
%Data Requirements
%data.value1 = Description of a required variable in the data structure (if relevant)
%           example = [0 0 0 -1 -1 -1 1 1 1 1 0 0];
%
% *OUTPUT*
%Description of the output this function provides, both type of data, and
%potentialy the format it outputs
%
% *NOTES*
%Additional information about the function, for example if parts have been
%retrieved from an online source
%
% *BY*
%Name & Date when function was made or last updated

%% DEV INFO
%Information relevant for developers, things to add to the function,
%potential updates to consider

%% VARIABLE CHECK
%Location to check if required variables are available, you can throw
%errors for required variables, or set defaults for optional variables
if ~isfield (cfg, 'variable1')
    error('variable1 is not defined in the CFG')
end
if ~isfield (cfg, 'variable2')
    cfg.variable2 = 1;
end

%% FUNCTION PART 1
%Code for the function
functionOutcome1 = data.value1*cfg.variable2;

%% FUNCTION PART 2
%Code for the function
functionOutcome2 = linspace(0,functionOutcome1,10);

%% FUNCTION END
out = functionOutcome2;

end