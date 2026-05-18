%% ============================================================
%  MOTOR VIBRATION FAULT DETECTION - FIXED VERSION
%  Using FFT, STFT/Spectrogram, and Bandpass Filtering
%  Course: Digital Signal Processing (DSP)
%  ============================================================

clear; clc; close all;

%% PART 1: GENERATE MOTOR DATA
fprintf('=== PART 1: Generating Motor Vibration Data ===\n');

fs = 5000;
dt = 1/fs;
T_total = 5;
t = 0:dt:T_total-dt;
N = length(t);

f_rotor = 60;
f_bearing_BPFO = 156.2;
f_bearing_BPFI = 203.8;

noise_level = 0.02;
signal_healthy = sin(2*pi*f_rotor*t) + noise_level*randn(size(t));

fault_amplitude = 0.3;
signal_fault = sin(2*pi*f_rotor*t) + ...
    fault_amplitude*sin(2*pi*f_bearing_BPFO*t) + ...
    noise_level*randn(size(t));

noise_heavy = 0.15;
signal_noisy = signal_fault + noise_heavy*randn(size(t));

fprintf('Generated 3 signals successfully.\n');

%% PART 2: TIME DOMAIN PLOT
fprintf('\n=== PART 2: Time Domain Visualization ===\n');

figure('Name','Time Domain Signals');

subplot(3,1,1);
plot(t(1:2500), signal_healthy(1:2500), 'b', 'LineWidth', 0.8);
title('Healthy Motor');
ylabel('Amplitude'); grid on;

subplot(3,1,2);
plot(t(1:2500), signal_fault(1:2500), 'r', 'LineWidth', 0.8);
title('Motor with Bearing Fault - Outer Race');
ylabel('Amplitude'); grid on;

subplot(3,1,3);
plot(t(1:2500), signal_noisy(1:2500), 'Color', [0.8 0.4 0], 'LineWidth', 0.8);
title('Noisy Motor Signal');
xlabel('Time (s)'); ylabel('Amplitude'); grid on;

saveas(gcf, 'fig1_time_domain.png');

%% PART 3: FFT ANALYSIS
fprintf('\n=== PART 3: FFT Frequency Domain Analysis ===\n');

L = N;
f = fs*(0:(L/2))/L;

Y_healthy = fft(signal_healthy);
P2_healthy = abs(Y_healthy/L);
P_healthy = P2_healthy(1:L/2+1);
P_healthy(2:end-1) = 2*P_healthy(2:end-1);

Y_fault = fft(signal_fault);
P2_fault = abs(Y_fault/L);
P_fault = P2_fault(1:L/2+1);
P_fault(2:end-1) = 2*P_fault(2:end-1);

Y_noisy = fft(signal_noisy);
P2_noisy = abs(Y_noisy/L);
P_noisy = P2_noisy(1:L/2+1);
P_noisy(2:end-1) = 2*P_noisy(2:end-1);

figure('Name','FFT Spectrum');

subplot(3,1,1);
plot(f, P_healthy, 'b', 'LineWidth', 1.2);
title('Healthy Motor - FFT Spectrum');
ylabel('|Amplitude|'); grid on; xlim([0 500]); ylim([0 1.2]);

subplot(3,1,2);
plot(f, P_fault, 'r', 'LineWidth', 1.2);
hold on;
yl = ylim;
plot([f_bearing_BPFO f_bearing_BPFO], yl, 'g--', 'LineWidth', 1.5);
text(f_bearing_BPFO+5, 0.9, 'BPFO Fault', 'Color', 'g', 'FontSize', 10);
title('Faulty Motor - FFT Spectrum');
ylabel('|Amplitude|'); grid on; xlim([0 500]); ylim([0 1.2]);

subplot(3,1,3);
plot(f, P_noisy, 'Color', [0.8 0.4 0], 'LineWidth', 1.2);
hold on;
yl = ylim;
plot([f_bearing_BPFO f_bearing_BPFO], yl, 'g--', 'LineWidth', 1.5);
text(f_bearing_BPFO+5, 1.1, 'BPFO Fault', 'Color', 'g', 'FontSize', 10);
title('Noisy Motor - FFT Spectrum');
xlabel('Frequency (Hz)'); ylabel('|Amplitude|'); grid on;
xlim([0 500]); ylim([0 1.5]);

saveas(gcf, 'fig2_fft_analysis.png');

%% PART 4: STFT ANALYSIS
fprintf('\n=== PART 4: STFT / Spectrogram Analysis ===\n');

window_length = 512;
overlap = 256;
nfft = 1024;
win = hamming(window_length);

figure('Name','STFT Spectrograms');

subplot(3,1,1);
spectrogram(signal_healthy, win, overlap, nfft, fs, 'yaxis');
title('Healthy Motor - STFT');
ylim([0 0.5]);

subplot(3,1,2);
spectrogram(signal_fault, win, overlap, nfft, fs, 'yaxis');
title('Faulty Motor - STFT');
ylim([0 0.5]);

subplot(3,1,3);
spectrogram(signal_noisy, win, overlap, nfft, fs, 'yaxis');
title('Noisy Motor - STFT');
ylim([0 0.5]);

saveas(gcf, 'fig3_stft_analysis.png');

%% PART 5: BANDPASS FILTERING
fprintf('\n=== PART 5: Bandpass Filtering ===\n');

bw = 20;
low_cut = (f_bearing_BPFO-bw)/(fs/2);
high_cut = (f_bearing_BPFO+bw)/(fs/2);

[b, a] = butter(4, [low_cut high_cut], 'bandpass');
signal_filtered = filtfilt(b, a, signal_noisy);

figure('Name','Filtering Results');

subplot(2,1,1);
plot(t(1:2500), signal_noisy(1:2500), 'Color', [0.8 0.4 0], 'LineWidth', 0.8);
title('Noisy Signal - Before Filtering');
ylabel('Amplitude'); grid on;

subplot(2,1,2);
plot(t(1:2500), signal_filtered(1:2500), 'g', 'LineWidth', 1.2);
title('Filtered Signal - Fault Frequency Isolated');
ylabel('Amplitude'); xlabel('Time (s)'); grid on;

saveas(gcf, 'fig4_filtering.png');

%% SUMMARY
fprintf('\n=============================================================\n');
fprintf('MOTOR VIBRATION FAULT DETECTION - COMPLETE\n');
fprintf('=============================================================\n');
