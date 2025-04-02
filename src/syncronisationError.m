function y = syncronisationError(x, cfg, mode)

    % mode = 0: everything, 1: CFO only, 2: phase only, 3: SFO only

    y = x;

    %% CFO
    if (mode == 0 | mode == 1)
        t = (0:length(x)-1)/cfg.RRC_params.fs; % time vector
        y = y .* exp(1j*2*pi*cfg.fc*cfg.CFO_ratio*t); % CFO
    end

    %% carrier phase offset
    if (mode == 0 | mode == 2)
        phase = unifrnd(0, 2*pi); % random phase
        y = y .* exp(1j*phase); % random phase
    end

    %% sampling time offset
    if (mode == 0 | mode == 3)
        y(1:length(y)*cfg.STO) = zeros(1,length(y)*cfg.STO); % remove first samples
    end

end