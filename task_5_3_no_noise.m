cfg = config();

mode = 3; %Error type


if mode == 1
    vector = cfg.CFO_ratio_vec;
elseif mode == 2
    vector = linspace(0, 2*pi*4/5, 5);
elseif mode == 3
    vector = cfg.STO_vec;
end

    % To add a new block to the transmission chain, add the corresponding function in the handle function list "blocks"
    blocks = { ...
        @(x) mapping(x, cfg.mapping_params), ...
        @(x) upsample(x, cfg.OSF), ...
        @(x) RRC_filtering(x, cfg.RRC_params, 0), ...
        @(x) synchronisationError(x, cfg, mode), ...
        @(x) RRC_filtering(x, cfg.RRC_params, 1), ...
        @(x) gardner(x, cfg), ...
        @(x) downsample(x, cfg, cfg.OSF), ...
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

        for k = 1:length(vector)
            if mode == 1
                cfg.CFO_ratio = vector(k);
            elseif mode == 2
                cfg.phase = vector(k);
            elseif mode == 3
                cfg.STO = round(vector(k));
            end
            % to reevaluate cfg
            blocks{4} = @(x) synchronisationError(x, cfg, mode);
            blocks{6} = @(x) gardner(x, cfg);
            for i = 4:5
                signal{i+1} = blocks{i}(signal{i});
            end
            [signal{7},error_time, collect_slope, mid_points, correction_real] = blocks{6}(signal{6});
            for i = 7:length(blocks)
                signal{i+1} = blocks{i}(signal{i});
            end
        end
        


   %% Plot Time offset correction per nbre of symbol


   figure();
   symbol_nbre = [0:1:(cfg.NumBits/cfg.mapping_params.Nbps)-1];
   plot(symbol_nbre,error_time, 'LineWidth',0.5,'Color','b');
   title('Time correction trough symbol transmission');
   xlabel('Symbol');
   ylabel('Time Error (s)');

   figure();
   symbol_range_test = symbol_nbre(1 : 20);
   % plot(symbol_range_test, sqrt(abs(signal{2}(1 : 20)).^2),'LineWidth',0.5,'Color','b');
   title('Symbol sampling visualization');
   xlabel('Symbol');
   ylabel('magnitude');
   hold on
   
   sumbol_range_delay = symbol_nbre + (error_time*cfg.RRC_params.fs/cfg.OSF)';
   plot(sumbol_range_delay(1 : 20)+1.5, sqrt(abs(mid_points(1 : 20)).^2),"*",'Color','b');
   hold on

   plot(sumbol_range_delay(1 : 20)+1, sqrt(abs(collect_slope(1:20)).^2), '--', 'LineWidth', 0.5, 'Color', 'g');
   hold on

   plot(sumbol_range_delay(1 : 20)+1, sqrt(abs(collect_slope(1:20)).^2), 'x', 'Color', 'g');
   hold on

   symbol_range_test_2 = linspace(0,20,400);

   plot(symbol_range_test_2, sqrt(abs(signal{6}(1:20*cfg.OSF)).^2),'--', 'LineWidth', 0.5, 'Color', 'b');
   hold on
    
   result_signal_6 = zeros(1,20);
   result_signal_3 = zeros(1,20);
   symbol_range_test_3 = [cfg.STO/20+1:1:20+cfg.STO/20];
   symbol_range_test_4 = [1:1:20];
   for i = 1:20
       result_signal_3(i) = signal{3}((i)*20);
       result_signal_6(i) = signal{6}((i)*20+cfg.STO);
   end
   plot(symbol_range_test_3, sqrt(abs(result_signal_6).^2),  'o', 'Color', 'r');
   hold on


   %% Check result

   % Calculate and display the Mean Squared Error between input and output (MSE)
    mse = mean((signal{1} - signal{end}).^2);
    disp(['Mean Squared Error (MSE): ', num2str(mse)]);

    N = 250; % Number of symbols to plot

    % % source and demodulated signal comparison
    % figure('Position', [100, 100, 600, 600]);
    % stairs(signal{1}(1:N), 'LineWidth', 2);
    % hold on
    % stairs(signal{end}(1:N), 'r--');
    % title('Comparison of Source and Demodulated Signal');
    % xlabel('Bit Index');
    % ylabel('Value');
    % ylim([-0.5 1.75]);
    % legend('Source Signal', 'Demodulated Signal');
    % hold off
   