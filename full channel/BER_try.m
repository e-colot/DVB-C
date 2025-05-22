clear; close all; clc;

%seed = abs(round(1000000*randn(1, 1)));
%seed = 487012;
%rng(seed); % Set seed for reproducibility

cfg = config();

K = 50;
N = 100; 
pilotCnt = 10;

Nbits = N * cfg.mapping_params.Nbps; 

cfg.NumBits = Nbits*50;

%EbN0Vector = linspace(cfg.EbN0_interval(1), cfg.EbN0_interval(2), cfg.BER_resolution);
EbN0Vector = linspace(5, 15, 15);
itr = 50; % number of iterations for the same EbN0

BER = zeros(length(EbN0Vector), itr);

t = waitbar(0, 'Processing...');

misShiftCnt = 0;

for EbN0Index = 1:length(EbN0Vector)

    EbN0 = EbN0Vector(EbN0Index);

    parfor itrIndex = 1:itr
        %% signal generation
        local_cfg = cfg; % Use a local copy for parfor safety
        local_cfg.pilot_length = N;
        local_cfg.pilotK = K;
        local_cfg.pilot = randi([0 1], 1, Nbits);

        local_cfg.NumBits = local_cfg.pilot_length*local_cfg.mapping_params.Nbps*25;

        pilotPos = linspace(1, local_cfg.NumBits, pilotCnt+2)./local_cfg.mapping_params.Nbps;
        pilotPos = round(pilotPos(2:end-1)+1); 

        mappedPilot = mapping(local_cfg.pilot, local_cfg.mapping_params);

        xbits = randi([0 1], 1, local_cfg.NumBits);
        x = mapping(xbits, local_cfg.mapping_params); 

        for i = 1:length(pilotPos)
            x(pilotPos(i):pilotPos(i)+length(mappedPilot)-1) = mappedPilot; 
        end

        xbits = demapping(x, local_cfg.mapping_params);

        local_cfg.CFO_ratio = 3e-6;
        local_cfg.STO = 3; 
        local_cfg.OSF = 20; 

        %% processing through the channel
        signalIn = mapping(xbits, local_cfg.mapping_params);

        % First pass
        upsampled = upsample(signalIn, local_cfg.OSF);
        RRC_filtered1 = RRC_filtering(upsampled, local_cfg.RRC_params, 0);

        % get Eb
        signal_power_baseband = sum(abs(RRC_filtered1).^2)/length(RRC_filtered1);
        signal_power = signal_power_baseband/2;
        Energy_symbol = signal_power/local_cfg.RRC_params.symbolRate;
        Energy_bit = Energy_symbol/local_cfg.mapping_params.Nbps;
        N_0 = Energy_bit/(10^(EbN0/10));

        awgn_signal = awgn(RRC_filtered1, local_cfg, N_0);
        sync_signal = synchronisationError(awgn_signal, local_cfg, 5);
        sync_before = sync_signal;
        RRC_filtered2 = RRC_filtering(sync_signal, local_cfg.RRC_params, 1);

        [gardner_out, shift] = gardner2(RRC_filtered2, local_cfg, 1);

        downsampled_first_pass = downsample(gardner_out, local_cfg);

        [CFOest, ToAest] = frame_aquisition(downsampled_first_pass, local_cfg, 0);

        % correct synchronisation errors
        sync_signal = [sync_signal(shift:end), zeros(1, shift-1)];
        local_cfg.CFO_ratio = CFOest/local_cfg.fc;
        sync_signal = synchronisationError(sync_signal, local_cfg, -1);

        if (shift ~= local_cfg.STO)
            misShiftCnt = misShiftCnt + 1;
        end

        % Second pass
        RRC_filtered2 = RRC_filtering(sync_signal, local_cfg.RRC_params, 1);
        downsampled = downsample(RRC_filtered2, local_cfg);
        demapped = demapping(downsampled, local_cfg.mapping_params);

        BER(EbN0Index, itrIndex) = sum(abs(demapped-xbits))/length(xbits);
    end
    waitbar(EbN0Index/length(EbN0Vector), t, sprintf('Processing... %d/%d', EbN0Index, length(EbN0Vector)));
end

close(t);

%% BER plot
figure;
semilogy(EbN0Vector, mean(BER, 2), 'LineWidth', 2);
hold on;
semilogy(EbN0Vector, berawgn(EbN0Vector, 'qam', 2^cfg.mapping_params.Nbps), 'LineWidth', 2, 'LineStyle', '--');
xlabel('Eb/N0 (dB)');
ylabel('Bit Error Rate (BER)');
legend('Simulated', 'Theoretical');

disp('Mis detected shifts ratio:');
disp(misShiftCnt/(length(EbN0Vector)*itr));

% %% error plots
% figure;
% subplot(2,1,1);
% error = abs(demapped-xbits);
% plot(error, 'r');
% xlabel('Bit index');
% hold on;
% y = ylim;
% for i = ToAest
%     area([i*cfg.mapping_params.Nbps i*cfg.mapping_params.Nbps+Nbits], [1 1]*y(2), y(1), 'FaceColor', [0 0.4 0.8], 'FaceAlpha', 0.5, 'EdgeColor', 'none');
% end
% legend('Error', 'Detected pilot');
% subplot(2,1,2);
% cumulativeErrors = cumsum(abs(demapped-xbits));
% plot(cumulativeErrors, 'r');
% hold on;
% xlabel('Bit index');
% y = ylim;
% for i = ToAest
%     area([i*cfg.mapping_params.Nbps i*cfg.mapping_params.Nbps+Nbits], [1 1]*y(2), y(1), 'FaceColor', [0 0.4 0.8], 'FaceAlpha', 0.5, 'EdgeColor', 'none');
% end
% legend('Cumulative error', 'Detected pilot');

% disp('BER:');
% disp(sum(abs(demapped-xbits))/length(xbits));

% %% Constellation plot

% sampleLimit = 2500;

% figure;
% subplot(2,2,1);
% plot(real(signalIn(1:sampleLimit)), imag(signalIn(1:sampleLimit)), 'o');
% title('Emitted Constellation');
% xlabel('In-Phase');
% ylabel('Quadrature');
% axis equal; grid on;

% % Downsampled at first pass (before any sync correction)
% subplot(2,2,2);
% plot(real(downsampled_first_pass(1:sampleLimit)), imag(downsampled_first_pass(1:sampleLimit)), 'o');
% title('Constellation after Gardner correction');
% xlabel('In-Phase');
% ylabel('Quadrature');
% axis equal; grid on;

% % Downsampling(RRC_filtering(sync_signal)) before sync_signal gets modified
% RRC_sync_before = RRC_filtering(sync_before, cfg.RRC_params, 1);
% downsampled_sync_before = downsample(RRC_sync_before, cfg);
% subplot(2,2,3);
% plot(real(downsampled_sync_before(1:sampleLimit)), imag(downsampled_sync_before(1:sampleLimit)), 'o');
% title('Received constellation');
% xlabel('In-Phase');
% ylabel('Quadrature');
% axis equal; grid on;

% % Downsampled at second pass (after sync correction)
% subplot(2,2,4);
% plot(real(downsampled(1:sampleLimit)), imag(downsampled(1:sampleLimit)), 'o');
% title('Corrected constellation');
% xlabel('In-Phase');
% ylabel('Quadrature');
% axis equal; grid on;

