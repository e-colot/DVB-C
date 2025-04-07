cfg = config();

% To add a new block to the transmission chain, add the corresponding function in the handle function list "blocks"
blocks = { ...
    @(x) mapping(x, cfg.mapping_params), ...
    @(x) upsample(x, cfg.OSF), ...
    @(x) RRC_filtering(x, cfg.RRC_params, 0), ...
    @(x) syncronisationError(x, cfg, 1), ...
    @(x) RRC_filtering(x, cfg.RRC_params, 1), ...
    @(x) removeISI(x, cfg), ...
    @(x) downsample(x, cfg.OSF), ...
    @(x) demapping(x, cfg.mapping_params) ...
};

signal = cell(1, length(blocks) + 1);

% Generate random bits
signal{1} = randi([0 1], 1, cfg.NumBits);

% Run the blocks (until the awgn block)
for i = 1:length(blocks)-1
    signal{i+1} = blocks{i}(signal{i});
end

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

