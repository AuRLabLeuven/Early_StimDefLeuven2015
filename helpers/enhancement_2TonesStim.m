function P = enhancement_2TonesStim(P, varargin);
%   P = enhancement_harmonicStim(P) computes the waveforms of tonal stimulus
%   The carrier frequencies are given by P.Fcar [Hz], which is a column
%   vector (mono) or Nx2 vector (stereo). The remaining parameters are
%   taken from the parameter struct P returned by GUIval. The Experiment
%   field of P specifies the calibration, available sample rates etc
%   In addition to Experiment, the following fields of P are used to
%   compute the waveforms

%    FreqTolMode: tolerance mode for freq rounding; equals exact|economic.
%            ISI: onset-to-onset inter-stimulus interval in ms

%     testOnsetDelay: silent interval (ms) preceding onset (common to both DACs)
%       testBurstDur: burst duration in ms including ramps
%        testRiseDur: duration of onset ramp
%        testFallDur,: duration of offset ramp

%     condOnsetDelay: silent interval (ms) preceding onset (common to both DACs)
%       condBurstDur: burst duration in ms including ramps
%        condRiseDur: duration of onset ramp
%        condFallDur: duration of offset ramp

%            DAC: left|right|both active DAC channel(s)
%            SPL: carrier sound pressure level [dB SPL]
%        delta_T: time between conditoner and test
%             BF: notch center frequency
%           minf: minum frequency
%           maxf: maximum frequency
%         dBdiff: dB difference between condtioner and test
%         notchW



%   Most of these parameters may be a scalar or a [1 2] array, or
%   a [Ncond x 1] or [Ncond x 2] or array, where Ncond is the number of
%   stimulus conditions. The allowed number of columns (1 or 2) depends on
%   the character of the paremeter, i.e., whether it may have separate
%   values for the left and right DA channel. The exceptions are
%   FineITD, GateITD, ModITD, and ISI, which which are allowed to have
%   only one column, and SPLtype and FreqTolMode, which are a single char
%   strings that apply to all of the conditions.


% %TODO2, that's at the end
% if nargin>1
%     if isequal('GenericStimParams', varargin{1}),
%         P = local_genericstimparams(P);
%         return;
%     else,
%         error('Invalid second input argument.');
%     end
% end
% S = [];
% % test the channel restrictions described in the help text
% error(local_test_singlechan(P,{'FineITD', 'GateITD', 'ModITD', 'ISI'}));

% There are Ncond=size(Fcar,1) conditions and Nch DA channels.
% Cast all numerical params in Ncond x Nch size, so we don't have to check
% sizes all the time.

% P.polarity=1;

[db_comp2,BF1,delta_T,SPL1,condFallDur,...
    condRiseDur,condBurstDur,condOnsetDelay,...
    testFallDur,testRiseDur,testBurstDur,testOnsetDelay,ISI,sideT,polarity,BF2,SPL2,probe_alone]=...
    SameSize(P.db_comp2,P.BF1,P.delta_T,P.SPL1,P.condFallDur,...
    P.condRiseDur,P.condBurstDur,P.condOnsetDelay,...
    P.testFallDur,P.testRiseDur,P.testBurstDur,P.testOnsetDelay,P.ISI,P.sideT,P.polarity,P.BF2,P.SPL2,P.probe_alone);

% if P.DAC(1)=='B'
%     notchW = [notchW,notchW];
% end
% Restrict the parameters to the active channels. If only one DA channel is
% active, DAchanStr indicates which one.
[DAchanStr,db_comp2,BF1,delta_T,SPL1,condFallDur,...
    condRiseDur,condBurstDur,condOnsetDelay,...
    testFallDur,testRiseDur,testBurstDur,testOnsetDelay,ISI,sideT,polarity,BF2,SPL2,probe_alone]=...
    channelSelect(P.DAC, 'LR',db_comp2,BF1,delta_T,SPL1,condFallDur,...
    condRiseDur,condBurstDur,condOnsetDelay,...
    testFallDur,testRiseDur,testBurstDur,testOnsetDelay,ISI,sideT,polarity,BF2,SPL2,probe_alone);


% find the single sample rate to realize all the waveforms while  ....
Fsam = sampleRate(max([BF1,BF2]), P.Experiment); % accounting for recording requirements minADCrate


% now compute the stimulus waveforms condition by condition, ear by ear.
[Ncond, Nchan] = size(BF2);
for ichan=1:Nchan,
    chanStr = DAchanStr(ichan); % L|R
    for icond=1:Ncond,
        % select the current element from the param matrices. All params ...
        % are stored in a (iNcond x Nchan) matrix. Use a single index idx
        % to avoid the cumbersome A(icond,ichan).
        idx = icond + (ichan-1)*Ncond;
        % compute the waveform
        if length(DAchanStr)==1
            [w,duration] = local_WaveformMono(chanStr, Fsam,idx,...
                BF1(idx),delta_T(idx),SPL1(idx),condBurstDur(idx),...
                BF2,SPL2,...
                db_comp2(idx),condFallDur(idx),condRiseDur(idx),condOnsetDelay(idx),...
                testFallDur(idx),testRiseDur(idx),testBurstDur(idx),testOnsetDelay(idx),ISI(idx),polarity(idx),P,probe_alone(idx));
        else
%             [w,duration] = local_WaveformBinaural(chanStr, Fsam,idx,...
%                 dBdiff,BF,delta_T,SPL,condBurstDur,notchW,...
%                 minf(idx),maxf(idx),condFallDur(idx),condRiseDur(idx),condOnsetDelay(idx),...
%                 testFallDur(idx),testRiseDur(idx),testBurstDur(idx),testOnsetDelay(idx),ISI(idx),polarity(idx),P,sideT(idx),sband(idx),stim_type(idx),probe_alone(idx));
%             
            
        end
        P.Waveform(icond,ichan) =w;
        P.Duration(icond,ichan) =duration;
        P.SPL = P.Waveform(icond,ichan).SPL
    end
end

P = structJoin(P, CollectInStruct(Fsam));
end

%here is where GenricParamsCall
% P.GenericParamsCall = {fhandle(mfilename) struct([]) 'GenericStimParams'};


%===================================================
%===================================================

function  [W,duration] = local_WaveformMono(DAchan, Fsam,idx,...
    BF1,delta_T,SPL1,condBurstDur,BF2s,SPL2s,...
    db_comp2,condFallDur,condRiseDur,condOnsetDelay,...
    testFallDur,testRiseDur,testBurstDur,testOnsetDelay,ISI,polarity,P,probe_alone);


SPL2 = SPL2s(idx);
BF2 = BF2s(idx);


% Generate the waveform from the elementary parameters
%=======TIMING, DURATIONS & SAMPLE COUNTS=======
% get sample counts of subsequent segments
nsamp_cond = NsamplesofChain([condBurstDur], Fsam/1e3);
nsamp_test = NsamplesofChain([testBurstDur], Fsam/1e3);
nsamp_silence = NsamplesofChain([delta_T], Fsam/1e3);
nsamp_total = NsamplesofChain([condBurstDur,testBurstDur,delta_T], Fsam/1e3);

dt = 1e3/Fsam; % sample period in ms

% if Yvars is the first value, no conditioner
% so Yval should always be a param of the conditioner
Yvars = unique(eval([P.Yname,'s']));
eval(['idxY=find(Yvars==',P.Yname,');'])
Xvars = unique(eval([P.Xname,'s']));
eval(['idxX=find(Xvars==',P.Xname,');'])




% BF2,SPL2

SPLcond=SPL2;
freqcond = BF2;
%SPL=0 handles the case when there is no conditioner
if sign(Xvars(idxX))==-1
    % if Xvars(idxX)==-1
    conditioner=zeros(nsamp_cond,1);
else
%     phase = 2*pi*rand(1,length(cfs));
    phase = load('phase2');
    phase= phase.phase;
    [DL, Dphi] = calibrate(P.Experiment, Fsam, DAchan, freqcond);
    Ampcond = dB2A(SPLcond+DL)*sqrt(2); % calibrated linear amplitude
    conditioner = tonecomplex(Ampcond, freqcond, phase(1), Fsam, condBurstDur); % ungated waveform buffer; starting just after OnsetDelay
    conditioner = ExactGate(conditioner, Fsam, condBurstDur, 0, condRiseDur, condFallDur);
end
phase = load('phase2');
phase= phase.phase;

if db_comp2=='C'
SPLtest=[SPL2,SPL1];
else
   SPLtest=[SPL1,SPL1]; 
end
freqtest = [abs(BF2),BF1]; %BF2 should always be present and positive


%make test

[DL, Dphi] = calibrate(P.Experiment, Fsam, DAchan, freqtest);
Amptest = dB2A(SPLtest+DL)*sqrt(2); % calibrated linear amplitude

if probe_alone==1
Amptest(find(freqtest~=BF1))=0;
end

% Amptest, freqtest, phase(1:2)
test = tonecomplex(Amptest, freqtest, phase(1:2), Fsam, testBurstDur); % ungated waveform buffer; starting just after OnsetDelay
test = ExactGate(test, Fsam, testBurstDur, 0, testRiseDur, testFallDur);

%make silence in between
silence = zeros(nsamp_silence,1);

%make stimulus (column vector)
if sign(Xvars(idxX))==1
    w = [conditioner;silence;test];
else
    w = [conditioner;silence;test];
end
w = polarity*w;
% 




% display([SPL2,BF2,delta_T,SPL1,BF1])
% % 
% t = linspace(0,length(w)*dt,length(w));
% subplot(2,2,1)
% plot(t,w)
% subplot(2,2,2)
% absfft = abs(fft(conditioner));
% freq = linspace(0,Fsam,length(absfft));
% plot(freq,absfft)
% xlim([100,10000])
% subplot(2,2,3)
% absfft2 = abs(fft(test));
% freq = linspace(0,Fsam,length(absfft2));
% plot(freq,absfft2)
% xlim([100,10000])
% subplot(2,2,4)
% plot(conditioner)
% var(absfft),var(absfft2)
% xlim([1000,3000])
% pause
% 
% clf


duration = ceil(length(w)*dt);

% FROM NOISEconvert to waveform object & provide heading & trailing silence
Nsam = CollectInStruct(nsamp_cond,nsamp_test,nsamp_silence,nsamp_total); %differnet number of smaples
duration = CollectInStruct(delta_T,condFallDur,...
    condRiseDur,condBurstDur,condOnsetDelay,...
    testRiseDur,testBurstDur,testOnsetDelay); %differnet durations
SPL = max([SPL2,SPL1]);
test_alone_is_delayed = 1;
P = CollectInStruct(test_alone_is_delayed,polarity,Nsam,duration,SPLtest,db_comp2,SPL,BF1,SPL1,BF2,SPL2,SPLcond,ISI,freqtest,freqcond,phase); % store stim parameters for debugging purposes


NsamOnsetDelay = round(condOnsetDelay/dt);
W = Waveform(Fsam, DAchan, NaN, max([SPL2,SPL1]), P, {0 w}, [NsamOnsetDelay 1]);
W = AppendSilence(W, ISI); % pas zeros to ensure correct ISI
end


function  [W,duration] = local_WaveformBinaural(DAchan, Fsam,idx,...
    dBdiffs,BFs,delta_Ts,SPLs,condBurstDurs,Ws,...
    minf,maxf,condFallDur,condRiseDur,condOnsetDelay,...
    testFallDur,testRiseDur,testBurstDur,testOnsetDelay,ISI,polarity,P,sideT,sband,stim_type,probe_alone);



dBdiff = dBdiffs(idx);
BF =BFs(idx);
delta_T=delta_Ts(idx);
SPL=SPLs(idx);
condBurstDur=condBurstDurs(idx);
W=Ws(idx);

% Generate the waveform from the elementary parameters
%=======TIMING, DURATIONS & SAMPLE COUNTS=======
% get sample counts of subsequent segments
nsamp_cond = NsamplesofChain([condBurstDur], Fsam/1e3);
nsamp_test = NsamplesofChain([testBurstDur], Fsam/1e3);
nsamp_silence = NsamplesofChain([delta_T], Fsam/1e3);
nsamp_total = NsamplesofChain([condBurstDur,testBurstDur,delta_T], Fsam/1e3);



dt = 1e3/Fsam; % sample period in ms

%if Yvars is the first value, no conditioner
%so Yval should always be a param of the conditioner
Yvars = unique(eval([P.Yname,'s']));
eval(['idxY=find(Yvars==',P.Yname,');'])
Xvars = unique(eval([P.Xname,'s']));
eval(['idxX=find(Xvars==',P.Xname,');'])


%make conditioner
if abs(W)==100
    W=0;
end
cfs= round(2.^linspace(log2(BF/8),log2(BF*8),(6*10)+1));
cfs = cfs(find(cfs>=minf));
cfs = cfs(find(cfs<=maxf));
[freqtest,idx_kept_test,iBF]=remove_comp(BF,abs(W),cfs);
freqcond = setdiff(freqtest,BF);

% freqtest
% freqcond

idx_kept_cond = setdiff(idx_kept_test,iBF);
phase = 2*pi*rand(1,length(cfs));

SPLcond=SPL;
SPLtest=SPL+dBdiff;

if sign(Xvars(idxX))==1 & DAchan~=sideT %if only conditioner present at that side
    [DL, Dphi] = calibrate(P.Experiment, Fsam, DAchan, freqcond);
    Ampcond = dB2A(SPLcond+DL)*sqrt(2); % calibrated linear amplitude
    if sband=='H'
        Ampcond(find(freqcond<BF))=0;
    elseif sband=='L'
        Ampcond(find(freqcond>BF))=0;
    end
    conditioner = toneComplex(Ampcond, freqcond, phase(idx_kept_cond), Fsam, condBurstDur); % ungated waveform buffer; starting just after OnsetDelay
    conditioner = exactGate(conditioner, Fsam, condBurstDur, 0, condRiseDur, condFallDur);
    w = [conditioner];
    
elseif  DAchan==sideT  % if test at that side (test not delayed)
    [DL, Dphi] = calibrate(P.Experiment, Fsam, DAchan, freqtest);
    Amptest = dB2A(SPLtest+DL)*sqrt(2); % calibrated linear amplitude
    if sband=='H'
        Amptest(find(freqtest<BF))=0;
    elseif sband=='L'
        Amptest(find(freqtest>BF))=0;
    end
    test = toneComplex(Amptest, freqtest, phase(idx_kept_test), Fsam, testBurstDur); % ungated waveform buffer; starting just after OnsetDelay
    test = exactGate(test, Fsam, testBurstDur, 0, testRiseDur, testFallDur);
    if sign(Xvars(idxX))==1 %if  conditioner in stimulus, test is delayed
        %delay is duration of conditioner + deltaT
        silence = zeros(nsamp_silence+nsamp_cond,1);
        w = [silence;test]; %not delayed
    else
        w = [silence;test]; %not delayed
    end
else
    w=[0;0;0;0];
end

w = polarity*w;
%make stimulus (column vector)


% Xvars(idxX),W
% t = linspace(0,length(w)*dt,length(w));
% subplot(2,2,1)
% plot(t,w)
% subplot(2,2,2)
% absfft = abs(fft(conditioner));
% freq = linspace(0,Fsam,length(absfft));
% plot(freq,absfft)
% xlim([0,20000])
% subplot(2,2,3)
% absfft2 = abs(fft(test));
% freq = linspace(0,Fsam,length(absfft2));
% plot(freq,absfft2)
% xlim([0,20000])
% subplot(2,2,4)
% plot(conditioner)
% var(absfft),var(absfft2)
% xlim([0,16000])
% pause
% clf

duration = ceil(length(w)*dt);

% FROM NOISEconvert to waveform object & provide heading & trailing silence
Nsam = CollectInStruct(nsamp_cond,nsamp_test,nsamp_silence,nsamp_total); %differnet number of smaples
duration = CollectInStruct(delta_T,condFallDur,...
    condRiseDur,condBurstDur,condOnsetDelay,...
    testRiseDur,testBurstDur,testOnsetDelay); %differnet durations
test_alone_is_delayed = 1;
P = CollectInStruct(test_alone_is_delayed,polarity,Nsam,duration,SPLtest,minf,maxf,BF,SPL,SPLcond,ISI,freqtest,freqcond,sband,stim_type); % store stim parameters for debugging purposes

NsamOnsetDelay = round(condOnsetDelay/dt);
W = waveform(Fsam, DAchan, NaN, SPL, P, {0 w}, [NsamOnsetDelay 1]);
W = appendSilence(W, ISI); % pas zeros to ensure correct ISI
end