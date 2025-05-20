clear; close all; clc;

cfg = config(); 
cfg.NumBits = 15000;
cfg.pilot_length = 25;
cfg.pilotK = 12;

cfg.OSF = ; % depends on the setup

%% signal creation

bitstream = randi([0 1], 1, cfg.NumBits); % Generate random bits
modulatedSignal = mapping(bitstream, cfg.mapping_params); % Mapping
signalOut = RRC_filtering(modulatedSignal, cfg.RRC_params, 0); % RRC filtering

cfg.pilot = modulatedSignal(1:cfg.pilotK);

%% signal processing

signalIn = ;

% first pass to estimate the CFO
afterRRC = RRC_filtering(signalIn, cfg.RRC_params, 1); % RRC filtering
afterGardner = gardner(afterRRC, cfg, 1); % Gardner synchronisation
[CFOest, ~] = frame_aquisition(afterGardner, cfg, 0); % Frame acquisition

% correct the CFO
t = (0:length(signalIn)-1)/cfg.RRC_params.fs;
CFOcorrected = signalIn .* exp(-1j*2*pi*CFOest*t);
% continue the processing
afterRRC = RRC_filtering(CFOcorrected, cfg.RRC_params, 1); % RRC filtering
afterGardner = gardner(afterRRC, cfg, 1); % Gardner synchronisation
downsampledSignal = downsample(afterGardner, cfg); % Downsampling
demodulatedSignal = demapping(downsampledSignal, cfg.mapping_params); % Demapping

% compare the demodulated signal with the original bitstream
BER = sum(bitstream ~= demodulatedSignal) / length(bitstream); % Bit Error Rate
disp(['Bit Error Rate: ', num2str(BER)]);

