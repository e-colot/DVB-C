function output = awgn(input, params, N_0)

freq_s = params.OSF*params.RRC_params.symbolRate;

N = length(input);

noise_real = randn(1,N).*sqrt(N_0*freq_s);
noise_imag = randn(1,N).*sqrt(N_0*freq_s);

output = input + noise_real + 1j * noise_imag;

end

