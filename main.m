cfg = config();

% To add a new block to the transmission chain, add the corresponding function in the handle function list "blocks"
blocks = { ...
    @(x) mapping(x, cfg.mapping_params), ...
    @(x) upsample(x, cfg.OSF), ...
    @(x) RRC_filtering(x, cfg.RRC_params, 0), ...
    @(x) awgn(x, cfg, cfg.N_0), ...
    @(x) RRC_filtering(x, cfg.RRC_params, 1), ...
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

figure;

subplot(1, 2, 1);
plot(real(signal{2}), imag(signal{2}), 'o');
title('Constellation Diagram of the clear signal');
xlabel('In-Phase');
ylabel('Quadrature');
axis equal;
xlim([-1.5 1.5]);
ylim([-1.5 1.5]);
grid on;

subplot(1, 2, 2);
plot(real(signal{7}), imag(signal{7}), 'o');
title('Constellation Diagram of the noised signal');
xlabel('In-Phase');
ylabel('Quadrature');
axis equal;
xlim([-1.5 1.5]);
ylim([-1.5 1.5]);
grid on;
