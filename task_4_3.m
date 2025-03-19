cfg = config();
nbps = (4:2:8);
for i = 1:length(nbps)
    cfg.mapping_params.Nbps = nbps(i);
    % To add a new block to the transmission chain, add the corresponding function in the handle function list "blocks"
    blocks = { ...
        @(x) mapping(x, cfg.mapping_params), ...
        @(x) upsample(x, cfg.OSF), ...
        @(x) RRC_filtering(x, cfg.RRC_params, 0), ...
        @(x, N_0) awgn(x, cfg, N_0), ...
        @(x) RRC_filtering(x, cfg.RRC_params, 1), ...
        @(x) downsample(x, cfg.OSF), ...
        @(x) demapping(x, cfg.mapping_params) ...
    };

    signal = cell(1, length(blocks) + 1);

    % Generate random bits
    signal{1} = randi([0 1], 1, cfg.NumBits);

    % Run the blocks (until the awgn block)
    for i = 1:3
        signal{i+1} = blocks{i}(signal{i});
    end

    %% Loop with different noise power

    % Generate Noise power 
    N_0 = zeros(1,100);
    N_0(1)=1e-8;
    for i =  2:length(N_0)
        N_0(i) = N_0(i-1)/(1.25);
    end

    demapped_signal = zeros(length(N_0),cfg.NumBits);

    for j = 1:length(N_0)
        signal{5} = blocks{4}(signal{4}, N_0(j));
        for i = 5:length(blocks)
            signal{i+1} = blocks{i}(signal{i});
        end
        demapped_signal(j,:) = signal{end};
    end
    %%  Plots

    % Energy per bit (Eb)
    Signal_power_baseband = sum(abs(signal{4}).^2)/length(signal{4});
    % division by signal length ????
    Signal_power = Signal_power_baseband/2;

    Energy_symbol = Signal_power/cfg.RRC_params.symbolRate;
    Energy_bit = Energy_symbol/cfg.mapping_params.Nbps;
    disp(['Energy per bit (Eb): ', num2str(Energy_bit)]);

    % Bit Error Rate (BER)
    Difference_bit = zeros(length(N_0), cfg.NumBits);
    BER = zeros(length(N_0),1);
    for i=1:length(N_0)
        errors = sum(abs(demapped_signal(i,:) - signal{1}) > 0);
        BER(i) = errors/cfg.NumBits;
    end

    % Eb/No
    Energy_per_noise =10*log10(Energy_bit./N_0);

    semilogy(Energy_per_noise, BER, "LineWidth", 2);
    hold on;
end

title('Bit Error Rate for QAM modulation');
xlabel('Eb/N_0 (Decibel)');
ylabel('BER');
legend(arrayfun(@(x) ['QAM-', num2str(2^x)], nbps, 'UniformOutput', false));
xlim([-5 20]);
