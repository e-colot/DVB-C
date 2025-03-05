function output = upsample(input, OSF)
    output = zeros(1, OSF * length(input));
    for i = 1:length(input)
        output(OSF*i) = input(i);
    end
end
