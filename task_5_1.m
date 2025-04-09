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
        @(x, N_0) awgn(x, cfg, N_0), ...
        @(x) synchronisationError(x, cfg, mode), ...
        @(x) RRC_filtering(x, cfg.RRC_params, 1), ...
        @(x) synchronisationError(x, cfg, -mode), ...
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
            if mode == 1
                cfg.CFO_ratio = vector(k);
            elseif mode == 2
                cfg.phase = vector(k);
            elseif mode == 3
                cfg.STO = vector(k);
            end
            % to reevaluate cfg
            blocks{5} = @(x) synchronisationError(x, cfg, mode);
            blocks{7} = @(x) synchronisationError(x, cfg, -mode);
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

elseif mode == 2
    title('Bit Error Rate for different phases');
    xlabel('Eb/N_0 (Decibel)');
    ylabel('BER');
    legend_entries = arrayfun(@(x) ['Phase shift - ', num2str(round(x, 3)), ' rad'], vector, 'UniformOutput', false);
    legend_entries = [legend_entries, strcat('QAM-',num2str(2^cfg.mapping_params.Nbps),' Theoretical')];
    legend(legend_entries(:));
    xlim(cfg.EbN0_interval);
    ylim([1e-5 1]);
    grid on;

    figure;
    plot(signal{end-1}, 'o');
    hold on;
    plot(signal{2}, 'rx');
    title('Constellation Diagram');
    xlabel('Real Part');
    ylabel('Imaginary Part');
    legend('after transmission with phase offset', 'before transmission');
    hold off;
    axis equal;
    grid on;
elseif mode == 3
    title('Bit Error Rate for time offset');
    xlabel('Eb/N_0 (Decibel)');
    ylabel('BER');
    legend_entries = arrayfun(@(x) ['Sample offset ', num2str(x)], vector, 'UniformOutput', false);
    legend_entries = [legend_entries; strcat('QAM-',num2str(2^cfg.mapping_params.Nbps),' Theoretical')];
    legend(legend_entries(:));
    xlim(cfg.EbN0_interval);
    ylim([1e-5 1]);
    grid on;
end
