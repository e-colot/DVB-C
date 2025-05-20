clear;
close all;
cfg = config();

disp(['SNR is fixed at ', num2str(cfg.EbN0_interval(1)), ' dB']);

mode = 5; % Error type
gardner_mode = 2; % mode of output (without visu [1], with visualisation of time offset and MSE [2] or with full visualisation [3]) 

if mode == 1
    vector = cfg.CFO_ratio_vec;
elseif mode == 2
    vector = linspace(0, 2*pi*4/5, 5);
elseif mode == 3
    vector = cfg.STO_vec;
elseif mode == 4 % multiple time offset samples tested 
    vector = cfg.STO_vec;
    disp(['CFO is fixed at ', num2str(cfg.CFO_ratio), ' ppm']);
elseif mode == 5 % multiple CFOs tested for a same time offset
    vector = cfg.CFO_ratio_vec;
    cfg.STO = cfg.STO_vec(1);
    disp(['STO is fixed at ', num2str(cfg.STO), ' samples shift']);
elseif mode == 6 % multiple K coef tested for a same time offset
    vector = cfg.k_coef_vec;
    cfg.STO = cfg.STO_vec(1);
    cfg.CFO_ratio = cfg.CFO_ratio_vec(1);
    disp(['CFO is fixed at ', num2str(cfg.CFO_ratio), ' ppm']);
    disp(['STO is fixed at ', num2str(cfg.STO), ' samples shift']);
end

colors = lines(length(vector)); % Generate distinct colors for each iteration

    % To add a new block to the transmission chain, add the corresponding function in the handle function list "blocks"
    blocks = { ...
        @(x) mapping(x, cfg.mapping_params), ...
        @(x) upsample(x, cfg.OSF), ...
        @(x) RRC_filtering(x, cfg.RRC_params, 0), ...
        @(x, N_0) awgn(x, cfg, N_0), ...
        @(x) synchronisationError(x, cfg, mode), ...
        @(x) RRC_filtering(x, cfg.RRC_params, 1), ...
        @(x) synchronisationError(x, cfg, -mode), ...
        @(x) gardner2(x, cfg, gardner_mode), ...
        @(x) downsample(x, cfg), ...
        @(x) demapping(x, cfg.mapping_params) ...
    };

    signal = cell(1, length(blocks) + 1);
    repetition = 150;
    temp_sum = 0;
    error_matrix = zeros((cfg.NumBits/cfg.mapping_params.Nbps),length(cfg.STO_vec)*repetition);
    for l = 1:repetition

    % Generate random bits
    signal{1} = randi([0 1], 1, cfg.NumBits);
    
    % Run the blocks (until the awgn block)
    for i = 1:3
        signal{i+1} = blocks{i}(signal{i});
    end

    %% Loop with different noise power
    
    % Energy per bit (Eb)
    Signal_power_baseband = sum(abs(signal{4}).^2)/length(signal{4});
    Signal_power = Signal_power_baseband/2;

    Energy_symbol = Signal_power/cfg.RRC_params.symbolRate;
    Energy_bit = Energy_symbol/cfg.mapping_params.Nbps;

    % Generate Noise power 
    % EbN0 = linspace(cfg.EbN0_interval(1), cfg.EbN0_interval(2), cfg.BER_resolution);
    EbN0 = cfg.EbN0_interval(1);
    N_0 = Energy_bit./(10.^(EbN0/10));
    
    signal{5} = blocks{4}(signal{4}, N_0);

    
        for k = 1:length(vector)
            if mode == 1 | mode == 5
                cfg.CFO_ratio = vector(k);
            elseif mode == 2
                cfg.phase = vector(k);
            elseif mode == 3 | mode == 4
                cfg.STO = round(vector(k));
            elseif mode == 6
                cfg.k_coef = vector(k);
            end
            % to reevaluate cfg
            blocks{5} = @(x) synchronisationError(x, cfg, mode);
            blocks{7} = @(x) synchronisationError(x, cfg, -mode);
            blocks{8} = @(x) gardner2(x, cfg, gardner_mode);
            for i = 5:7
                signal{i+1} = blocks{i}(signal{i});
            end
            if gardner_mode == 3 | gardner_mode == 2
                [signal{9},error_time] = blocks{8}(signal{8});
            elseif gardner_mode == 1
                [signal{9}] = blocks{8}(signal{8});
            end
            for i = 9:length(blocks)
                signal{i+1} = blocks{i}(signal{i});
            end

            if gardner_mode == 2 | gardner_mode == 3

                error_matrix(:,k+(l-1)*length(vector)) = error_time; % Filling error matrix with error time tracking for each repetition l
                %% Check result
            
                % % Calculate and display the Mean Squared Error between input and output (MSE)
                % mse = mean((signal{1} - signal{end}).^2);
                % if mode == 4
                %     disp(['Mean Squared Error (MSE) for time offset of ',num2str(cfg.STO), ' samples : ' num2str(mse*100), '%']);
                % elseif mode == 5
                %     disp(['Mean Squared Error (MSE) for time offset of ',num2str(cfg.STO), ' samples with CFO of ',num2str(cfg.CFO_ratio),' : ', num2str(mse*100), '%']);
                % end
            end
        end
    end

       %% Averaging the curves

       Error_average = zeros((cfg.NumBits/cfg.mapping_params.Nbps),length(cfg.STO_vec));
       for  i= 1:length(vector) 
           for l = 1:repetition
                temp_sum = temp_sum + error_matrix(:,i+length(vector)*(l-1));
           end
           Error_average(:,i) = temp_sum./repetition;
           temp_sum = 0;
       end

       %% Standard Deviation calculation

       Covariance = cell(1, length(vector));
       for i = 1:length(vector)
           Covariance{i} = zeros(length(error_time),length(error_time));
           for l = 1:repetition
               Covariance{i} = Covariance{i} + (error_matrix(:,i+(l-1)*length(vector))-Error_average(:,i))*(error_matrix(:,i+(l-1)*length(vector))-Error_average(:,i))';
           end
           Covariance{i} = Covariance{i}/repetition;
       end

       std = cell(1, length(vector));
       for i = 1:length(vector)
           std{i} = zeros(length(error_time),1);
           for l = 1:length(error_time)
                std{i}(l,1) = sqrt(Covariance{i}(l,l));
           end
       end

       %%  Convergence
       if gardner_mode == 2 | gardner_mode == 3 
           figure();
           symbol_nbre = [0:1:(cfg.NumBits/cfg.mapping_params.Nbps)-1];
           for k = 1:length(vector)
               plot(symbol_nbre,Error_average(:,k),'--', 'LineWidth',0.5,'Color',colors(k,:));
               hold on
               Uncert_high = Error_average(:,k)+std{k};
               Uncert_low = Error_average(:,k)-std{k};
               % plot(symbol_nbre,Uncert_high, 'LineWidth',0.5,'Color',colors(k,:));
               % hold on
               % plot(symbol_nbre,Uncert_high,'*','Color',colors(k,:));
               % hold on
               % plot(symbol_nbre,Uncert_low, 'LineWidth',0.5,'Color',colors(k,:));
               % hold on
               % plot(symbol_nbre,Uncert_low,'*','Color',colors(k,:));
               % hold on
               fill([symbol_nbre, fliplr(symbol_nbre)], [Uncert_high', fliplr(Uncert_low')], colors(k,:), 'FaceAlpha', 0.3, 'EdgeColor', 'none');
               hold on
               if mode == 4
                   yline(round(cfg.STO_vec(k))/cfg.RRC_params.fs,'LineWidth',0.5,'Color',colors(k,:)); % Convert to MHz
                   hold on
               end
           end
           if mode == 5
                   yline(round(cfg.STO)/cfg.RRC_params.fs,'--','LineWidth',0.5,'Color','r'); % Convert to MHz
                   hold on
           end
           title('Time correction trough symbol transmission');
           xlabel('Symbol');
           ylabel('Time Error (s)');
           if mode == 4
               legend_entries = arrayfun(@(x) ['Time offset - ', num2str(x), ' samples'], cfg.STO_vec, 'UniformOutput', false);
               legend_entries = [legend_entries; strcat(legend_entries, '+- std'); strcat(legend_entries, 'Target') ];
               grid on
           elseif mode ==5
               legend_entries = arrayfun(@(x) ['CFO Shift - ', num2str(x*1e6), ' ppm'], cfg.CFO_ratio_vec, 'UniformOutput', false);
               legend_entries = [legend_entries; strcat(legend_entries, '+- std')];
               grid on
           elseif mode ==6
               legend_entries = arrayfun(@(x) ['K coefficient - ', num2str(x)], cfg.k_coef_vec, 'UniformOutput', false);
               legend_entries = [legend_entries; strcat(legend_entries, '+- std')];
               grid on
           end
           
           legend(legend_entries(:));
       end