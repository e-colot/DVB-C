clear; close all; clc;

%seed = abs(round(1000000*randn(1, 1)));
%seed = 487012;
%rng(seed); % Set seed for reproducibility

cfg = config();

K = 30;
N = 50; 
pilotCnt = 10;

Nbits = N * cfg.mapping_params.Nbps; 

EbN0Vector = linspace(cfg.EbN0_interval(1), cfg.EbN0_interval(2), cfg.BER_resolution);

EbN0 = 10; % dB

%% signal generation
cfg.pilot_length = N;
cfg.pilotK = K;
cfg.pilot = randi([0 1], 1, Nbits);

cfg.NumBits = cfg.pilot_length*cfg.mapping_params.Nbps*50;

pilotPos = linspace(1, cfg.NumBits, pilotCnt+2)./cfg.mapping_params.Nbps;
pilotPos = round(pilotPos(2:end-1)+1); 

mappedPilot = mapping(cfg.pilot, cfg.mapping_params);

xbits = randi([0 1], 1, cfg.NumBits);
x = mapping(xbits, cfg.mapping_params); 

for i = 1:length(pilotPos)
    x(pilotPos(i):pilotPos(i)+length(mappedPilot)-1) = mappedPilot; 
end

xbits = demapping(x, cfg.mapping_params);

cfg.CFO_ratio = 3e-6;
cfg.STO = 3; 
cfg.OSF = 20; 



%% processing through the channel
signalIn = mapping(xbits, cfg.mapping_params);

% First pass
upsampled = upsample(signalIn, cfg.OSF);
RRC_filtered1 = RRC_filtering(upsampled, cfg.RRC_params, 0);

    % get Eb
    signal_power_baseband = sum(abs(RRC_filtered1).^2)/length(RRC_filtered1);
    signal_power = signal_power_baseband/2;
    Energy_symbol = signal_power/cfg.RRC_params.symbolRate;
    Energy_bit = Energy_symbol/cfg.mapping_params.Nbps;
    N_0 = Energy_bit/(10^(EbN0/10));


awgn_signal = awgn(RRC_filtered1, cfg, N_0);
sync_signal = synchronisationError(awgn_signal, cfg, 5);
sync_before = sync_signal;
RRC_filtered2 = RRC_filtering(sync_signal, cfg.RRC_params, 1);

[gardner_out, shift] = gardner(RRC_filtered2, cfg, 1);

downsampled_first_pass = downsample(gardner_out, cfg);

[CFOest, ToAest] = frame_aquisition(downsampled_first_pass, cfg, 0);

% disp('CFO estimation:');
% disp(CFOest/cfg.fc);

% correct synchronisation errors
sync_signal = [sync_signal(shift:end), zeros(1, shift-1)];
cfg.CFO_ratio = CFOest/cfg.fc;
sync_signal = synchronisationError(sync_signal, cfg, -1);

% Second pass
RRC_filtered2 = RRC_filtering(sync_signal, cfg.RRC_params, 1);
downsampled = downsample(RRC_filtered2, cfg);
demapped = demapping(downsampled, cfg.mapping_params);


%% error plots
figure;
subplot(2,1,1);
error = abs(demapped-xbits);
plot(error, 'r');
xlabel('Bit index');
hold on;
y = ylim;
for i = ToAest
    area([i*cfg.mapping_params.Nbps i*cfg.mapping_params.Nbps+Nbits], [1 1]*y(2), y(1), 'FaceColor', [0 0.4 0.8], 'FaceAlpha', 0.5, 'EdgeColor', 'none');
end
legend('Error', 'Detected pilot');
subplot(2,1,2);
cumulativeErrors = cumsum(abs(demapped-xbits));
plot(cumulativeErrors, 'r');
hold on;
xlabel('Bit index');
y = ylim;
for i = ToAest
    area([i*cfg.mapping_params.Nbps i*cfg.mapping_params.Nbps+Nbits], [1 1]*y(2), y(1), 'FaceColor', [0 0.4 0.8], 'FaceAlpha', 0.5, 'EdgeColor', 'none');
end
legend('Cumulative error', 'Detected pilot');

disp('BER:');
disp(sum(abs(demapped-xbits))/length(xbits));

%% Constellation plot

sampleLimit = 2500;

figure;
subplot(2,2,1);
plot(real(signalIn(1:sampleLimit)), imag(signalIn(1:sampleLimit)), 'o');
title('Emitted Constellation');
xlabel('In-Phase');
ylabel('Quadrature');
axis equal; grid on;

% Downsampled at first pass (before any sync correction)
subplot(2,2,2);
plot(real(downsampled_first_pass(1:sampleLimit)), imag(downsampled_first_pass(1:sampleLimit)), 'o');
title('Constellation after Gardner correction');
xlabel('In-Phase');
ylabel('Quadrature');
axis equal; grid on;

% Downsampling(RRC_filtering(sync_signal)) before sync_signal gets modified
RRC_sync_before = RRC_filtering(sync_before, cfg.RRC_params, 1);
downsampled_sync_before = downsample(RRC_sync_before, cfg);
subplot(2,2,3);
plot(real(downsampled_sync_before(1:sampleLimit)), imag(downsampled_sync_before(1:sampleLimit)), 'o');
title('Received constellation');
xlabel('In-Phase');
ylabel('Quadrature');
axis equal; grid on;

% Downsampled at second pass (after sync correction)
subplot(2,2,4);
plot(real(downsampled(1:sampleLimit)), imag(downsampled(1:sampleLimit)), 'o');
title('Corrected constellation');
xlabel('In-Phase');
ylabel('Quadrature');
axis equal; grid on;

