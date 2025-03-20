function output = RRC_filtering(input, params, mode)
    % mode 0: RRC for TX
    % mode 1: RRC for RX
    % mode 2: show filter

    stepOffset = params.fs/params.taps;
    highestFreq = stepOffset*(params.taps-1)/2;
    freqGrid = linspace(-highestFreq, highestFreq, params.taps);

    rc_freq = zeros(1, params.taps);

    T = 1/params.symbolRate;
    lim_inf = (1-params.rolloff)/(2*T);
    lim_sup = (1+params.rolloff)/(2*T);

    for i = 1:params.taps
        if (abs(freqGrid(i)) < lim_inf)
            rc_freq(i) = T;
        elseif (abs(freqGrid(i)) <= lim_sup)
            rc_freq(i) = T/2 * (1+cos((pi*T/params.rolloff)*(abs(freqGrid(i))-lim_inf)));
        end
    end

    rrc_freq = sqrt(rc_freq);

    rrc_freq_shifted = ifftshift(rrc_freq);
    rrc_temp = fftshift((ifft(rrc_freq_shifted)));

    rrc_temp = rrc_temp/norm(rrc_temp);

    if (mode == 1)

        % because at RX, the signal is convoluted with h(-t)
        rrc_temp = fliplr(rrc_temp);
    
    elseif (mode == 2)
        rc_temp = (fftshift(ifft(ifftshift(rc_freq))));
    
        figure;
        subplot(2, 1, 1);
        plot(freqGrid, rc_freq);
        title('raised cosine filter frequency response');
        xlabel('Frequency (Hz)');
        ylabel('Magnitude');
        grid on;
        
        subplot(2, 1, 2);
        plot(rc_temp);
        title('raised cosine filter impulse response');
        xlabel('Samples');
        ylabel('Amplitude');
        grid on;
    end

    output = conv(input, rrc_temp);

    if (mode == 1)
        output = output(params.taps:end-(params.taps-1));
    end

end
