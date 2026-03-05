% Define System Parameters
L = 0.1; mp = 0.05; g = 9.81;
kt = 50.6e-3; ke = 52.8e-3; Lm = 2.8544e-3;
R = 3.3133; b = 77.851e-6; J = 58.559e-6;

% Define the Unstable Plant
num = [kt];
den = [Lm*J, (R*J + Lm*b), (R*b + kt*ke - Lm*mp*g*L), -R*mp*g*L];
sys = tf(num, den);
p = pole(sys); % This will calculate all 3 poles

% Create the S-Plane Graph
figure('Color', 'w'); hold on;

% Color the Zones (Expanded to cover the fast pole)
fill([-1500 0 0 -1500], [-100 -100 100 100], [0.8 1 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.3); % Green
fill([0 200 200 0], [-100 -100 100 100], [1 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.3); % Red

% Plot the Poles
plot(real(p), imag(p), 'rx', 'LineWidth', 2, 'MarkerSize', 10);

% Label each pole with its value for clarity
for i = 1:length(p)
    text(real(p(i)), imag(p(i))+2, sprintf('%.1f', real(p(i))), 'HorizontalAlignment', 'center');
end

% Formatting
xline(0, 'k-', 'LineWidth', 2); 
grid on;
xlabel('Real Axis (\sigma)');
ylabel('Imaginary Axis (j\omega)');
title('S-Plane: All 3 Poles (Electrical & Mechanical)');
axis([-1300 100 -20 20]); % Expanded X-axis to see the pole at -1160
legend('Stable Zone', 'Unstable Zone', 'Poles (X)');