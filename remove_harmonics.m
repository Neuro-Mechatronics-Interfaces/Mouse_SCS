function reconstructed_signal = remove_harmonics(signal, fs, fharmonic, ftol)
%REMOVE_HARMONICS Function to remove 60Hz noise and its harmonics from a signal
%
% Parameters:
%   signal (vector): Input time-domain signal
%   fs (scalar): Sampling frequency of the input signal
%   fharmonic (scalar, optional): Default is 60Hz - which frequency/harmonics to remove?
%   ftol (scalar, optional): Default is 12.5Hz - Tolerance around fundamental harmonic to remove.
%
% Returns:
%   reconstructed_signal (vector): Signal with 60Hz noise and harmonics removed

arguments
    signal (1,:) double
    fs (1,1) double = 20000; % Intan amplifier data sampling rate
    fharmonic (1,1) double = 60;
    ftol (1,1) double = 12.5;
end

% Transform the signal to the frequency domain
N = length(signal);
Y = fft(signal);

% Frequency vector
f = (0:N-1)*(fs/N);
[~,iFundamental] = min(abs(f-fharmonic));
fharmonic_fundamental = f(iFundamental);
fh = f(abs(f-fharmonic_fundamental)<ftol);
for fsubtract = fh
    % Identify the indices corresponding to 60Hz and its harmonics
    for k = 1:floor(fs/(2*fsubtract))
        harmonic_idx = abs(f - k*fsubtract) < fs/N;
        Y(harmonic_idx) = 0;  % Remove the frequency component
    end
end

% Transform the signal back to the time domain
reconstructed_signal = ifft(Y, 'symmetric');
end
