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
    cfg.mapping_params.Nbps = 6;
    cfg.mapping_params.modulation = 'qam';

    cfg.OSF = 10;    % oversample factor

    cfg.RRC_params = struct();
    cfg.RRC_params.rolloff = 0.2;
    cfg.RRC_params.bandwidth = 6e6;
    cfg.RRC_params.taps = 101;
    cfg.RRC_params.symbolRate = 5e6;
    cfg.RRC_params.fs = cfg.OSF*cfg.RRC_params.symbolRate;

    cfg.desiredBits = 50e3; % Number of bits generated by the source

    cfg.NumBits = ceil(cfg.desiredBits/cfg.mapping_params.Nbps)*cfg.mapping_params.Nbps; % Number of bits generated by the source

    cfg.N_0 = 1e-8; % Noise power spectral density

end
