function [output, delay] = gardner(input, cfg, mode)

    delay = -1;
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
        
        correction = 2*cfg.k_coef*real_part(ind-1)/(cfg.RRC_params.fs);
        error(ind+1) = error(ind) - correction;

    end

    if mode == 1
        delay = round(abs(error(end))*cfg.RRC_params.fs);
        if round(abs(error(end))*cfg.RRC_params.fs) >= 1  
            output = y_corr(round(abs(error(end))*cfg.RRC_params.fs):end);
        else
            output = y_corr(1:end);
        end
        output = [output , zeros(1, cfg.NumBits*cfg.OSF/cfg.mapping_params.Nbps - length(output))];
    elseif mode == 2
        error_time = error;
        if round(abs(error(end))*cfg.RRC_params.fs) >= 1  
            output = y_corr(round(abs(error(end))*cfg.RRC_params.fs):end);
        else
            output = y_corr(1:end);
        end
        output = [output , zeros(1, cfg.NumBits*cfg.OSF/cfg.mapping_params.Nbps - length(output))];
    elseif mode == 3
        error_time = error;
        mid_points = med;
        collect_slope = collect_y;
        % disp(['Start delay ',num2str(error(1)*cfg.RRC_params.fs), ' micro seconds']);
        % disp(['Result ',num2str(error(end)*cfg.RRC_params.fs), ' micro seconds']);
        % disp(['Target ',num2str(cfg.STO), ' micro seconds']);
        if round(abs(error(end))*cfg.RRC_params.fs) >= 1  
            output = y_corr(round(abs(error(end))*cfg.RRC_params.fs):end);
        else
            output = y_corr(1:end);
        end
        output = [output , zeros(1, cfg.NumBits*cfg.OSF/cfg.mapping_params.Nbps - length(output))];

       %% Time offset per symbol
        symbol_nbre = [0:1:(cfg.NumBits/cfg.mapping_params.Nbps)-1];
       figure();
       title('Symbol sampling visualization');
       xlabel('Symbol');
       ylabel('magnitude');
       hold on
       
       sumbol_range_delay = symbol_nbre + (error_time*cfg.RRC_params.fs/cfg.OSF)';
       plot(sumbol_range_delay(1 : 20)+1.5, sqrt(abs(mid_points(1 : 20)).^2),"*",'Color','r');
       hold on
    
       plot(sumbol_range_delay(1 : 20)+1, sqrt(abs(collect_slope(1:20)).^2), '--', 'LineWidth', 0.5, 'Color', 'g');
       hold on
    
       plot(sumbol_range_delay(1 : 20)+1, sqrt(abs(collect_slope(1:20)).^2), 'x', 'Color', 'g');
       hold on

       symbol_range_test_2 = linspace(0,20,400);

       plot(symbol_range_test_2, sqrt(abs(input(1:20*cfg.OSF)).^2), 'LineWidth', 0.5, 'Color', 'b');
       hold on
    end
    
