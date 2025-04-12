cfg = config();

colors = lines(length(cfg.STO_vec)); % Generate distinct colors for each iteration
disp(['SNR is fixed at ', num2str(cfg.EbN0_interval(1)), ' dB']);
disp(['CFO is fixed at ', num2str(cfg.CFO_ratio), ' ppm']);

mode = 4; %Error type
gardner_mode = 2; % mode of output (without visu [1], with visualisation of time offset and MSE [2] or with full visualisation [3]) 

if mode == 1
    vector = cfg.CFO_ratio_vec;
elseif mode == 2
    vector = linspace(0, 2*pi*4/5, 5);
elseif mode == 3
    vector = cfg.STO_vec;
elseif mode == 4
    vector = cfg.STO_vec;
end

    % To add a new block to the transmission chain, add the corresponding function in the handle function list "blocks"
    blocks = { ...
        @(x) mapping(x, cfg.mapping_params), ...
        @(x) upsample(x, cfg.OSF), ...
        @(x) RRC_filtering(x, cfg.RRC_params, 0), ...
        @(x, N_0) awgn(x, cfg, N_0), ...
        @(x) synchronisationError(x, cfg, mode), ...
        @(x) RRC_filtering(x, cfg.RRC_params, 1), ...
        @(x) synchronisationError(x, cfg, -mode), ...
        @(x) gardner(x, cfg, gardner_mode), ...
        @(x) downsample(x, cfg), ...
        @(x) demapping(x, cfg.mapping_params) ...
    };

    signal = cell(1, length(blocks) + 1);

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

    error_matrix = zeros((cfg.NumBits/cfg.mapping_params.Nbps),length(cfg.STO_vec));
    signal{5} = blocks{4}(signal{4}, N_0);       
        for k = 1:length(vector)
            if mode == 1
                cfg.CFO_ratio = vector(k);
            elseif mode == 2
                cfg.phase = vector(k);
            elseif mode == 3
                cfg.STO = round(vector(k));
            elseif mode == 4
                cfg.STO = round(vector(k));
            end
            % to reevaluate cfg
            blocks{5} = @(x) synchronisationError(x, cfg, mode);
            blocks{8} = @(x) gardner(x, cfg, gardner_mode);
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
                error_matrix(:,k) = error_time;
                %% Check result
    
                % Calculate and display the Mean Squared Error between input and output (MSE)
                mse = mean((signal{1} - signal{end}).^2);
                disp(['Mean Squared Error (MSE) for time offset of ',num2str(cfg.STO), ' samples : ' num2str(mse*100), '%']);
            end
        end


       %%  Convergence
       if gardner_mode == 2 | gardner_mode == 3 
           figure();
           symbol_nbre = [0:1:(cfg.NumBits/cfg.mapping_params.Nbps)-1];
           for k = 1:length(vector)
               plot(symbol_nbre,error_matrix(:,k), 'LineWidth',0.5,'Color',colors(k,:));
               hold on
               yline(round(cfg.STO_vec(k))/cfg.RRC_params.fs,'--','LineWidth',0.5,'Color',colors(k,:)); % Convert to MHz
               hold on
           end
           title('Time correction trough symbol transmission');
           xlabel('Symbol');
           ylabel('Time Error (s)');
           legend_entries = arrayfun(@(x) ['Time offset -', num2str(x), ' samples'], cfg.STO_vec, 'UniformOutput', false);
           legend_entries = [legend_entries; strcat(legend_entries, ' Target')];
           legend(legend_entries(:));
       end