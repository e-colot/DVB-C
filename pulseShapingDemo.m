cfg = config();

bitstream = [1 0 1 0 1 1 1 1];

upsampled = upsample(bitstream, cfg.OSF);

rrc_half_filtered = RRC_filtering(upsampled, cfg.RRC_params, 0);
rrc_fully_filtered = RRC_filtering(rrc_half_filtered, cfg.RRC_params, 1);

downsampled = downsample(rrc_fully_filtered, cfg.OSF);

figure;

subplot(4,1,1);
stem(bitstream, 'filled');
title('Original Bitstream');
xlabel('Sample');
ylabel('Amplitude');

subplot(4,1,2);
stem(upsampled, 'filled');
title('Upsampled Bitstream');
xlabel('Sample');
ylabel('Amplitude');

subplot(4,1,3);
plot(rrc_fully_filtered);
hold on;
plot(10:10:length(rrc_fully_filtered), rrc_fully_filtered(10:10:end), 'o');
title('RC Filtered Signal');
xlabel('Sample');
ylabel('Amplitude');
hold off;

subplot(4,1,4);
stem(downsampled, 'filled');
title('Downsampled Signal');
xlabel('Sample');
ylabel('Amplitude');

