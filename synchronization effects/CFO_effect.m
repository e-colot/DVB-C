project_root = fileparts(mfilename('fullpath')); % Get project root
src_path = fullfile(project_root, '..');
if ~contains(path, src_path)
    addpath(genpath(src_path));
end


cfg = config();

cfg.desiredBits = 5e3;
cfg.NumBits = ceil(cfg.desiredBits/cfg.mapping_params.Nbps)*cfg.mapping_params.Nbps;
cfg.N_0 = 0;
cfg.CFO_ratio = 0.2e-6;

blocks = { ...
    @(x) mapping(x, cfg.mapping_params), ...
    @(x) upsample(x, cfg.OSF), ...
    @(x) RRC_filtering(x, cfg.RRC_params, 0), ...
    @(x) synchronisationError(x, cfg, 1), ...
    @(x) RRC_filtering(x, cfg.RRC_params, 1), ...
    @(x) downsample(x, cfg.OSF), ...
    @(x) demapping(x, cfg.mapping_params) ...
};

signal = cell(1, length(blocks) + 1);

% Generate random bits
signal{1} = randi([0 1], 1, cfg.NumBits);

% Run the blocks 
for i = 1:length(blocks)-1
    signal{i+1} = blocks{i}(signal{i});
end
% Plot constellation diagrams
figure;

% Constellation diagram for the original mapped symbols
subplot(1, 2, 1);
scatter(real(signal{2}), imag(signal{2}), 'filled');
title('Original Mapped Symbols');
xlabel('In-Phase');
ylabel('Quadrature');
ylim([-(max(real(signal{2}))+0.5), (max(real(signal{2}))+0.5)]);
axis equal;
grid on;

% Constellation diagram for the received symbols
subplot(1, 2, 2);
scatter(real(signal{end-1}), imag(signal{end-1}), 'filled');
title('Received Symbols');
xlabel('In-Phase');
ylabel('Quadrature');
ylim([-(max(real(signal{end-1}))+0.5), (max(real(signal{end-1}))+0.5)]);
axis equal;
grid on;

