function output = downsample(input, cfg,OSF)
    output = zeros(1, cfg.NumBits/cfg.mapping_params.Nbps);
    for i = 1:length(output)
        output(i) = input(OSF*i);
    end
end
