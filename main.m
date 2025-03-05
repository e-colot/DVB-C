cfg = config();

% To add a new block to the transmission chain, add the corresponding function in the handle function list "blocks"
blocks = { ...
    @(x) mapping(x, cfg.mapping_params), ...
    @(x) upsample(x, cfg.OSF), ...
    @(x) RRC_filtering(x, cfg.RRC_params), ...
    @(x) RRC_filtering(x, cfg.RRC_params), ...
    @(x) downsample(x, cfg.OSF), ...
    @(x) demapping(x, cfg.mapping_params) ...
};

signal = cell(1, length(blocks) + 1);

% Generate random bits
signal{1} = randi([0 1], 1, cfg.NumBits);

% Run the blocks
for i = 1:length(blocks)
    signal{i+1} = blocks{i}(signal{i});
end

N = 100; % Number of symbols to plot

figure;
plot(real(signal{3}(1:N)));
hold on;
plot(real(signal{4}(1:N)));
plot(real(signal{5}(1:N)));
title('Impact of RRC filtering on the signal');
xlabel('Sample index');
ylabel('Amplitude');
legend('before RRC', 'after one RRC', 'after both RRC');
hold off;
