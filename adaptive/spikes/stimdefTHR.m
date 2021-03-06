function Params = stimdefTHR(EXP)

%==========Carrier frequency GUIpanel=====================
Fsweep = FrequencyStepper('Frequency range', EXP,'','','nobinaural');
% ---Levels
Levels = SPLstepper('SPL range', EXP'','','nobinaural');
% ---Presentation
Pres = PresentationPanelTHR;
% Pres = PresentationPanelTHR_Geisler;
% ---REC STOP
RecStop = GUIpanel('RecStop', '');
Rec = ActionButton('Rec', 'REC', 'REC', 'Start the recording of the threshold curve', @(Src,Ev,LR)THRstart([]), 'BackgroundColor', [0.65 0.75 0.7]);
Stop = ActionButton('Stop', 'STOP', 'STOP', 'Stop the recording of the threshold curve', @(Src,Ev,LR)THRstop(), 'BackgroundColor', [0.65 0.75 0.7]);
Rec0SR = ActionButton('REC_SR', 'REC: No SR', 'REC: No SR', 'Start the recording of the threshold curve with a custom Spike Rate', ...
    @(Src,Ev,LR)THRstart([],-1), 'BackgroundColor', [0.65 0.75 0.7]);               % Gowtham 7/9/20: Rec: 0 SR button was renamed
RecStop = add(RecStop, Rec, 'cornering', [5 -15]);
RecStop = add(RecStop, Stop, nextto(Rec), [5 0]);
RecStop = add(RecStop,Rec0SR,nextto(Stop), [5 0]);
%====================
Params = GUIpiece('Params'); % upper half of GUI: parameters
Params = add(Params, Fsweep);
Params = add(Params, Levels, nextto(Fsweep), [10 0]);
Params = add(Params, Pres, nextto(Levels) ,[5 0]);
Params = add(Params, RecStop, below(Fsweep) ,[35 20]);