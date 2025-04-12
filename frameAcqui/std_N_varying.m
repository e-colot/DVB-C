project_root = fileparts(mfilename('fullpath')); % Get project root
src_path = fullfile(project_root, '..');
if ~contains(path, src_path)
    addpath(genpath(src_path));
end

cfg = config();

N = 5;
K = 10;

pilotPos = 100;

signal = randi([0 1], 1, cfg.NumBits);
signal(pilotPos:pilotPos+cfg.pilot_bit_length-1) = cfg.pilot; % Insert pilot bits

cfg.CFO_ratio = 5e-6; % 5ppm

blocks = { ...
    @(x) mapping(x, cfg.mapping_params), ...
    @(x) upsample(x, cfg.OSF), ...
    @(x) RRC_filtering(x, cfg.RRC_params, 0), ...
};

for i = 1:length(blocks)
    signal = blocks{i}(signal);
end

ToA = zeros(1, cfg.BER_resolution);
CFO = zeros(1, cfg.BER_resolution);

[ToAstd, CFOstd] = ToA_CFO_error(signal, N, K, cfg);
ToA(i, :) = ToAstd;
CFO(i, :) = CFOstd;


x_axis = linspace(cfg.EbN0_interval(1), cfg.EbN0_interval(2), cfg.BER_resolution);

figure;
subplot(2, 1, 1);
plot(x_axis, ToA, 'LineWidth', 1.5);
xlabel('E_b/N_0 (dB)');
ylabel('ToA Standard Deviation (K = 5)');
title('Time of Arrival (ToA) Error');
grid on;

subplot(2, 1, 2);
plot(x_axis, CFO, 'LineWidth', 1.5);
xlabel('E_b/N_0 (dB)');
ylabel('CFO Standard Deviation (K = 5)');
title('Carrier Frequency Offset (CFO) Error');
grid on;
