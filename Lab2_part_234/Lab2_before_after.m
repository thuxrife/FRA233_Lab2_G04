%% Lab 2: S-Plane Comparison - Column Aligned & P1 Imaginary
clear; clc; close all;

% --- 1. System Parameters ---
L = 0.1; mp = 0.05; g = 9.81;
kt = 50.6e-3; ke = 52.8e-3; Lm = 2.8544e-3;
R = 3.3133; b = 77.851e-6; J = 58.559e-6;
Kp = 30; Kp_com = 0.01; 

% --- 2. Define Denominators ---
d1 = [Lm*J, (R*J + Lm*b), (R*b + kt*ke - Lm*mp*g*L), -R*mp*g*L]; % 1. No P + No DFF
d2 = [Lm*J, (R*J + Lm*b), (R*b + kt*ke - Lm*mp*g*L), (kt*Kp - R*mp*g*L)]; % 2. P + No DFF
d3 = [Lm*J, (R*J + Lm*b), (R*b + kt*ke), 0]; % 3. No P + DFF
d4 = [Lm*J, (R*J + Lm*b), (R*b + kt*ke), (kt*Kp_com)]; % 4. P + DFF

% --- 3. Visualization ---
figure('Color', 'w', 'Position', [100 100 1100 900]);
titles = {'1. No P + No DFF', '2. P + No DFF', '3. No P + DFF', '4. P + DFF'};
dens = {d1, d2, d3, d4};

for i = 1:4
    subplot(2,2,i); hold on;
    p = pole(tf(1, dens{i})); 
    
    % Transform for Non-Equal Spacing (Symmetric Log Effect)
    plot_real = sign(real(p)) .* log10(1 + abs(real(p)));
    
    % Color Zones: Green (Stable), Red (Unstable)
    fill([-4 0 0 -4], [-400 -400 400 400], [0.8 1 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.2); 
    fill([0 4 4 0], [-400 -400 400 400], [1 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.2);
    
    % Plot Poles
    plot(plot_real, imag(p), 'bx', 'LineWidth', 2, 'MarkerSize', 12);
    
    % Manual Ticks for Non-Equal Spacing
    tick_vals = [-1160, -100, -30, -10, 0, 10, 30, 100];
    set(gca, 'XTick', sign(tick_vals).*log10(1+abs(tick_vals)), 'XTickLabel', tick_vals);
    
    % Formatting
    xline(0, 'k-', 'LineWidth', 1.5); yline(0, 'k-');
    grid on; axis([-3.5 2.5 -100 100]);
    xlabel('Real (\sigma)'); ylabel('Imag (j\omega)');
    
    % ALIGNED COLUMN FORMATTING
    % %8.1f ensures the number takes 8 spaces, aligning decimal points
    % %+7.1fj ensures the imaginary part always has a sign (+/-) and aligns
    p1_s = sprintf('P1: %8.1f %+7.1fj', real(p(1)), imag(p(1)));
    p2_s = sprintf('P2: %8.1f %+7.1fj', real(p(2)), imag(p(2)));
    p3_s = sprintf('P3: %8.1f %+7.1fj', real(p(3)), imag(p(3)));
    
    t_obj = title({titles{i}, p1_s, p2_s, p3_s}, 'FontSize', 10, 'FontWeight', 'bold');
    set(t_obj, 'FontName', 'Courier New'); % Monospaced font for perfect alignment
end