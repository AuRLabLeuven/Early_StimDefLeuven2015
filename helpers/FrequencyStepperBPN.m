function Fsweep=FrequencyStepperBPN(T, EXP, Prefix, Flag, Flag2);
% 
% Note: This function is a form modified of FrequencyStepperARMIN
% 
% FrequencyStepperBPN - generic frequency stepper panel for stimulus GUIs.
%   F=FrequencyStepperBPN(Title, EXP) returns a GUIpanel F allowing the 
%   user to specify a series of frequencies, using either be logarithmic or
%   linear spacing.  The Guipanel F has title Title. EXP is the experiment 
%   definition, from which the number of DAC channels used (1 or 2) is
%   determined.
%
%   The paramQuery objects contained in F are named: 
%         StartFreq: starting frequency in Hz
%     StepFrequency: step in Hz or Octaves (toggle unit)
%      EndFrequency: end frequency in Hz
%        AdjustFreq: toggle selecting which of the above params to adjust
%                    in case StepFrequency does not fit exactly.
%       FreqTolMode: toggle selecting whether frequencies should be
%                    realized exactly, or whether memory-saving rounding is
%                    allowed.
%       LowPolarity: the sign of the correlation below the flip frequency
%        CutoffSide: to select which edge to vary during the cycles;
%                    L varies the lower edge, H varies the higher edge
%         PowerCorr: select(Y/N) to correct the level of the signal to a
%                    constant power level
%                    
%   FrequencyStepperBPN is a helper function for stimulus generators like 
%   makestimBPN.
% 
%   F=FrequencyStepperBPN(Title, ChanSpec, Prefix) prepends the string Prefix
%   to the paramQuery names, e.g. StartFreq -> ModStartFreq, etc.
%
%   Use EvalFrequencyStepperBPN to read the values from the queries and to
%   compute the actual frequencies specified by the above step parameters.
%
%   See StimGUI, GUIpanel, EvalFrequencyStepperBPN, makestimBPN.

[Prefix, Flag, Flag2] = arginDefaults('Prefix/Flag/Flag2', '');

% # DAC channels and Flag2 determines the allowed multiplicity of user-specied numbers
if isequal('Both', EXP.AudioChannelsUsed) && ~isequal('nobinaural', Flag2), 
    Nchan = 2;
    PairStr = ' Pairs of numbers are interpreted as [left right].';
else, % single Audio channel
    Nchan = 1;
    PairStr = ''; 
end
ClickStr = ' Click button to select ';

%==========frequency GUIpanel=====================
Fsweep = GUIpanel('Fsweep', T);
StartFreq = ParamQuery([Prefix 'StartFreq'], 'start:', '15000.5 15000.5', 'Hz', ...
    'rreal/positive', ['Starting frequency of series.' PairStr], Nchan);
StepFreq = ParamQuery([Prefix 'StepFreq'], 'step:', '12000', {'Hz' 'Octave'}, ...
    'rreal/positive', ['Frequency step of series.' ClickStr 'step units.'], Nchan);
EndFreq = ParamQuery([Prefix 'EndFreq'], 'end:', '12000.1 12000.1', 'Hz', ...
    'rreal/positive', ['Last frequency of series.' PairStr], Nchan);
AdjustFreq = ParamQuery([Prefix 'AdjustFreq'], 'adjust:', '', {'none' 'start' 'step' 'end'}, ...
    '', ['Choose which parameter to adjust when the stepsize does not exactly fit the start & end values.'], 1,'Fontsiz', 8);
Tol = ParamQuery([Prefix 'FreqTolMode'], 'acuity:', '', {'economic' 'exact'}, '', [ ...
    'Exact: no rounding applied;', char(10), 'Economic: allow slight (<1 part per 1000), memory-saving rounding of frequencies;'], ...
    1, 'Fontsiz', 8);
CutoffSide = ParamQuery('CutoffSide', 'Select which edge to vary:', '', {'L' 'H'}, ...
    '', 'L varies the lower side, making a HPF, and vice versa.');
PowerCorr = ParamQuery('PowerCorr', 'Power Correction?', '', {'Y' 'N'}, ...
    '', 'Select whether the signal should be corrected to a constant power level or not.');
FullBand = ParamQuery('FullBand', 'Full Band Noise?', '', {'Y' 'N'}, ...
    '', 'Send Full Band Noise as a stimulus?');

Fsweep = add(Fsweep, StartFreq);
Fsweep = add(Fsweep, StepFreq, alignedwith(StartFreq));
Fsweep = add(Fsweep, EndFreq, alignedwith(StepFreq));
Fsweep = add(Fsweep, AdjustFreq, nextto(StepFreq), [10 0]);
Fsweep = add(Fsweep, CutoffSide, below(EndFreq), [0 0]);
Fsweep = add(Fsweep, PowerCorr, below(CutoffSide), [0 0]);
Fsweep = add(Fsweep, FullBand, below(PowerCorr), [0 0]);
if ~isequal('notol', Flag),
    Fsweep = add(Fsweep, Tol, alignedwith(AdjustFreq) , [0 -10]);
end





