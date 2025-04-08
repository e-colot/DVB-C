cfg = config();

mode = 1; %Error type
mode_inv = -mode;

if mode == 0
    vector = cfg.CFO_ratio_vec;
elseif mode == 1
    vector = cfg.CFO_ratio_vec;
elseif mode ==3
    vector = cfg.SFO_ratio_vec;
end

    % To add a new block to the transmission chain, add the corresponding function in the handle function list "blocks"
    blocks = { ...
        @(x) mapping(x, cfg.mapping_params), ...
        @(x) upsample(x, cfg.OSF), ...
        @(x) RRC_filtering(x, cfg.RRC_params, 0), ...
        @(x, N_0) awgn(x, cfg, N_0), ...
        @(x) synchronisationError(x, cfg, mode), ...
        @(x) RRC_filtering(x, cfg.RRC_params, 1), ...
        @(x) synchronisationError(x, cfg, mode_inv), ...
        @(x) downsample(x, cfg.OSF), ...
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
    EbN0 = linspace(cfg.EbN0_interval(1), cfg.EbN0_interval(2), cfg.BER_resolution);
    N_0 = Energy_bit./(10.^(EbN0/10));

    BER = zeros(length(N_0),length(vector));

    for j = 1:length(N_0)
        signal{5} = blocks{4}(signal{4}, N_0(j));
        for k = 1:length(vector)
            cfg.CFO_ratio = cfg.CFO_ratio_vec(k);
            % to reevaluate cfg
            blocks{5} = @(x) synchronisationError(x, cfg, mode);
            blocks{7} = @(x) synchronisationError(x, cfg, mode_inv);
            for i = 5:length(blocks)
                signal{i+1} = blocks{i}(signal{i});
            end
            errors = sum(abs(signal{end} - signal{1}) > 0);
            BER(j, k) = errors/cfg.NumBits;
        end
        
    end


    %%  Plots

    % Eb/No
    Energy_per_noise =10*log10(Energy_bit./N_0);

    for k = 1:length(vector)
        % Plot the BER for each CFO ratio
        semilogy(Energy_per_noise, BER(:, k), "LineWidth", 2);
        hold on;
    end

    theoreticalBER = berawgn(EbN0, 'qam', 2^cfg.mapping_params.Nbps);
    semilogy(Energy_per_noise, theoreticalBER, "LineWidth", 2, "LineStyle", "--", 'Color', 'k');

if mode == 0
    title('Bit Error Rate for Full Synchro errors');
    xlabel('Eb/N_0 (Decibel)');
    ylabel('BER');
    legend_entries = arrayfun(@(x) ['CFO-', num2str(cfg.CFO_ratio)], cfg.CFO_ratio_vec, 'UniformOutput', false);
    legend_entries = [legend_entries; strcat(legend_entries, ' Theoretical')];
    legend(legend_entries(:));
    xlim(cfg.EbN0_interval);
    ylim([1e-5 1]);
    grid on;
elseif mode ==1
    title('Bit Error Rate for CFO ppm');
    xlabel('Eb/N_0 (Decibel)');
    ylabel('BER');
    legend_entries = arrayfun(@(x) ['CFO - ', num2str(x*1e6), 'ppm - ' , num2str(x*cfg.fc), ' Hz'], cfg.CFO_ratio_vec, 'UniformOutput', false);
    legend_entries = [legend_entries, strcat('QAM-',num2str(2^cfg.mapping_params.Nbps),' Theoretical')];
    legend(legend_entries(:));
    xlim(cfg.EbN0_interval);
    ylim([1e-5 1]);
    grid on;
elseif mode ==2
    figure;
    plot(signal{end-1}, 'o');
    hold on;
    plot(signal{2}, 'rx');
    title('Constellation Diagram');
    xlabel('Real Part');
    ylabel('Imaginary Part');
    legend('before transmission', 'after transmission with phase offset');
    hold off;
    axis equal;
    grid on;
elseif mode ==3
    title('Bit Error Rate for time offset');
    xlabel('Eb/N_0 (Decibel)');
    ylabel('BER');
    legend_entries = arrayfun(@(x) ['Time offset -', num2str(cfg.CFO_ratio)], cfg.SFO_ratio, 'UniformOutput', false);
    legend_entries = [legend_entries; strcat(legend_entries, ' Theoretical')];
    legend(legend_entries(:));
    xlim(cfg.EbN0_interval);
    ylim([1e-5 1]);
    grid on;
end
