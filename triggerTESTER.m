%=========================================================================
% FLASHING CHECKBOARD
%
% Created July 2010
% Bob Spunt
% Social Cognitive Neuroscience Lab (www.scn.ucla.edu)
% University of California, Los Angeles
%
% 08/23 - Script created (BS)
%=========================================================================
clear all; clc;
% get protocol ID
protocolID=input('\Identify the protocol you are using: ', 's');
% MRI flag
MRIflag=1;
% are you using the buttonbox or keyboard?
if MRIflag==1  % then always use the button box
    deviceflag=1;
else            % then use the button box during in-scanner tests, and keyboard when not in the scanner
    deviceflag=input('Are you using the buttonbox? 1 for YES, 2 for NO: ');
    while isempty(find(deviceflag==[1 2], 1));
        disp('ERROR: input must be 1 or 2. Please try again.');
        deviceflag=input('Are you using the buttonbox? 1 for YES, 2 for NO: ');
    end
end

%---------------------------------------------------------------
%% TASK CONSTANTS & INITIALIZE VARIABLES
%---------------------------------------------------------------
% rotating hemifield flickering checkerboard 
rcycles = 8;    % number of white/black circle pairs 
tcycles = 24;   % number of white/black angular segment pairs (integer) 
flicker_freq = 4;   % full cycle flicker frequency (Hz) 
flick_dur = 1/flicker_freq/2; 
period = 0;    % rotation period (sec) 

%---------------------------------------------------------------
%% SET UP INPUT DEVICES
%---------------------------------------------------------------

% from agatha's code, uses's Don's hid_probe.m
fprintf('\n\n===============');
fprintf('\nTRIGGER - CHOOSE DEVICE:')
fprintf('\n===============\n');
inputDevice = hid_probe;

fprintf('\n\n===============');
fprintf('\nMANUAL STARTUP - CHOOSE DEVICE:')
fprintf('\n   (if laptop at scanner, "5", if laptop elsewhere, "4", if imac, "5")')
fprintf('\n===============\n');
experimenterDevice = hid_probe;

%---------------------------------------------------------------
%% INITIALIZE SCREENS
%---------------------------------------------------------------
AssertOpenGL;
% screens=Screen('Screens');
% screenNumber=max(screens);
[w, rect] = Screen('OpenWindow',0,128); 
HideCursor 
xc = rect(3)/2; 
yc = rect(4)/2;
xysize = rect(4); 

% w=Screen('OpenWindow', screenNumber,0,[],32,2);
[wWidth, wHeight]=Screen('WindowSize', w);
xcenter=wWidth/2;
ycenter=wHeight/2;
priorityLevel=MaxPriority(w);
Priority(priorityLevel);

% colors
hi_index=255; 
lo_index=0; 
bg_index=128; 
black=BlackIndex(w); % Should equal 0.
white=WhiteIndex(w); % Should equal 255.
Screen('FillRect', w, bg_index);
Screen('Flip', w);

% text
theFont='Arial';
theFontSize=40;
Screen('TextSize',w,40);
theight = Screen('TextSize', w);
Screen('TextFont',w,theFont);
Screen('TextColor',w,white);

% cues
fixation='+';

% compute default Y position (vertically centered)
numlines = length(strfind(fixation, char(10))) + 1;
bbox = SetRect(0,0,1,numlines*theight);
[rect,dh,dv] = CenterRect(bbox, Screen('Rect', w));
PosY = dv;
% compute X position for fixation
bbox=Screen('TextBounds', w, fixation);
[rect,dh,dv] = CenterRect(bbox, Screen('Rect', w));
fixPosX = dh;

%---------------------------------------------------------------
%% ASSIGN RESPONSE KEYS
%---------------------------------------------------------------

respset=['b','y','g','r','t'];
trigger=KbName('t');
buttonOne=KbName('b');
buttonTwo=KbName('y');
buttonThree=KbName('g');
buttonFour=KbName('r');

%---------------------------------------------------------------
%% GET AND LOAD STIMULI
%---------------------------------------------------------------

% make stimulus 
s = xysize/sqrt(2); % size used for mask 
xylim = 2*pi*rcycles; 
[x,y] = meshgrid(-xylim:2*xylim/(xysize-1):xylim, - ... 
    xylim:2*xylim/(xysize-1):xylim); 
at = atan2(y,x); 
checks = ((1+sign(sin(at*tcycles)+eps) .* ... 
    sign(sin(sqrt(x.^2+y.^2))))/2) * (hi_index-lo_index) + lo_index; 
circle = x.^2 + y.^2 <= xylim^2; 
checks = circle .* checks + bg_index * ~circle; 
t(1) = Screen('MakeTexture', w, checks); 
t(2) = Screen('MakeTexture', w, hi_index - checks); % reversed contrast 


% display GET READY screen
Screen('FillRect', w, bg_index);
Screen('Flip', w);
WaitSecs(0.25);
DrawFormattedText_new(w, 'Press any key to start waiting for the trigger.', 'center','center',white, 600, 0, 0);
Screen('Flip',w);

%---------------------------------------------------------------
%% WAIT FOR TRIGGER OR KEYPRESS
%---------------------------------------------------------------

% this is taken from Naomi's script
if MRIflag==1, % wait for experimenter keypress (experimenterDevice) and then trigger from scanner (inputDevice)
    timer_started = 1;
    while timer_started
        [timerPressed,time] = KbCheck(experimenterDevice);
        STARTscanner = time;
        if timerPressed
            timer_started = 0;
        end
    end
    secs=KbTriggerWait(trigger,inputDevice);	% wait for trigger, return system time when detected
    anchor=secs;		% anchor timing here (because volumes are discarded prior to trigger)
    DisableKeysForKbCheck(trigger);     % So trigger is no longer detected
    triggerOFFSET = secs - STARTscanner;  % difference between experimenter keypress and when trigger detected
else % If using the keyboard, allow any key as input
    noresp=1;
    STARTscanner = GetSecs;
    while noresp
        [keyIsDown,secs,keyCode] = KbCheck(experimenterDevice);
        if keyIsDown && noresp
            noresp=0;
            triggerOFFSET = secs - STARTscanner;
            anchor=secs;	% anchor timing here
        end
    end
end;
WaitSecs(0.001);

% %---------------------------------------------------------------
% %% SAVE DATA
% %---------------------------------------------------------------
d=clock;
outfile=sprintf('triggertest_%s_%s_%02.0f-%02.0f.mat',protocolID,date,d(4),d(5));

try
    save(outfile,'protocolID','triggerOFFSET'); 
catch
	fprintf('couldn''t save %s\n saving to triggertester.mat\n',outfile);
	save triggertester;
end;

%---------------------------------------------------------------
%% CLOSE SCREENS
%---------------------------------------------------------------
Screen('CloseAll');
Priority(0);
ShowCursor;
