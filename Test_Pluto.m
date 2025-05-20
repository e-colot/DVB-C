clear; close all; clc;

%% PLUTO ACQUISITION

cfg = config(); 
cfg.NumBits = 15000;
cfg.pilot_length = 25;
cfg.pilotK = 12; 
cfg.OSF = 100; % depends on the setup
fcarrier = cfg.fc;
Rsamp = cfg.RRC_params.bandwidth;

% Transmitter system object
txPluto = sdrtx("Pluto",...
"RadioID", "usb:0",...
"Gain", -10,... % -90 to 0 dB
"CenterFrequency", fcarrier,... % 335e6 to 3.8e9 [Hz]
"BasebandSampleRate", Rsamp); % 60e3 to 60e6 [Hz]

% Receiver system object
rxPluto = sdrrx("Pluto",...
"RadioID", "usb:0",...
"CenterFrequency", fcarrier,... % 335e6 to 3.8e9 [Hz]
"GainSource", "Manual",... % Manual, AGC Slow Attack
"Gain", 10,... % -4 to 71 [dB]
"BasebandSampleRate", Rsamp,... % 60e3 to 60e6 [Hz]
"EnableBurstMode", true,...
"NumFramesInBurst", 1,...
"SamplesPerFrame", 200000,...
"OutputDataType", "double" );

%% signal creation

bitstream = randi([0 1], 1, cfg.NumBits); % Generate random bits
modulatedSignal = mapping(bitstream, cfg.mapping_params); % Mapping
signalOut = RRC_filtering(modulatedSignal, cfg.RRC_params, 0); % RRC filtering

cfg.pilot = modulatedSignal(1:cfg.pilotK);

%% SIGNAL PROCESSING

buffer_tx = signalOut;


% Periodic transmission
txPluto.transmitRepeat(buffer_tx);

% Burst reception
[data_rx,datavalid,overflow] = rxPluto();

if (overflow)
disp("Samples dropped");
end

signalIn = data_rx(:) ;

% first pass to estimate the CFO
afterRRC = RRC_filtering(signalIn, cfg.RRC_params, 1); % RRC filtering
afterGardner = gardner2(afterRRC, cfg, 1); % Gardner synchronisation
[CFOest, ~] = frame_aquisition(afterGardner, cfg, 0); % Frame acquisition

% correct the CFO
t = (0:length(signalIn)-1)/cfg.RRC_params.fs;
CFOcorrected = signalIn .* exp(-1j*2*pi*CFOest*t);
% continue the processing
afterRRC = RRC_filtering(CFOcorrected, cfg.RRC_params, 1); % RRC filtering
afterGardner = gardner2(afterRRC, cfg, 1); % Gardner synchronisation
downsampledSignal = downsample(afterGardner, cfg); % Downsampling
demodulatedSignal = demapping(downsampledSignal, cfg.mapping_params); % Demapping

% compare the demodulated signal with the original bitstream
BER = sum(bitstream ~= demodulatedSignal) / length(bitstream); % Bit Error Rate
disp(['Bit Error Rate: ', num2str(BER)]);

