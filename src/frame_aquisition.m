function [CFOest, AboveThr] = frame_aquisition(y, cfg, mode)

    pilot = mapping(cfg.pilot, cfg.mapping_params);

    N = length(pilot);
    K = cfg.pilotK;

    y_conj = conj(y);
    DiffCorr = zeros(K, length(y)-N+1);

    [rowIdx, colIdx] = ndgrid(0:length(y)-N, 1:N); % to construct y
    Y = y_conj(rowIdx + colIdx);
    A = repmat(pilot, length(y)-N+1, 1);

    corr = Y .* A;

    for k = 1:K
        part1 = corr(:, k+1:N);      % [L x (N-k)]
        part2 = conj(corr(:, 1:N-k)); % [L x (N-k)]
    
        % multiply and sum across the columns
        DiffCorr(k, :) = sum(part1 .* part2, 2).' / (N - k);
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    sumDiffCorr = sum(abs(DiffCorr), 1); % Sum over the K correlations

    [maxCorr, ToAest] = max(sumDiffCorr);

    threshold = 0.8 * maxCorr;
    AboveThr = find(sumDiffCorr > threshold);
    

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
        disp(ToAest);
        CFOest = 0;
    else
        % normal mode

        denum = 2*pi/cfg.RRC_params.symbolRate * (1:K);
        CFO = zeros(1, length(AboveThr));

        for i = 1:length(AboveThr)
            CFO(i) = -1/K * sum(angle(DiffCorr(:, AboveThr(i)).')./denum); % CFO estimation
        end

        CFOest = mean(CFO); % average over every pilot
    end

end
