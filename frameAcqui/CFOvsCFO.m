project_root = fileparts(mfilename('fullpath')); % Get project root
src_path = fullfile(project_root, '..');
if ~contains(path, src_path)
    addpath(genpath(src_path));
end


cfg = config();

K = 12;
N = 50; 

Nbits = N * cfg.mapping_params.Nbps; 

cfg.pilot_length = N;
cfg.pilotK = K;
cfg.pilot = randi([0 1], 1, Nbits);

cfg.NumBits = cfg.pilot_length*cfg.mapping_params.Nbps*10;
cdf.ToaA_params.measurements = 1e5;

pilotPos = 100; 
mappedPilot = mapping(cfg.pilot, cfg.mapping_params);

x = randi([0 1], 1, cfg.NumBits);
x = mapping(x, cfg.mapping_params); 
x(pilotPos:pilotPos+length(mappedPilot)-1) = mappedPilot; 

x = upsample(x, cfg.OSF);
x = RRC_filtering(x, cfg.RRC_params, 0);
EbN0 = -2;
Eb = sum(abs(x).^2)/(2*length(x)*cfg.RRC_params.symbolRate*cfg.mapping_params.Nbps);
N_0 = Eb/(10^(EbN0/10));

CFO_values = (1:500)*1e-6;

CFO_std = zeros(1, length(CFO_values));
CFO_mean = zeros(1, length(CFO_values));

f = waitbar(0, 'Processing...');
for i = 1:length(CFO_values)
    cfg.CFO_ratio = CFO_values(i);
    CFO_est_vect = zeros(1, cfg.ToaA_params.measurements);

    for j = 1:cfg.ToaA_params.measurements
        y = awgn(x, cfg, N_0);
        y = synchronisationError(y, cfg, 1);
        y = RRC_filtering(y, cfg.RRC_params, 1);
        y = downsample(y, cfg);
    
        [CFO_est, ~] = frame_aquisition(y, cfg, 0);
        CFO_est_vect(j) = CFO_est/cfg.fc;
    end

    waitbar(i/length(CFO_values), f, 'Processing...');
    
    CFO_std(i) = std(CFO_est_vect);
    CFO_mean(i) = mean(CFO_est_vect);
    
end

delete(f); % Close the waitbar

figure;
fill([CFO_values * 1e6, fliplr(CFO_values * 1e6)], ...
    [(CFO_mean - CFO_std) * 1e6, fliplr((CFO_mean + CFO_std) * 1e6)], ...
    'b', 'FaceAlpha', 0.3, 'EdgeColor', 'none');
xlabel('True CFO (ppm)');
ylabel('CFO estimation (ppm)');
title('CFO estimated vs true CFO');
grid on;

hold on;
plot(CFO_values * 1e6, CFO_mean * 1e6, 'g-', 'LineWidth', 1.5); % Plot the CFO mean line
plot(CFO_values * 1e6, CFO_values * 1e6, 'r--', 'LineWidth', 1.5); % Plot the true CFO line
legend('CFO estimation', 'CFO estimation mean', 'True CFO', 'Location', 'Best'); % Update legend
hold off;

