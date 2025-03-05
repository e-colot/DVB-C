cfg = config();

% To add a new block to the transmission chain, add the corresponding function in the handle function list "blocks"
blocks = { ...
    @(x) mapping(x, cfg.mapping_params), ...
    @(x) upsample(x, cfg.OSF), ...
    @(x) RRC_filtering(x, cfg.RRC_params), ...
    @(x) RRC_filtering(x, cfg.RRC_params), ...
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

% to only show the first 200 bits
l = 200;
if length(signal{1}) < l
    l = length(signal{1});
end

% source and demodulated signal comparison
figure('Position', [100, 100, 800, 600]);
subplot(3,1,1);
stairs(signal{1}(1:l), 'LineWidth', 2);
hold on
stairs(signal{7}(1:l), 'r--');
title('Comparison of Source and Demodulated Signal');
xlabel('Bit Index');
ylabel('Value');
ylim([-0.5 1.75]);
legend('Source Signal', 'Demodulated Signal');
hold off

% mean square error
mse = norm(signal{1} - signal{7})^2 / length(signal{1});
subplot(3,1,2);
text(0.5, 0.5, ['Mean Square Error: ', num2str(mse)], 'HorizontalAlignment', 'center', 'FontSize', 12);
axis off;

% constellation diagram
subplot(3,1,3);
plot(signal{2}, 'o');
title('Constellation Diagram');
xlabel('Real Part');
ylabel('Imaginary Part');
axis equal;
grid on;
