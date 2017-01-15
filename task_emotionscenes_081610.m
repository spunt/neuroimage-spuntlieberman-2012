%=========================================================================
% ACT4 - EMOTIONAL SCENES STUDY- Experimental task for fMRI
%
% Created July 2010
% Bob Spunt
% Social Cognitive Neuroscience Lab (www.scn.ucla.edu)
% University of California, Los Angeles
%
% 07/26 - Script created (BS)
% 08/16 - Updated method of holding on last movie frame (BS)
%=========================================================================
clear all; clc;
%---------------------------------------------------------------
%% PRINT VERSION INFORMATION TO SCREEN
%---------------------------------------------------------------
script_name='EMOTIONAL SCENES STUDY';
creation_date='07-26-10';
fprintf('%s (created %s)\n',script_name, creation_date);
%---------------------------------------------------------------
%% GET USER INPUT
%---------------------------------------------------------------

% get subject ID
subjectID=input('\nEnter subject ID: ');
while isempty(subjectID)
    disp('ERROR: no value entered. Please try again.');
    subjectID=input('Enter subject ID: ');
end;

% get run number
runNum=input('Enter run number (1 or 2): ');
while isempty(find(runNum==[1 2], 1)),
  runNum=input('Run number must be 1 or 2 - please re-enter: ');
end;

% is this a scan?
MRIflag=input('Are you scanning? 1 for YES, 2 for NO: ');
while isempty(find(MRIflag==[1 2], 1));
    disp('ERROR: input must be 0 or 1. Please try again.');
    MRIflag=input('Are you scanning? 1 for YES, 2 for NO: ');
end

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
%% WRITE TRIAL-BY-TRIAL DATA TO LOGFILE
%---------------------------------------------------------------
d=clock;
logfile=sprintf('sub%d_emotions.log',subjectID);
fprintf('\nA running log of this session will be saved to %s\n',logfile);
fid=fopen(logfile,'a');
if fid<1,
    error('could not open logfile!');
end;
fprintf(fid,'Started: %s %2.0f:%02.0f\n',date,d(4),d(5));
WaitSecs(1);

%---------------------------------------------------------------
%% DETERMINE ORDER AND GET ORDER VARIABLE
%---------------------------------------------------------------

% seed random number generator
rand('state',sum(100*clock));

% determine version number (based on subjectID)
if (rem(subjectID,2))
    verNum=1;
    if runNum==1,
       orderNum=1;
       inputfile='order1.mat';
    elseif runNum==2,
       orderNum=2;
       inputfile='order2.mat';
    end;
else
    verNum=2;
    if runNum==1,
       orderNum=2;
       inputfile='order2.mat';
    elseif runNum==2,
       orderNum=1;
       inputfile='order1.mat';
    end;
end;
cd trialcodes/emotionscenes
load(inputfile);
cd ../../

%---------------------------------------------------------------
%% TASK CONSTANTS & INITIALIZE VARIABLES
%---------------------------------------------------------------
nTrials=50;     % number of trials (per run)
nShapematch=20;
nStim=40;
nRuns=2;        % number of runs
actualStimulus=cell(nTrials,1);     % actual stimulus displayed for each trial

%---------------------------------------------------------------
%% SET UP INPUT DEVICES
%---------------------------------------------------------------

% from agatha's code, uses's Don's hid_probe.m
fprintf('\n\n===============');
fprintf('\nSUBJECT RESPONSES - CHOOSE DEVICE:')
fprintf('\n===============\n');
inputDevice = hid_probe;

fprintf('\n\n===============');
fprintf('\nEXPERIMENTER RESPONSE - CHOOSE DEVICE:')
fprintf('\n   (if laptop at scanner, "5", if laptop elsewhere, "4", if imac, "5")')
fprintf('\n===============\n');
experimenter_device = hid_probe;

%---------------------------------------------------------------
%% INITIALIZE SCREENS
%---------------------------------------------------------------
AssertOpenGL;
screens=Screen('Screens');
screenNumber=max(screens);
w=Screen('OpenWindow', screenNumber,0,[],32,2);
[wWidth, wHeight]=Screen('WindowSize', w);
xcenter=wWidth/2;
ycenter=wHeight/2;
priorityLevel=MaxPriority(w);
Priority(priorityLevel);

% colors
grayLevel=0;    
black=BlackIndex(w); % Should equal 0.
white=WhiteIndex(w); % Should equal 255.
Screen('FillRect', w, grayLevel);
Screen('Flip', w);

% text
theFont='Arial';
theFontSize=40;
Screen('TextSize',w,40);
theight = Screen('TextSize', w);
Screen('TextFont',w,theFont);
Screen('TextColor',w,white);

% movie defaults
rate=1;     % playback rate
movieSize=.75;     % 1 is fullscreen
maxTime=5;  % maximum time (in secs) to display each movie
dstRect = CenterRect(ScaleRect(Screen('Rect', w),movieSize,movieSize),Screen('Rect', w)); 

% cues
whyCueMALE='Why is he feeling it?';
whyCueFEMALE='Why is she feeling it?';
howCueMALE='How is he showing his feelings?';
howCueFEMALE='How is she showing her feelings?';
shapeCue='Which shape matches?';
fixation='+';

% compute default Y position (vertically centered)
numlines = length(strfind(fixation, char(10))) + 1;
bbox = SetRect(0,0,1,numlines*theight);
[rect,dh,dv] = CenterRect(bbox, Screen('Rect', w));
PosY = dv;
% compute X position for cues
bbox=Screen('TextBounds', w, shapeCue);
[rect,dh,dv] = CenterRect(bbox, Screen('Rect', w));
shapeCuePosX = dh;
bbox=Screen('TextBounds', w, whyCueMALE);
[rect,dh,dv] = CenterRect(bbox, Screen('Rect', w));
whycueMALEPosX = dh;
bbox=Screen('TextBounds', w, whyCueFEMALE);
[rect,dh,dv] = CenterRect(bbox, Screen('Rect', w));
whycueFEMALEPosX = dh;
bbox=Screen('TextBounds', w, howCueMALE);
[rect,dh,dv] = CenterRect(bbox, Screen('Rect', w));
howcueMALEPosX = dh;
bbox=Screen('TextBounds', w, howCueFEMALE);
[rect,dh,dv] = CenterRect(bbox, Screen('Rect', w));
howcueFEMALEPosX = dh;
% compute X position for fixation
bbox=Screen('TextBounds', w, fixation);
[rect,dh,dv] = CenterRect(bbox, Screen('Rect', w));
fixPosX = dh;

%---------------------------------------------------------------
%% ASSIGN RESPONSE KEYS
%---------------------------------------------------------------
if deviceflag==1 % input from button box (can choose this if not scanning)
    respset=['b','y','g','r','t'];
    trigger=KbName('t');
    buttonOne=KbName('b');
    buttonTwo=KbName('y');
    buttonThree=KbName('g');
    buttonFour=KbName('r');
else                % input from keyboard
    respset=['u' 'i' 'o' 'p'];
    trigger=KbName('t'); % won't use this but just in case I accidentally make the code look for it
    buttonOne=KbName('u');
    buttonTwo=KbName('i');
    buttonThree=KbName('o');
    buttonFour=KbName('p');
end
HideCursor;

%---------------------------------------------------------------
%% GET AND LOAD STIMULI
%---------------------------------------------------------------

DrawFormattedText_new(w, 'LOADING', 'center','center',white, 600, 0, 0);
Screen('Flip',w);
fmt='mov';
fmtimg='png';
movieName=cell(nStim,1);
movieMov=zeros(nStim,1);
movieDur=zeros(nStim,1);
movieCode=cell(nStim,1);
cd('stimuli/emotionscenes/SET1');
d=dir(['*.' fmt]);
for i=1:(nStim/2),
    fname=d(i).name;
    tmp=regexprep(fname,'_','');
    movieCode(i)={regexprep(tmp,'.mov','')};
    [movie movieduration fps imgw imgh] = Screen('OpenMovie', w, fname);
    movieMov(i) = movie;
    movieName{i}=fname;
    movieDur(i)=movieduration;
end;
cd('../SET2');
d=dir(['*.' fmt]);
for i=1:(nStim/2),
    fname=d(i).name;
    tmp=regexprep(fname,'_','');
    movieCode(i+20)={regexprep(tmp,'.mov','')};
    [movie movieduration fps imgw imgh] = Screen('OpenMovie', w, fname);
    movieMov(i+20) = movie;
    movieName{i+20}=fname;
    movieDur(i+20)=movieduration;
end;
cd('../shapematch');
d=dir(['*.' fmtimg]);
shapematchStim=cell(nShapematch,1);
shapematchName=cell(nShapematch,1);
shapematchTex=cell(nShapematch,1);
for i=1:nShapematch,
    fname=d(i).name;
    shapematchStim{i}=fname;
    shapematchName{i}=imread(fname);
    shapematchTex{i}=Screen('MakeTexture',w,shapematchName{i});
end;
cd ../../
screen=imread('trainingscreen_emotionalscenes.png');
trainingSCREEN=Screen('MakeTexture',w,screen);
cd ../

%---------------------------------------------------------------
%% iNITIALIZE SEEKER VARIABLE
%---------------------------------------------------------------
% COLUMN KEY
% 1 - trial #
% 2 - condition (1=Why, 2=How, 3=Shapematch)
% 3 - stimulus # (1-40)
% 4 - cue duration
% 5 - stimulus duration
% 6 - intertrial interval (ITI)
% 7 - onset for cue
% 8 - onset for stimulus
% 9 - offset for trial
% 10 - actual onset for stimulus
% 11 - RT to stimulus onset
% 12 - skip index: 0=Valid Trial; 1=Skip (no response)
% 13 - target gender (0=male, 1=female)
% 14 - shape match correct? (1=YES, 0=NO or Not shapematch);
Seeker=zeros(nTrials,14);
Seeker(:,1:9)=trialcode;

% determine target gender for each trial
catchGender=[0 1]';
for i=1:nTrials,
    if Seeker(i,3)==0,
       tmp=randperm(2);
       Seeker(i,13)=catchGender(tmp(1));
    else
        tmpIDX=Seeker(i,3);
        tmp=char(movieCode(tmpIDX));
        Seeker(i,13)=str2num(tmp(5));
    end;
end;

% display GET READY screen
Screen('FillRect', w, grayLevel);
Screen('Flip', w);
WaitSecs(0.25);
if runNum==1,
    Screen('DrawTexture', w, trainingSCREEN);
else
    DrawFormattedText_new(w, 'Run 2 is about to begin. Remember to keep your head as still as possible.', 'center','center',white, 600, 0, 0);
end;
Screen('Flip',w);
%---------------------------------------------------------------
%% WAIT FOR TRIGGER OR KEYPRESS
%---------------------------------------------------------------

% this is taken from Naomi's script
if MRIflag==1, % wait for experimenter keypress (experimenter_device) and then trigger from scanner (inputDevice)
    timer_started = 1;
    while timer_started
        [timerPressed,time] = KbCheck(experimenter_device);
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
        [keyIsDown,secs,keyCode] = KbCheck(experimenter_device);
        if keyIsDown && noresp
            noresp=0;
            triggerOFFSET = secs - STARTscanner;
		anchor=secs;	% anchor timing here
        end
    end
end;
WaitSecs(0.001);

%---------------------------------------------------------------
%% TRIAL PRESENTATION!!!!!!!
%---------------------------------------------------------------

anchor2=GetSecs; 	% just to test difference between trigger anchor and this one

% present fixation cross until first trial cue onset
Screen('DrawText',w,fixation,fixPosX,PosY);
Screen('Flip', w);
WaitSecs('UntilTime', anchor + Seeker(1,7));

try

for t=1:nTrials,
       
    % Present trial cue (in condition and target gender contingent way)
    if Seeker(t,2)==1 && Seeker(t,13)==0,
        Screen('DrawText',w,whyCueMALE,whycueMALEPosX,PosY);
    elseif Seeker(t,2)==1 && Seeker(t,13)==1,
        Screen('DrawText',w,whyCueFEMALE,whycueFEMALEPosX,PosY);
    elseif Seeker(t,2)==2 && Seeker(t,13)==0,
        Screen('DrawText',w,howCueMALE,howcueMALEPosX,PosY);
    elseif Seeker(t,2)==2 && Seeker(t,13)==1,
        Screen('DrawText',w,howCueFEMALE,howcueFEMALEPosX,PosY);
    elseif Seeker(t,2)==3,
        Screen('DrawText',w,shapeCue,shapeCuePosX,PosY);
    end;
    Screen('Flip', w);
    WaitSecs(1.5);
    Screen('FillRect', w, grayLevel);
    Screen('Flip', w);
    % During this period, prepare stimulus for presentation
    if Seeker(t,2)==1 || Seeker(t,2)==2,
        Screen('SetMovieTimeIndex', movieMov(Seeker(t,3)), 0);
        Screen('PlayMovie', movieMov(Seeker(t,3)), rate, 0, 0);
    elseif Seeker(t,2)==3,
        Screen('DrawTexture', w, shapematchTex{Seeker(t,3)});
        shapeTMP=char(shapematchStim(Seeker(t,3)));
        if str2num(shapeTMP(1))==1,
           correctKey=buttonOne;
        elseif str2num(shapeTMP(1))==2,
           correctKey=buttonTwo;
        end;
    end;

    % Present Stimulus
    
   if Seeker(t,2)==1 || Seeker(t,2)==2    % present movie
       
   endMovie=0;
	   WaitSecs('UntilTime', anchor + Seeker(t,8));
       stimStart=GetSecs;
       while (endMovie<2)
            while(1)
                if (abs(rate)>0)
                    [tex] = Screen('GetMovieImage', w, movieMov(Seeker(t,3)), 1);
                    if tex<=0 
                        Screen('SetMovieTimeIndex', movieMov(Seeker(t,3)), Screen('GetMovieTimeIndex', movieMov(Seeker(t,3))) - .01);
                        [tex] = Screen('GetMovieImage', w, movieMov(Seeker(t,3)), 1);
                    elseif (maxTime > 0 && GetSecs - stimStart >= maxTime)
                        reactionTime=0;
                        endMovie=2;
                        break;
                    end;
                    Screen('DrawTexture', w, tex,[],dstRect);
                    Screen('DrawingFinished',w);
                    Screen('Flip', w);
                    Screen('Close', tex);
                end;
                % Has the user stopped with movie with an appropriate button press? 
                endMovie=0;
                [keyIsDown,secs,keyCode]=KbCheck;
                if (keyIsDown==1 && keyCode(buttonOne))
                    reactionTime=secs-stimStart;
                    endMovie=2;
                    Screen('PlayMovie', movieMov(Seeker(t,3)), 0);
                    Screen('CloseMovie', movieMov(Seeker(t,3)));
                    Screen('Flip', w);
                    break;
                end;
            end;
            if reactionTime==0,
                Screen('Flip', w);
                Screen('PlayMovie', movieMov(Seeker(t,3)), 0);
                Screen('CloseMovie', movieMov(Seeker(t,3)));
            end;
        end;
       actualStimulus{t}=movieName(Seeker(t,3));
       Seeker(t,10)=stimStart-anchor;
       Seeker(t,11)=reactionTime;

   else    % present shape matching trial
       Screen('Flip',w, anchor + Seeker(t,8));
       stimStart=GetSecs;
       Seeker(t,10)=stimStart-anchor;
       actualStimulus{t}=shapematchName(Seeker(t,3));
       while GetSecs - stimStart < Seeker(t,5), 
           [keyIsDown,secs,keyCode]=KbCheck(inputDevice);
           if keyIsDown && (keyCode(buttonOne) || keyCode(buttonTwo))
                Seeker(t,11)=secs-stimStart;
                if keyCode(correctKey), 
                    Seeker(t,14)=1;
                end;
                Screen('DrawText',w,fixation,fixPosX,PosY);
                Screen('Flip', w);    
           end;
       end;
   end;
   
    % Present fixation cross during intertrial interval
    Screen('DrawText',w,fixation,fixPosX,PosY);
    Screen('Flip', w);
    noresp=1;
    if Seeker(t,11)==0,   % if they did not respond to stimulus, look for button press
       while (GetSecs - anchor < Seeker(t,9)) && noresp
           [keyIsDown,secs,keyCode]=KbCheck(inputDevice);
           if keyIsDown && (keyCode(buttonOne) || keyCode(buttonTwo)),  
                Seeker(t,11)=secs-stimStart;
                noresp=0;
                if Seeker(t,2)==3,                  
                    Seeker(t,14)=keyCode(correctKey);
                end;
           end;
       end;
    end;
	WaitSecs('UntilTime', anchor + Seeker(t,9));

    % Should this trial be skipped in analysis? (i.e. because of no respose)
    if Seeker(t,11)==0,
       Seeker(t,12)=1;
    end;
   
    % PRINT TRIAL INFO TO LOG FILE
    try,
        fprintf(fid,'%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n',Seeker(t,1:12));
    catch,   % if sub responds weirdly, trying to print the resp crashes the log file...instead print "ERR"
        fprintf(fid,'ERROR SAVING THIS TRIAL\n');
    end;
end;    % end of trial loop

catch
    Screen('CloseAll');
    Priority(0);
    psychrethrow(psychlasterror);
end;

%---------------------------------------------------------------
%% SAVE DATA
%---------------------------------------------------------------
d=clock;
outfile=sprintf('emotions_%d_run%d_%s_%02.0f-%02.0f.mat',subjectID,runNum,date,d(4),d(5));

cd data
try
    save(outfile, 'Seeker','actualStimulus','subjectID','runNum','orderNum','verNum','triggerOFFSET'); % if give feedback, add:  'error', 'rt', 'count_rt',
catch
	fprintf('couldn''t save %s\n saving to emotions_behav.mat\n',outfile);
	save act4;
end;
cd ..

%---------------------------------------------------------------
%% AFTER RUN 1, CHECK IN WITH SUBJECT
%---------------------------------------------------------------
if runNum==1,
    DrawFormattedText_new(w, 'The first run is over. If you are ready to begin the second run, press #1. If you have a question or concern, press #2.', 'center','center',white, 600, 0, 0);
    Screen('Flip',w);
    noresp=1;
    while noresp
        [keyIsDown,secs,keyCode] = KbCheck(inputDevice);
        if keyIsDown && (keyCode(buttonOne) || keyCode(buttonTwo)),  
            noresp=0;
            if keyCode(buttonOne),
                fprintf('\n---------------------------');
                fprintf('\n-SUBJECT IS READY TO MOVE ON-');
                fprintf('\n---------------------------\n');
            elseif keyCode(buttonTwo),
                fprintf('\n----------------------');
                fprintf('\n-SUBJECT HAS A QUESTION-');
                fprintf('\n----------------------\n');
            end;
        end;
    end;
end;

%---------------------------------------------------------------
%% CLOSE SCREENS
%---------------------------------------------------------------
Screen('CloseAll');
Priority(0);
ShowCursor;
