function frequency = frame_aquisition(y, cfg, mode)

    pilot = cfg.pilot;
    %pilot = mapping(cfg.pilot, cfg.mapping_params);
    N = cfg.pilot_params.N;
    k = cfg.pilot_params.k;

    diffCorr = zeros(1, length(y)-N+1);
    for i = 1:length(y)-N+1

        diffCorr(i) = 1/(N-k) * conj(y(i+k:i+N-1)).*pilot(k+1:N) * conj(conj(y(i:i+N-1-k)) .* pilot(1:N-k)).';

    end

    [maxCorr, maxIndex] = max(diffCorr);

    if mode == 1
        % debug mode
        plot(diffCorr, 'r');
        title('Correlation between the received signal and the pilot sequence');
        xlabel('Sample index');
        ylabel('Correlation value');
        ylim([0, maxCorr+0.1]);
        xlim([0 length(diffCorr)]);
        grid on;
        disp('Estimated pilot position: ');
        disp(maxIndex);
        frequency = 0;
    end


end
