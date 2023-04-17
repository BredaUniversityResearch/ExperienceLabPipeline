function out = calculatebikingpower(cfg)
%% NAME OF FUNCTION
% function out = calculatebikingpower(cfg)
%
% *DESCRIPTION*
%This function can calculate the current power required to propel a bike
%forward
%
% *INPUT*
%Configuration Options
%cfg.bikerweight = weight of the biker in KG;
%cfg.bikeweight = weight of the bike in KG;
%cfg.verticalgain = verticalgain of that section in M;
%cfg.timeinseconds = Time of that section in S;
%cfg.speed = Speed of the biker in KM/H;
%cfg.roadtype = Type of Road, can be set as "road" or "mountain"
%cfg.position = Position of the biker, can be set as "standing", "seated,bar-tops", "seated,drops", "seated,tucked";
%
% *OUTPUT*
%The final power calculation
%
% *NOTES*
%this calculation is based on the website of the university of arizona
%https://www.u.arizona.edu/~sandiway/bike/climb.html
%
% *BY*
%Wilco Boode

%% CHECK VARIABLES
%Checks for user provided values, if they are not in standard values are used
if ~isfield(cfg, 'bikerweight')
    cfg.bikerweight = 70;
end
if ~isfield(cfg, 'bikeweight')
    cfg.bikeweight = 9;
end
if ~isfield(cfg, 'verticalgain')
    cfg.verticalgain = 0;
end
if ~isfield(cfg, 'timeinseconds')
    error('NO TIME FOUND FOR POWER CALCULATION');
end
if ~isfield(cfg, 'speed')
    error('NO SPEED FOUND FOR POWER CALCULATION');
end
if ~isfield(cfg, 'roadtype')
    cfg.roadtype = "road";

end
if ~isfield(cfg, 'position')
    cfg.position = "seated,bar-tops";
end

%% SET VALUES
%Set non-user definable values
crunits = 3600;
if strcmp(cfg.roadtype,"road")
    roadtype = 0.0047;
elseif strcmp(cfg.roadtype,"mountain")
    roadtype = 0.0066;
end

if strcmp(cfg.position,"standing")
    position = 0.356;
elseif strcmp(cfg.position,"seated,bar-tops")
    position = 0.267;
elseif strcmp(cfg.position,"seated,drops")
    position = 0.233;
elseif strcmp(cfg.position,"seated,tucked")
    position = 0.167;
end

climbrateperhour = cfg.verticalgain/cfg.timeinseconds*crunits;
climbrate = cfg.verticalgain/cfg.timeinseconds;
totalweight = cfg.bikeweight + cfg.bikerweight;

speed = cfg.speed * 0.2778;
speed3 = speed*speed*speed;
gravityscalar = 9.81;
rollingresistance = roadtype;
riderposition = position;


%% CALCULATE POWER LEVEL
%Calculate final values that indicate power
gravity = gravityscalar*totalweight*climbrate;
rolresistance = gravityscalar*totalweight*rollingresistance*speed;
aero = riderposition*speed3;
power = gravity + rolresistance + aero;

%% OUTPUT
out = power;
end