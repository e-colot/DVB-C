function output = downsample(input, OSF)
    output = zeros(1, length(input)/OSF);
    for i = 1:length(output)
        output(i) = input(OSF*i);
    end
end
