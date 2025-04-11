function CFOest = frame_aquisition(y, cfg, mode)

    if mode == 1
        pilot = cfg.pilot;
    else
        pilot = mapping(cfg.pilot, cfg.mapping_params);
    end

    N = length(pilot);
    K = cfg.pilotK;

    sumDiffCorr = zeros(1, length(y)-N+1);
    for i = 1:length(y)-N+1
        for k = 1:K
            sumDiffCorr(i) = sumDiffCorr(i) + abs(1/(N-k) * conj(y(i+k:i+N-1)).*pilot(k+1:N) * conj(conj(y(i:i+N-1-k)) .* pilot(1:N-k)).');
        end
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    [maxCorr, maxIndex] = max(sumDiffCorr);

    if mode == 1
        % debug mode
        plot(sumDiffCorr, 'r');
        title('Correlation between the received signal and the pilot sequence');
        xlabel('Sample index');
        ylabel('Correlation value');
        ylim([0, maxCorr+0.1]);
        xlim([0 length(sumDiffCorr)]);
        grid on;
        disp('Estimated pilot position: ');
        disp(maxIndex);
        CFOest = 0;
    else
        % normal mode
        denum = 2*pi/cfg.RRC_params.fs * (1:K);
        
        CFOest = -1/K * sum(angle(sumDiffCorr)./denum); % CFO estimation
    end


end
