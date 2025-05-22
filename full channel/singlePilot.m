clear; close all; clc;

rng(251); % Set seed for reproducibility


cfg = config();

K = 12;
N = 50; 

Nbits = N * cfg.mapping_params.Nbps; 

% signal generation
cfg.pilot_length = N;
cfg.pilotK = K;
cfg.pilot = randi([0 1], 1, Nbits);

cfg.NumBits = cfg.pilot_length*cfg.mapping_params.Nbps*50;

pilotPos = 100; 
mappedPilot = mapping(cfg.pilot, cfg.mapping_params);

xbits = randi([0 1], 1, cfg.NumBits);
x = mapping(xbits, cfg.mapping_params); 
x(pilotPos:pilotPos+length(mappedPilot)-1) = mappedPilot; 
xbits = demapping(x, cfg.mapping_params);

cfg.CFO_ratio = 3e-6;
cfg.STO = 3; 
cfg.OSF = 20; 


signal = cell(1, 10);

% Generate random bits
signal{1} = x;


% To add a new block to the transmission chain, add the corresponding function in the handle function list "blocks"
blocks = { ...
    @(x) upsample(x, cfg.OSF), ...
    @(x) RRC_filtering(x, cfg.RRC_params, 0), ...
    @(x) awgn(x, cfg, N_0), ...
    @(x) synchronisationError(x, cfg, 5), ...
    @(x) RRC_filtering(x, cfg.RRC_params, 1), ...
    @(x) gardner(x, cfg, 1), ...
    @(x) downsample(x, cfg), ...
    @(x) frame_aquisition(x, cfg, 0), ...
    @(x) demapping(x, cfg.mapping_params) ...
};

% Run the blocks (until the frame_aquisition block)
for i = 1:5
    signal{i+1} = blocks{i}(signal{i});
end

[signal{7}, shift] = blocks{6}(signal{6});
signal{8} = blocks{7}(signal{7});

[CFOest, ToAest] = blocks{8}(signal{8});

disp('ToA estimation:');
disp(ToAest);

disp('CFO estimation:');
disp(CFOest/cfg.fc);

% correct CFO
%shift = 3;
signal{5} = [signal{5}(shift:end), zeros(1, shift-1)];
cfg.CFO_ratio = CFOest/cfg.fc;
signal{5} = synchronisationError(signal{5}, cfg, -1);

sig6 = blocks{5}(signal{5});
sig8 = blocks{7}(sig6);
sig9 = blocks{9}(sig8);

cumulativeErrors = cumsum(abs(sig9-xbits));
plot(cumulativeErrors, 'r');
hold on;
xlabel('Bit index');
y = ylim;
area([ToAest ToAest+Nbits], [1 1]*y(2), y(1), 'FaceColor', [0 0.4 0.8], 'FaceAlpha', 0.5, 'EdgeColor', 'none');

legend('Cumulative error', 'Detected pilot');

