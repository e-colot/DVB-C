cfg = config();

% To add a new block to the transmission chain, add the corresponding function in the handle function list "blocks"
blocks = { ...
    @(x) mapping(x, cfg.mapping_params), ...
    @(x) upsample(x, cfg.OSF), ...
    @(x) RRC_filtering(x, cfg.RRC_params, 0), ...
    @(x, N_0) awgn(x, cfg, N_0), ...
    @(x) syncronisationError(x, cfg, 1), ...
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

% Energy per bit (Eb)
Signal_power_baseband = sum(abs(signal{4}).^2)/length(signal{4});
Signal_power = Signal_power_baseband/2;

Energy_symbol = Signal_power/cfg.RRC_params.symbolRate;
Energy_bit = Energy_symbol/cfg.mapping_params.Nbps;
disp(['Energy per bit (Eb): ', num2str(Energy_bit)]);

% Generate Noise power 
EbN0 = linspace(cfg.EbN0_interval(1), cfg.EbN0_interval(2), cfg.BER_resolution);
N_0 = Energy_bit./(10.^(EbN0/10));

BER = zeros(length(N_0),1);
theoreticalBER = zeros(length(N_0),1);

for j = 1:length(N_0)
    signal{5} = blocks{4}(signal{4}, N_0(j));
    for i = 5:length(blocks)
        signal{i+1} = blocks{i}(signal{i});
    end
    errors = sum(abs(signal{end} - signal{1}) > 0);
    BER(j) = errors/cfg.NumBits;
    theoreticalBER(j) = berawgn(10*log10(Energy_bit/N_0(j)), cfg.mapping_params.modulation, 2^cfg.mapping_params.Nbps);
end

%%  Plots

% Eb/No
Energy_per_noise =10*log10(Energy_bit./N_0);

semilogy(Energy_per_noise, BER, "LineWidth", 2);
hold on;
semilogy(Energy_per_noise, theoreticalBER, "LineWidth", 2, "LineStyle", "--");
hold on;
legend('Simulated BER', 'Theoretical BER');
title('Bit Error Rate for QAM modulation');
xlabel('Eb/N_0 (Decibel)');
ylabel('BER');
xlim(cfg.EbN0_interval);
ylim([1e-5 1]);
grid on;

figure;
plot(signal{end-1}, 'o');
title('Constellation Diagram');
xlabel('Real Part');
ylabel('Imaginary Part');
limit = max(real(signal{2})) + 1;
xlim([-limit limit]);
ylim([-limit limit]);
axis equal;
grid on;
