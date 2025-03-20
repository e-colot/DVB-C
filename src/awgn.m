function output = awgn(input, params, N_0)

L = length(input);

noise_real = randn(1,L).*sqrt(N_0*params.RRC_params.fs);
noise_imag = randn(1,L).*sqrt(N_0*params.RRC_params.fs);

output = input + noise_real + 1j * noise_imag;

end

