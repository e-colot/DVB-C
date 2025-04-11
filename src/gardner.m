function [output, error_time, collect_slope, mid_points , correction_real] = gardner(input, cfg)

    % Initialisation
    t = length(input);
    t_down = t/cfg.OSF;
    error = zeros(t_down-1,1);
    collect_y = zeros(t_down-1,1);
    med = zeros(t_down-2,1);
    real_part = zeros(t_down-2,1);
    error(1)= (cfg.OSF/2)/cfg.RRC_params.fs;
    error(2)= (cfg.OSF/2)/cfg.RRC_params.fs;
    y_corr = input;
    k = 0.01;
    collect_y(1) = y_corr(cfg.OSF+round((error(1)*cfg.RRC_params.fs)));

    % Loop error
    for ind=2:t_down-1
        

        time_med = ((ind*cfg.OSF+round(error(ind)*cfg.RRC_params.fs))+((ind-1)*cfg.OSF+round(error(ind)*cfg.RRC_params.fs)))/2;
        med(ind-1) = y_corr(time_med);
        if error(ind) > cfg.OSF 
            collect_y(ind) = y_corr(ind*cfg.OSF+cfg.OSF);
        else
            collect_y(ind) = y_corr(ind*cfg.OSF+round((error(ind)*cfg.RRC_params.fs)));
        end
        real_part(ind-1) = real(med(ind-1)*(conj(collect_y(ind))-conj(collect_y(ind-1))));
        
        correction = 2*k*real_part(ind-1)/(cfg.RRC_params.fs);
        error(ind+1) = error(ind) - correction;

    end
    error_time = error;
    mid_points = med;
    collect_slope = collect_y;
    correction_real = real_part;
    % disp(['Start delay ',num2str(error(1)*cfg.RRC_params.fs), ' micro seconds']);
    % disp(['Result ',num2str(error(end)*cfg.RRC_params.fs), ' micro seconds']);
    % disp(['Target ',num2str(cfg.STO), ' micro seconds']);
    output = y_corr(round(abs(error(end))*cfg.RRC_params.fs):end);
end

