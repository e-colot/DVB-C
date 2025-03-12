cfg = config();

% To add a new block to the transmission chain, add the corresponding function in the handle function list "blocks"
blocks = { ...
    @(x) mapping(x, cfg.mapping_params), ...
    @(x) upsample(x, cfg.OSF), ...
    @(x) RRC_filtering(x, cfg.RRC_params, 0), ...
    @(x) RRC_filtering(x, cfg.RRC_params, 2), ...
    @(x) downsample(x, cfg.OSF), ...
    @(x) demapping(x, cfg.mapping_params) ...
};

signal = cell(1, length(blocks) + 1);

% Generate random bits
signal{1} = randi([0 1], 1, cfg.NumBits);

% Run the blocks
for i = 1:length(blocks)
    signal{i+1} = blocks{i}(signal{i});
end

N = 250; % Number of symbols to plot

figure;
plot(real(signal{3}(1:N)), 'LineWidth', 2);
hold on;
plot(real(signal{4}(1:N)), 'LineWidth', 2);
plot(real(signal{5}(1:N)), 'LineWidth', 2);
title('Impact of RRC filtering on the signal');
xlabel('Sample index');
ylabel('Amplitude');
legend('before RRC', 'after one RRC', 'after both RRC');
hold off;

% source and demodulated signal comparison
figure('Position', [100, 100, 600, 600]);
stairs(signal{1}(1:N), 'LineWidth', 2);
hold on
stairs(signal{end}(1:N), 'r--');
title('Comparison of Source and Demodulated Signal');
xlabel('Bit Index');
ylabel('Value');
ylim([-0.5 1.75]);
legend('Source Signal', 'Demodulated Signal');
hold off

% constellation diagram of signal{6}
figure;
plot(signal{6}, 'o');
hold on;
plot(signal{2}, 'rx');
title('Constellation Diagram');
xlabel('Real Part');
ylabel('Imaginary Part');
legend('Signal 6', 'Signal 2');
hold off;
axis equal;
grid on;

% Calculate and display the Mean Squared Error (MSE)
mse = mean((signal{1} - signal{end}).^2);
disp(['Mean Squared Error (MSE): ', num2str(mse)]);
