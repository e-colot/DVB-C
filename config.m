% constants and configuration of the project

function cfg = config()
    clc; close all;

    % setup the path
    project_root = fileparts(mfilename('fullpath')); % Get project root
    src_path = fullfile(project_root, 'src');
    if ~contains(path, src_path)
        addpath(genpath(src_path));
    end

    cfg = struct();

    cfg.mapping_params = struct();
    cfg.mapping_params.Nbps = 4;
    cfg.mapping_params.modulation = 'qam';

    cfg.OSF = 20;    % oversample factor

    cfg.RRC_params = struct();
    cfg.RRC_params.rolloff = 0.2;
    cfg.RRC_params.bandwidth = 6e6;
    cfg.RRC_params.taps = 4*cfg.OSF+1;
    cfg.RRC_params.symbolRate = 5e6;
    cfg.RRC_params.fs = cfg.OSF*cfg.RRC_params.symbolRate;

    cfg.desiredBits = 5e5; % Number of bits generated by the source

    cfg.NumBits = ceil(cfg.desiredBits/cfg.mapping_params.Nbps)*cfg.mapping_params.Nbps; % Number of bits generated by the source

    cfg.N_0 = 1e-10; % Noise power spectral density
    cfg.BER_resolution = 100; % Number of points to calculate BER
    cfg.EbN0_interval = [-5 20];

    cfg.fc = 600e6;
    cfg.CFO_ratio = 0;
    cfg.CFO_ratio_vec = linspace(1e-6, 20e-6, 5);
    cfg.SFO_ratio = 0;
    cfg.SFO_ratio_vec = linspace(1e-5, 20e-5, 3);
    cfg.phase = linspace(0, 2*pi, 10);

end
