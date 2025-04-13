cfg = config();

K_values = 1:2:15; % Max shift of pilot masking
std_TOA_results = zeros(length(K_values), length(EbN0_dB));
std_CFO_results = zeros(length(K_values), length(EbN0_dB));

for n_idx = 1:length(K_values)
    N = 20; % Current pilot length
    Nbits = N * cfg.mapping_params.Nbps; % Length of the pilot (in bits)
    cfg.pilot_length = N; % Length of the pilot (in symbols)
    K = K_values(n_idx); % Max shift of pilot masking
    cfg.pilotK = K; % Max shift of pilot masking
    cfg.pilot = randi([0 1], 1, Nbits); % Generate random pilot bits

    blocks = { ... % Define the blocks in the transmission chain
        @(x) mapping(x, cfg.mapping_params), ... % Mapping
        @(x) upsample(x, cfg.OSF), ... % Upsampling
        @(x) RRC_filtering(x, cfg.RRC_params, 0), ... % RRC filtering (Tx)
        @(x, N_0) awgn(x, cfg, N_0), ... % AWGN channel
        @(x) synchronisationError(x, cfg, 1), ... % CFO and ToA estimation
        @(x) RRC_filtering(x, cfg.RRC_params, 1), ... % RRC filtering (Rx)
        @(x) downsample(x, cfg), ... % Downsampling
    };

    % Generate random bits
    bitstream = randi([0 1], 1, cfg.NumBits);
    bitstream(1:Nbits) = cfg.pilot; % Insert pilot bits
    signal{1} = bitstream;

    % Run the blocks (until the awgn block)
    for i = 1:3
        signal{i+1} = blocks{i}(signal{i});
    end
    
    tic;

    parfor idx = 1:length(EbN0_dB)
        TOA_values = zeros(1, cfg.ToaA_params.measurements);
        CFO_values = zeros(1, cfg.ToaA_params.measurements);

        Eb = sum(abs(signal{4}).^2)/(2*length(signal{4})*cfg.RRC_params.symbolRate*cfg.mapping_params.Nbps);
        N_0 = Eb/(10^(EbN0_dB(idx)/10));

        for meas = 1:cfg.ToaA_params.measurements
            % Regenerate noise and process the signal
            signal_copy = signal; % Create a local copy of the signal for parallel execution
            signal_copy{5} = blocks{4}(signal_copy{4}, N_0);
            for i = 5:length(blocks)
                signal_copy{i+1} = blocks{i}(signal_copy{i});
            end

            % Perform frame acquisition
            [TOA_values(meas), CFO_values(meas)] = frame_aquisition(signal_copy{end}, cfg, 0);
        end

        % Compute standard deviations
        std_TOA_results(n_idx, idx) = std(TOA_values);
        std_CFO_results(n_idx, idx) = std(CFO_values);
    end
    
    time = toc;

    disp(['K = ' num2str(K) ' completed in ' num2str(time) ' seconds']);
end

% Plot results
figure;
for n_idx = 1:length(K_values)
    subplot(2, 1, 1);
    plot(EbN0_dB, std_TOA_results(n_idx, :), 'DisplayName', ['K = ' num2str(K_values(n_idx))]);
    hold on;
    xlabel('Eb/N0 (dB)');
    ylabel('Std Dev of Time of Arrival');
    title('Time of Arrival Estimation vs Eb/N0 (N = 20)');
    grid on;

    subplot(2, 1, 2);
    plot(EbN0_dB, std_CFO_results(n_idx, :), 'DisplayName', ['K = ' num2str(K_values(n_idx))]);
    hold on;
    xlabel('Eb/N0 (dB)');
    ylabel('Std Dev of CFO Estimation');
    title('CFO Estimation vs Eb/N0 (N = 20)');
    grid on;
end

% Save results to ./results directory
if ~exist('./results', 'dir')
    mkdir('./results');
end

save('./results/step5_4_K.mat', 'std_TOA_results', 'std_CFO_results', 'K_values', 'EbN0_dB');

subplot(2, 1, 1);
legend('show');
subplot(2, 1, 2);
legend('show');


