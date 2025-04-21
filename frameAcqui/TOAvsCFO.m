project_root = fileparts(mfilename('fullpath')); % Get project root
src_path = fullfile(project_root, '..');
if ~contains(path, src_path)
    addpath(genpath(src_path));
end


cfg = config();

K = 8;
N = 20; 

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

ToASTD = zeros(1, length(CFO_values));

for i = 1:length(CFO_values)
    cfg.CFO_ratio = CFO_values(i);
    ToA = zeros(1, cfg.ToaA_params.measurements);

    for j = 1:cfg.ToaA_params.measurements
        y = awgn(x, cfg, N_0);
        y = synchronisationError(y, cfg, 1);
        y = RRC_filtering(y, cfg.RRC_params, 1);
        y = downsample(y, cfg);
    
        [~, TOA] = frame_aquisition(y, cfg, 0);
        ToA(j) = TOA;
    end
    
    ToASTD(i) = std(ToA);
    if mod(i, 10) == 0
        disp(i);
    end
    
end

figure;
plot(CFO_values*1e6, ToASTD, 'o-');
xlabel('CFO (ppm)');
ylabel('ToA STD (samples)');
title('ToA STD vs CFO');
grid on;
legend('ToA STD');
hold off;

