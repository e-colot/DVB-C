function output = downsample(input, cfg,OSF)
    output = zeros(1, cfg.NumBits/cfg.mapping_params.Nbps);
    input = [input , zeros(1, cfg.NumBits*OSF/cfg.mapping_params.Nbps - length(input))];
    for i = 1:length(output)
        output(i) = input(OSF*i);
    end
end
