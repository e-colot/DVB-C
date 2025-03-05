function output = RRC_filtering(input, params)

    stepOffset = params.fs/params.taps;
    highestFreq = stepOffset*(params.taps-1)/2;
    freqGrid = linspace(-highestFreq, highestFreq, params.taps);

    rc_freq = zeros(1, params.taps);

    T = 1/params.bandwidth;
    lim_inf = (1-params.rolloff)/(2*T);
    lim_sup = (1+params.rolloff)/(2*T);

    for i = 1:params.taps
        if (abs(freqGrid(i)) <= lim_inf)
            rc_freq(i) = T;
        elseif (abs(freqGrid(i)) <= lim_sup)
            rc_freq(i) = T/2 * (1+cos((pi*T/params.rolloff)*(abs(freqGrid(i)-lim_inf))));
        end
    end

    rrc_freq = sqrt(rc_freq);

    rrc_freq_shifted = ifftshift(rrc_freq);
    rrc_temp = fftshift(real(ifft(rrc_freq_shifted)));

    rrc_temp = rrc_temp/max(rrc_temp);

    % rrc_builtin = rcosdesign(params.rolloff, params.taps, params.fs/params.bandwidth, 'sqrt');

    % figure;
    % subplot(2, 1, 1);
    % plot(rrc_temp);
    % title('Custom RRC Filter');
    % subplot(2, 1, 2);
    % plot(rrc_builtin);
    % title('MATLAB Built-in RRC Filter');

    % figure;
    % subplot(2, 1, 1);
    % plot(freqGrid, rrc_freq);
    % subplot(2, 1, 2);
    % plot(rrc_temp);

    input_filtered = conv(input, rrc_temp);

    output = input_filtered((params.taps+1)/2:end-((params.taps-1)/2));

end
