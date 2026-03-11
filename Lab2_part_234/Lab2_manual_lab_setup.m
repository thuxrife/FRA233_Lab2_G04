%% --- PID Pole-Zero Plot with Auto-Zoom ---
clear; clc;

% Define your controller parameters
Kp = 1.0; Ki = 0.5; Kd = 0.05; N = 100; Ts = 0.001; 
s = tf('s');
C_cont = Kp + Ki/s + (Kd*N*s)/(s+N); 
C_disc = c2d(C_cont, Ts, 'tustin'); % Discretize

figure('Color', 'w', 'Position', [100, 100, 1100, 500]);

% --- S-Plane Subplot ---
subplot(1,2,1);
pzplot(C_cont); grid on;
title('S-Plane (Continuous)');

% Corrected extraction
p_cont = pole(C_cont); 
z_cont = zero(C_cont);

% Auto-Zoom: Focus on the action in the Left Half Plane
xlim([min(real([p_cont; z_cont])) - 10, 5]); 
ylim([-20, 20]);

% --- Z-Plane Subplot ---
subplot(1,2,2);
pzplot(C_disc); grid on; hold on;
zgrid; % Added Damping/Frequency grid for Analysis
title('Z-Plane (Discrete)');

% Auto-Zoom: Focus on the Unit Circle near z=1
% This is where the Integrator and low-frequency zeros live
xlim([0.8, 1.05]); 
ylim([-0.15, 0.15]);