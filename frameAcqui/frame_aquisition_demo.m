project_root = fileparts(mfilename('fullpath')); % Get project root
src_path = fullfile(project_root, '..');
if ~contains(path, src_path)
    addpath(genpath(src_path));
end


cfg = config();

cfg.pilot_length = 20;
cfg.pilotK = 8;
cfg.pilot = randi([0 1], 1, cfg.pilot_length*cfg.mapping_params.Nbps);

x = randi([0 1], 1, cfg.pilot_length*cfg.mapping_params.Nbps*10); % Generate random bits
x = mapping(x, cfg.mapping_params); % Map bits to symbols

pilotPos = 100;

mappedPilot = mapping(cfg.pilot, cfg.mapping_params); % Map pilot bits to symbols
x(pilotPos:pilotPos+length(mappedPilot)-1) = mappedPilot; % Insert pilot bits

disp('Pilot position: ');
disp(pilotPos);

figure;
plot([pilotPos pilotPos], [0 100], '--', 'LineWidth', 1.5); % Plot vertical dotted red line
hold on;

frame_aquisition(x, cfg, 1);

legend('True pilot position', 'Correlation'); % Add legend
hold off;
