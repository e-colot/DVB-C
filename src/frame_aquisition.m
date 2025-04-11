function CFOest = frame_aquisition(y, cfg, mode)

    pilot = mapping(cfg.pilot, cfg.mapping_params);

    N = length(pilot);
    K = cfg.pilotK;

    DiffCorr = zeros(K, length(y)-N+1);
    for i = 1:length(y)-N+1
        for k = 1:K
            DiffCorr(k, i) = 1/(N-k) * conj(y(i+k:i+N-1)).*pilot(k+1:N) * conj(conj(y(i:i+N-1-k)) .* pilot(1:N-k)).';
        end
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    sumDiffCorr = sum(abs(DiffCorr), 1); % Sum over the K correlations

    [maxCorr, maxIndex] = max(sumDiffCorr);

    if mode == 1
        % debug mode
        plot(sumDiffCorr, 'r');
        title('Correlation between the received signal and the pilot sequence');
        xlabel('Sample index');
        ylabel('Correlation value');
        ylim([0, maxCorr+1]);
        xlim([0 length(sumDiffCorr)]);
        grid on;
        disp('Estimated pilot position: ');
        disp(maxIndex);
        CFOest = 0;
    else
        % normal mode
        denum = 2*pi/cfg.RRC_params.fs * (1:K);
        
        CFOest = -1/K * sum(angle(DiffCorr(:, maxIndex).')./denum); % CFO estimation
    end


end
