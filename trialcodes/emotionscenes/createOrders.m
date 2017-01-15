% CREATE TRIAL CODE FOR EMOTIONAL FACES STUDY
clear all; clc;

% define scan information
nTrials=50;
TR=2;
nSlices=36;
% define trial durations
stimDur=5;
cueDur=2;
trialDur=7;
restBegin = 2;           
restEnd = 6;                
% define ITI information
meanITI=3;
minITI=2;
maxITI=5;
% get optimized condition order 
cd optimizedOrder
load ORDER
cd ..
tmp=ORDER;
ORDER(tmp==4)=3;
whyIDX=find(ORDER==1);
howIDX=find(ORDER==2);
shapeIDX=find(ORDER==3);
% create stimulus order sets
allStimuli=randperm(40)';
stimulusSET1=allStimuli(allStimuli<21);
stimulusSET2=allStimuli(allStimuli>20);

% define a vector of values representing jitter values
jitSample=[minITI:(TR/nSlices):maxITI];
jitSample=cat(2,jitSample,[minITI:(TR/nSlices):(maxITI-1)],[minITI:(TR/nSlices):(maxITI-2)],[minITI:(TR/nSlices):(maxITI-2)],[minITI:(TR/nSlices):(maxITI-2)]);
nSample=length(jitSample);
% find distribution of jitters with the desired mean
goodJit=0;
while goodJit==0,
    tempJit=Shuffle(jitSample);
    jitters=tempJit(1:nTrials-1);
    if mean(jitters)==meanITI,
       goodJit=1;
    end;
end;

% define TRIALCODE variable
% 1 - trial #
% 2 - condition (1=Why, 2=How, 3=CatchWhy, 4=CatchHow)
% 3 - stimulus # (1-40)
% 4 - cue duration
% 5 - stimulus duration
% 6 - intertrial interval (ITI)
% 7 - onset for cue
% 8 - onset for stimulus
% 9 - offset for trial
trialcode=zeros(nTrials,9);
trialcode(:,1)=1:nTrials;
trialcode(:,2)=ORDER;
% (stimulus orders defined below)
trialcode(:,4)=cueDur;
% now define stimulus durations
for i=1:nTrials,
     if trialcode(i,2)==3 || trialcode(i,2)==4;
         trialcode(i,5)=3;
     else
         trialcode(i,5)=5;
     end;
end;
trialcode(1:end-1,6)=jitters;
trialcode(end,6)=restEnd;
trialcode(1,7)=restBegin;
trialcode(1,8)=restBegin+cueDur;

for i=2:nTrials,
    trialcode(i,7)=sum(trialcode(i-1,4:7));
    trialcode(i,8)=trialcode(i,7)+cueDur;
end;

for i=1:nTrials,
    trialcode(i,9)=sum(trialcode(i,4:7));
end;

tmpOrder=randperm(20)';
% define two orders based on different sets of stimuli
tmpTrialcode=trialcode;
% first order
trialcode(whyIDX,3)=stimulusSET1;
trialcode(howIDX,3)=stimulusSET2;
trialcode(shapeIDX,3)=tmpOrder(1:10);
save order1.mat trialcode

% second order
trialcode(whyIDX,3)=stimulusSET2;
trialcode(howIDX,3)=stimulusSET1;
trialcode(shapeIDX,3)=tmpOrder(11:20);
save order2.mat trialcode




