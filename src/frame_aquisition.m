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

    %% optimize the code

    tic; % Start timing
    y_conj = conj(y);
    DiffCorr2 = zeros(K, length(y)-N+1);

    [rowIdx, colIdx] = ndgrid(0:length(y)-N, 1:N); % to construct y
    Y = y_conj(rowIdx + colIdx);
    A = repmat(pilot, length(y)-N+1, 1);

    corr = Y .* A;

    for k = 1:K
        part1 = corr(:, k+1:N);      % [L x (N-k)]
        part2 = conj(corr(:, 1:N-k)); % [L x (N-k)]
    
        % multiply and sum across the columns
        DiffCorr2(k, :) = sum(part1 .* part2, 2).' / (N - k);
    end

    elapsedTime = toc; % Stop timing
    disp(['Time taken for optimized DiffCorr2 computation: ', num2str(elapsedTime), ' seconds']);

    disp(['difference between both results: ', num2str(norm(DiffCorr - DiffCorr2))]);

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
