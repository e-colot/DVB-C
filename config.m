% constants and configuration of the project

function cfg = config()
    % setup the path
    project_root = fileparts(mfilename('fullpath')); % Get project root
    src_path = fullfile(project_root, 'src');
    if ~contains(path, src_path)
        addpath(genpath(src_path));
    end

    cfg = struct();

end
