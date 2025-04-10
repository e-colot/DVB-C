project_root = fileparts(mfilename('fullpath')); % Get project root
src_path = fullfile(project_root, '..');
if ~contains(path, src_path)
    addpath(genpath(src_path));
end


cfg = config();

x = randi([0 1], 1, cfg.pilot_params.N*10); % Generate random bits

pilotPos = 0.5*cfg.pilot_params.N + round(cfg.pilot_params.N*9 * rand());

x(pilotPos:pilotPos+cfg.pilot_params.N-1) = cfg.pilot; % Insert pilot bits

disp('Pilot position: ');
disp(pilotPos);

figure;
plot([pilotPos pilotPos], ylim, '--', 'LineWidth', 1.5); % Plot vertical dotted red line
hold on;

frame_aquisition(x, cfg, 1);

legend('Correlation', 'True pilot position'); % Add legend
hold off;
