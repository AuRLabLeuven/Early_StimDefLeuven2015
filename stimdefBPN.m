function Params = stimdefBPN(EXP)
% stimdefBPN - definition of stimulus and GUI for BPN stimulus paradigm
%    P=stimdefBPN(EXP) returns the definition for the BPN
%    stimulus paradigm. The definition P is a GUIpiece that can be rendered
%    by GUIpiece/draw. Stimulus definition like stimmdefBPN are usually
%    called by StimGUI, which combines the parameter panels with
%    a generic part of stimulus GUIs. The input argument EXP contains 
%    Experiment definition, which co-determines the realization of
%    the stimulus: availability of DAC channels, calibration, recording
%    side, etc.
%
%    See also stimGUI, stimDefDir, Experiment, makestimBPN, stimparamsARMIN.

PairStr = ' Pairs of numbers are interpreted as [left right].';
ClickStr = ' Click button to select ';
% Carrier frequency GUIpanel
Fsweep = FrequencyStepperARMIN_new('flip frequency',EXP);

% Noise
% Noise = NoisePanelARMIN_new('noise param', EXP);
% Noise
Noise = NoisePanel('Noise', EXP,'','Reverse'); % exclude reverse option in noise panel
% Fix SPL unit
noiseChildren = Noise.Children;
for ch = 1:length(noiseChildren)
    if isa(noiseChildren{ch},'ParamQuery') && strcmp(noiseChildren{ch}.Name,'SPL')
        Noise.Children{ch}.Unit = 'dB SPL';
        break;
    end
end

% Const Channel
%Const = ConstChannelPanelARMIN('Constant Channel');

% Varied Channel
%Var = VariedChannelARMIN('Varied Channel');

% ---Durations
Dur = DurPanel('-', EXP);

% ---Pres
Pres = PresentationPanel_XY('Freq','SPL');

% ---Summary
summ = Summary(17);

%====================
Params=GUIpiece('Params'); % upper half of GUI: parameters
Params = add(Params, summ);
Params = add(Params, Fsweep, nextto(summ), [10 0]);
Params = add(Params, Noise, below(Fsweep), [0 0]);
Params = add(Params, Var, nextto(Fsweep), [10 0]);
Params = add(Params, Const, below(Var), [0 0]);
Params = add(Params, Dur, nextto(Var) ,[10 0]);
Params = add(Params, Pres, below(Dur) ,[-110 0]);
Params = add(Params, PlayTime, below(Pres) , [-10 0]);




