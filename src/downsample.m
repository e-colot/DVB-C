function output = downsample(input, cfg)
    output = zeros(1, cfg.NumBits/cfg.mapping_params.Nbps);
    input = [input , zeros(1, cfg.NumBits*cfg.OSF/cfg.mapping_params.Nbps - length(input))];
    for i = 1:length(output)
        output(i) = input(cfg.OSF*i);
    end
end
