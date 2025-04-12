function [ToAstd, CFOstd] = ToA_CFO_error(x, N, K, cfg)
    % x: emitted signal (just before awgn block)
    % N: length of the pilot sequence
    % K: max shift of pilot masking
    % N0: noise power
    % cfg: configuration structure

    blocks = { ...
        @(x, N_0) awgn(x, cfg, N_0), ... % AWGN channel
        @(x) synchronisationError(x, cfg, 0), ... % CFO and ToA estimation
        @(x) RRC_filtering(x, cfg.RRC_params, 1), ... % RRC filtering (Rx)
        @(x) downsample(x, cfg), ... % Downsampling
    };

    Eb = sum(abs(x).^2)/(2*length(x)*cfg.RRC_params.symbolRate*cfg.mapping_params.Nbps);
    EbN0 = linspace(cfg.EbN0_interval(1), cfg.EbN0_interval(2), cfg.BER_resolution);
    N0 = Eb./(10.^(EbN0/10));

    ToA = zeros(cfg.ToaA_params.measurements, length(N0));
    CFO = zeros(cfg.ToaA_params.measurements, length(N0));

    for measurement = 1:cfg.ToaA_params.measurements

        for k = 1:length(N0)
            % Run the blocks
            signal = blocks{1}(x, N0(k));
            signal = blocks{2}(signal);
            signal = blocks{3}(signal); 
            signal = blocks{4}(signal);

            [CFOest, ToAest] = frame_aquisition(signal, cfg, 0);

            CFO(measurement, k) = CFOest/cfg.fc; % Normalized CFO
            ToA(measurement, k) = ToAest; % ToA estimation
        end

    end

    % Calculate the mean and standard deviation of CFO and ToA
    ToAstd = std(ToA, 0, 1);
    CFOstd = std(CFO, 0, 1);

end

