%% ============================================================
%  THREE MOTOR VIBRATION FAULT DETECTION
%  Using FFT, STFT/Spectrogram, and Bandpass Filtering
%  Course: Digital Signal Processing (DSP)
%  ============================================================

clear; clc; close all;

%% PART 1: GENERATE MOTOR DATA
fprintf('=== PART 1: Generating Motor Vibration Data ===\n');

fs = 2000;              % Sampling frequency (Hz)
dt = 1/fs;              % Time step
T_total = 5;            % Total time (seconds)
t = 0:dt:T_total-dt;    % Time vector
N = length(t);          % Number of samples

f_rotor = 60;           % Rotor speed (Hz)
f_bearing_BPFO = 156.2; % Bearing outer race fault frequency (Hz)

noise_level = 0.02;
fault_amplitude = 0.30;

%% MOTOR 1 - HEALTHY
motor1 = sin(2*pi*f_rotor*t) + noise_level*randn(size(t));

%% MOTOR 2 - HEALTHY
motor2 = sin(2*pi*f_rotor*t) + noise_level*randn(size(t));

%% MOTOR 3 - FAULTY MOTOR
motor3 = sin(2*pi*f_rotor*t) + fault_amplitude*sin(2*pi*f_bearing_BPFO*t) + noise_level*randn(size(t));

%% ADD INDUSTRIAL NOISE
noise_heavy = 0.15;

motor1_noisy = motor1 + noise_heavy*randn(size(t));
motor2_noisy = motor2 + noise_heavy*randn(size(t));
motor3_noisy = motor3 + noise_heavy*randn(size(t));

fprintf('Generated 3 motor signals successfully.\n');

%% PART 2: TIME DOMAIN PLOT
fprintf('\n=== PART 2: Time Domain Visualization ===\n');

figure('Name','Time Domain Signals');

subplot(3,1,1);
plot(t(1:2500), motor1_noisy(1:2500), 'b', 'LineWidth', 0.8);
title('Motor 1 - Healthy');
ylabel('Amplitude');
grid on;

subplot(3,1,2);
plot(t(1:2500), motor2_noisy(1:2500), 'b', 'LineWidth', 0.8);
title('Motor 2 - Healthy');
ylabel('Amplitude');
grid on;

subplot(3,1,3);
plot(t(1:2500), motor3_noisy(1:2500), 'r', 'LineWidth', 0.8);
title('Motor 3 - Faulty');
xlabel('Time (s)');
ylabel('Amplitude');
grid on;

saveas(gcf, 'fig1_time_domain.png');

%% PART 3: FFT ANALYSIS
fprintf('\n=== PART 3: FFT Analysis ===\n');

L = N;
f = fs*(0:(L/2))/L;

motors = {motor1_noisy, motor2_noisy, motor3_noisy};
P_all = cell(1,3);

figure('Name','FFT Spectrum');

for m = 1:3
    Y = fft(motors{m});
    P2 = abs(Y/L);
    P1 = P2(1:L/2+1);
    P1(2:end-1) = 2*P1(2:end-1);
    P_all{m} = P1;

    subplot(3,1,m);
    if m == 3
        plot(f, P1, 'r', 'LineWidth', 1.2);
    else
        plot(f, P1, 'b', 'LineWidth', 1.2);
    end

    hold on;
    yl = ylim;
    plot([f_bearing_BPFO f_bearing_BPFO], yl, 'g--', 'LineWidth', 1.5);
    text(f_bearing_BPFO+5, max(yl)*0.8, 'BPFO Fault', 'Color', 'g');
    title(['Motor ' num2str(m) ' - FFT Spectrum']);
    ylabel('|Amplitude|');
    grid on;
    xlim([0 500]);
end

xlabel('Frequency (Hz)');
saveas(gcf, 'fig2_fft_analysis.png');

%% PART 4: STFT ANALYSIS
fprintf('\n=== PART 4: STFT Analysis ===\n');

window_length = 512;
overlap = 256;
nfft = 1024;
win = hamming(window_length);

figure('Name','STFT Spectrograms');

for m = 1:3
    subplot(3,1,m);
    spectrogram(motors{m}, win, overlap, nfft, fs, 'yaxis');
    title(['Motor ' num2str(m) ' - STFT']);
    ylim([0 0.5]);
end

saveas(gcf, 'fig3_stft_analysis.png');

%% PART 5: BANDPASS FILTERING
fprintf('\n=== PART 5: Bandpass Filtering ===\n');

bw = 20;
low_cut = (f_bearing_BPFO-bw)/(fs/2);
high_cut = (f_bearing_BPFO+bw)/(fs/2);
[b, a] = butter(4, [low_cut high_cut], 'bandpass');

filtered_motors = cell(1,3);

for m = 1:3
    filtered_motors{m} = filtfilt(b, a, motors{m});
end

figure('Name','Filtering Results');

subplot(2,1,1);
plot(t(1:2500), motor3_noisy(1:2500), 'Color', [0.8 0.4 0], 'LineWidth', 0.8);
title('Faulty Motor - Before Filtering');
ylabel('Amplitude');
grid on;

subplot(2,1,2);
plot(t(1:2500), filtered_motors{3}(1:2500), 'g', 'LineWidth', 1.2);
title('Faulty Motor - After Filtering');
ylabel('Amplitude');
xlabel('Time (s)');
grid on;

saveas(gcf, 'fig4_filtering.png');

%% PART 6: FFT AFTER FILTERING
fprintf('\n=== PART 6: FFT After Filtering ===\n');

Y_filtered = fft(filtered_motors{3});
P2_filtered = abs(Y_filtered/L);
P_filtered = P2_filtered(1:L/2+1);
P_filtered(2:end-1) = 2*P_filtered(2:end-1);

figure('Name','FFT After Filtering');

plot(f, P_all{3}, 'Color', [0.8 0.4 0], 'LineWidth', 1);
hold on;
plot(f, P_filtered, 'g', 'LineWidth', 1.5);
yl = ylim;
plot([f_bearing_BPFO f_bearing_BPFO], yl, 'r--', 'LineWidth', 2);
xlim([0 500]);
title('Faulty Motor FFT Before vs After Filtering');
xlabel('Frequency (Hz)');
ylabel('|Amplitude|');
legend('Before Filtering', 'After Filtering', 'BPFO Frequency');
grid on;

saveas(gcf, 'fig5_fft_filtered.png');

%% PART 7: AUTOMATIC FAULT DETECTION
fprintf('\n=== PART 7: Automatic Fault Detection ===\n');

threshold_ratio = 0.20;
status = cell(1,3);

figure('Name','Detection Results');

for m = 1:3
    P = P_all{m};

    [~, idx_rotor] = min(abs(f - f_rotor));
    A_rotor = P(idx_rotor);
    threshold = threshold_ratio * A_rotor;

    [~, idx_bpfo] = min(abs(f - f_bearing_BPFO));
    A_bpfo = P(idx_bpfo);

    fprintf('\nMotor %d\n', m);
    fprintf('Rotor Amplitude = %.4f\n', A_rotor);
    fprintf('BPFO Amplitude = %.4f\n', A_bpfo);
    fprintf('Threshold = %.4f\n', threshold);

    subplot(1,3,m);

    if A_bpfo > threshold
        rectangle('Position', [0.1 0.1 0.8 0.8], 'FaceColor', [0.9 0.2 0.2], 'EdgeColor', 'k', 'LineWidth', 3);
        text(0.5, 0.5, 'FAULTY', 'FontSize', 22, 'FontWeight', 'bold', 'Color', 'white', 'HorizontalAlignment', 'center');
        status{m} = 'FAULTY';
        fprintf('STATUS: FAULTY MOTOR DETECTED\n');
    else
        rectangle('Position', [0.1 0.1 0.8 0.8], 'FaceColor', [0.2 0.8 0.2], 'EdgeColor', 'k', 'LineWidth', 3);
        text(0.5, 0.5, 'HEALTHY', 'FontSize', 22, 'FontWeight', 'bold', 'Color', 'white', 'HorizontalAlignment', 'center');
        status{m} = 'HEALTHY';
        fprintf('STATUS: HEALTHY MOTOR\n');
    end

    axis off;
    title(['Motor ' num2str(m)]);
end

saveas(gcf, 'fig6_detection_results.png');

%% SUMMARY
fprintf('\n=============================================================\n');
fprintf('THREE MOTOR FAULT DETECTION COMPLETE\n');

for m = 1:3
    fprintf('Motor %d : %s\n', m, status{m});
end

fprintf('=============================================================\n');
