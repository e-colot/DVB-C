function [CFOest, ToAest] = frame_aquisition(y, cfg, mode)

    pilot = mapping(cfg.pilot, cfg.mapping_params);

    N = length(pilot);
    K = cfg.pilotK;

    tic; % Start timing
    DiffCorr = zeros(K, length(y)-N+1);
    for i = 1:length(y)-N+1
        for k = 1:K
            DiffCorr(k, i) = 1/(N-k) * conj(y(i+k:i+N-1)).*pilot(k+1:N) * conj(conj(y(i:i+N-1-k)) .* pilot(1:N-k)).';
        end
    end
    elapsedTime = toc; % Stop timing
    disp(['Time taken for DiffCorr computation: ', num2str(elapsedTime), ' seconds']);

    % optimized
    tic; % Start timing
    y_conj = conj(y);
    DiffCorr2 = zeros(K, length(y)-N+1);

    [rowIdx, colIdx] = ndgrid(1:length(y)-N, 1:N); % to construct y
    Y = y(rowIdx + colIdx);
    A = repmat(pilot, N, 1);

    corr = conj(Y) * A;

    for n = 1:length(y)-N
        for k = 1:K
            DiffCorr2(k, n) = 1/(N-k) * corr(n, k+1:N) * conj(corr(n, 1:N-k)).';
        end
    end

    elapsedTime = toc; % Stop timing
    disp(['Time taken for DiffCorr2 computation: ', num2str(elapsedTime), ' seconds']);

    disp('difference correlation: ');
    disp(norm(DiffCorr - DiffCorr2, 'fro'));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    sumDiffCorr = sum(abs(DiffCorr), 1); % Sum over the K correlations

    [maxCorr, ToAest] = max(sumDiffCorr);

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
        
        CFOest = -1/K * sum(angle(DiffCorr(:, ToAest).')./denum); % CFO estimation
    end

end
