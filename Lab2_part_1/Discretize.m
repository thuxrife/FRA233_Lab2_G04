%% --- STM32 DIFFERENCE EQUATION GENERATOR (ALL 3 METHODS) ---
clear; clc;

% Physical Parameters
kt = 50.6e-3; ke = 52.8e-3; R = 3.3133; Lm = 2.8544e-3;
b = 77.851e-6; J = 58.559e-6; Ts = 0.001; 

% Continuous TF: Speed/Voltage
s = tf('s');
G_cont = kt / ((Lm*s + R)*(J*s + b) + kt*ke);

%% 1. TRAPEZOIDAL (TUSTIN)
G_tustin = c2d(G_cont, Ts, 'tustin');
[numT, denT] = tfdata(G_tustin, 'v');
print_stm32_format('Tustin', numT, denT);

%% 2. FORWARD EULER
% Manual substitution to avoid toolbox errors
A_f = (Lm * J) / (Ts^2);
B_f = (Lm*b + R*J)/Ts - 2*(Lm*J)/(Ts^2);
C_f = (Lm*J)/(Ts^2) - (Lm*b + R*J)/Ts + (R*b + kt*ke);
G_fwd = tf(kt, [A_f, B_f, C_f], Ts);
[numF, denF] = tfdata(G_fwd, 'v');
print_stm32_format('Forward Euler', numF, denF);

%% 3. BACKWARD EULER
% Manual substitution
A_b = (Lm*J)/(Ts^2) + (Lm*b + R*J)/Ts + (R*b + kt*ke);
B_b = -2*(Lm*J)/(Ts^2) - (Lm*b + R*J)/Ts;
C_b = (Lm*J)/(Ts^2);
G_bwd = tf([kt*Ts^2, 0, 0], [A_b, B_b, C_b], Ts);
[numB, denB] = tfdata(G_bwd, 'v');
print_stm32_format('Backward Euler', numB, denB);

%% Helper Function to Print Format
function print_stm32_format(methodName, num, den)
    fprintf('// --- STM32 %s Coefficients ---\n', methodName);
    fprintf('const double b1 = %.12f;\n', num(1));
    fprintf('const double b2 = %.12f;\n', num(2));
    fprintf('const double b3 = %.12f;\n', num(3));
    fprintf('const double a2 = %.12f;\n', den(2));
    fprintf('const double a3 = %.12f;\n', den(3));
    fprintf('\n// Implementation:\n');
    fprintf('w_k = (-a2 * w_k1) - (a3 * w_k2) + (b1 * v_k) + (b2 * v_k1) + (b3 * v_k2);\n\n');
end