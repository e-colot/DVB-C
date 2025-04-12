project_root = fileparts(mfilename('fullpath')); % Get project root
src_path = fullfile(project_root, '..');
if ~contains(path, src_path)
    addpath(genpath(src_path));
end

cfg = config();

% To add a new block to the transmission chain, add the corresponding function in the handle function list "blocks"
blocks = { ...
    @(x) mapping(x, cfg.mapping_params), ...
    @(x) upsample(x, cfg.OSF), ...
    @(x) RRC_filtering(x, cfg.RRC_params, 0), ...
    @(x) synchronisationError(x, cfg, 1), ...
    @(x) RRC_filtering(x, cfg.RRC_params, 1), ...
    @(x) downsample(x, cfg), ...
};

signal = cell(1, length(blocks) + 1);

% Generate random bits
bitstream = randi([0 1], 1, cfg.NumBits);
bitstream(1:cfg.pilot_bit_length) = cfg.pilot; % Insert pilot bits
signal{1} = bitstream;

% Run the blocks (until the RRC_filtering block)
for i = 1:3
    signal{i+1} = blocks{i}(signal{i});
end

for k = 1:length(cfg.CFO_ratio_vec)
    cfg.CFO_ratio = cfg.CFO_ratio_vec(k);
    % to reevaluate cfg
    blocks{4} = @(x) synchronisationError(x, cfg, 1);
    for i = 4:length(blocks)
        signal{i+1} = blocks{i}(signal{i});
    end

    disp('CFO ratio: ');
    disp(cfg.CFO_ratio);
    disp('Estimated CFO: ');
    [CFOest, ToAest] = frame_aquisition(signal{7}, cfg, 0);
    disp(CFOest/cfg.fc);
    
end


