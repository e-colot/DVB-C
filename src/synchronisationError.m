function y = synchronisationError(x, cfg, mode)

    % mode = 0: everything, 1: CFO only, 2: phase only, 3: SFO only

    y = x;

    %% CFO
    if (mode == 0 | mode == 1)
        t = (0:length(x)-1)/(cfg.RRC_params.fs); % time vector
        y = y .* exp(1j*2*pi*cfg.fc*cfg.CFO_ratio*t); % CFO
    end
    
    if (mode == 0 | mode == -1)
        t = (0:length(x)-1)/(cfg.RRC_params.fs); % time vector
        t = t + (cfg.RRC_params.taps-1)/(2 * cfg.RRC_params.fs); % correction for the number of samples
        y = y .* exp(-1j*2*pi*cfg.fc*cfg.CFO_ratio*t); % CFO
    end


    %% carrier phase offset
    if (mode == 0 | mode == 2)
        y = y .* exp(1j*cfg.phase); % random phase
    end

    %% sampling time offset
    if (mode == 0 | mode == 3)
        y = [zeros(1, cfg.STO), y(1:end-cfg.STO)];
    end

end
