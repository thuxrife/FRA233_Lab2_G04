%% Lab 2: Response Reconstruction from Poles Only
clear; clc; close all;

% Define the 4 Cases using only the Poles (DNA) from your analysis
% Case 1: Unstable (Real pole in RHP)
% Case 2: Oscillatory (Large Imaginary parts)
% Case 3: Integrator (One pole at 0)
% Case 4: Balanced (Poles in LHP)
case_poles = { ...
    [-1146.8, -37.8, 22.5], ...    % 1. No P + No DFF
    [-1153.7, -4.2+83.7j, -4.2-83.7j], ... % 2. P + No DFF
    [0, -1146.8, -15.3], ...       % 3. No P + DFF
    [-1146.8, -15.1, -0.2] ...     % 4. P + DFF
};

titles = {'1. No P + No DFF', '2. P + No DFF', '3. No P + DFF', '4. P + DFF'};
t = linspace(0, 2, 1000); % Time vector for 2 seconds

for i = 1:4
    figure('Color', 'w', 'Position', [100, 100, 1100, 500]);
    current_poles = case_poles{i};
    
    % --- LEFT: S-Plane Verification ---
    subplot(1,2,1); hold on;
    % Symmetric Log-like transform for visibility
    plot_real = sign(real(current_poles)) .* log10(1 + abs(real(current_poles)));
    
    fill([-4 0 0 -4], [-1000 -1000 1000 1000], [0.8 1 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.1); 
    fill([0 4 4 0], [-1000 -1000 1000 1000], [1 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.1);
    
    plot(plot_real, imag(current_poles), 'bx', 'LineWidth', 2, 'MarkerSize', 12);
    xline(0, 'k-'); yline(0, 'k-'); grid on; axis([-4 2 -100 100]);
    title(titles{i}); xlabel('Real (Log-Spaced)'); ylabel('Imag (j\omega)');

    % --- RIGHT: Natural Response from Poles ---
    subplot(1,2,2);
    % Construct the transfer function with Gain=1 and no zeros
    sys_recon = zpk([], current_poles, 1);
    
    if any(real(current_poles) > 0)
        impulse(sys_recon, 0.5); title('Unstable Natural Trend');
    elseif any(real(current_poles) == 0)
        step(sys_recon, 2); title('Integrator Ramp Response');
    else
        step(sys_recon, 2); title('Controlled Natural Response');
    end
    grid on;
end