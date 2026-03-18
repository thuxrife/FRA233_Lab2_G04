%% --- FIXED STM32 DIFFERENCE EQUATION GENERATOR ---
clear; clc;
% Physical Parameters
kt = 50.0e-3; ke = 50.10e-3; R = 3.3999; Lm = 2.8530e-3;
b = 0.6590e-6; J = 11.700e-6; Ts = 0.001; 

% Continuous Coefficients: G(s) = kt / (As^2 + Bs + C)
A = Lm * J;
B = Lm*b + R*J;
C = R*b + kt*ke;

%% 1. TUSTIN (Standard c2d)
G_cont = tf(kt, [A, B, C]);
G_tustin = c2d(G_cont, Ts, 'tustin');
[numT, denT] = tfdata(G_tustin, 'v');
print_stm32_format('Tustin', numT, denT);

%% 2. FORWARD EULER: s = (z-1)/Ts
% แทนค่า s ใน G(s) จะได้ num = [0, 0, kt*Ts^2], den = [A, (B*Ts - 2*A), (A - B*Ts + C*Ts^2)]
denF = [A, (B*Ts - 2*A), (A - B*Ts + C*Ts^2)];
numF = [0, 0, kt*Ts^2]; 
% ปรับให้ den(1) = 1
numF = numF / denF(1); denF = denF / denF(1);
print_stm32_format('Forward Euler', numF, denF);

%% 3. BACKWARD EULER: s = (z-1)/(z*Ts)
% แทนค่า s ใน G(s) จะได้ num = [kt*Ts^2, 0, 0], den = [(A + B*Ts + C*Ts^2), (-2*A - B*Ts), A]
denB = [(A + B*Ts + C*Ts^2), (-2*A - B*Ts), A];
numB = [kt*Ts^2, 0, 0];
% ปรับให้ den(1) = 1
numB = numB / denB(1); denB = denB / denB(1);
print_stm32_format('Backward Euler', numB, denB);

function print_stm32_format(methodName, num, den)
    fprintf('// --- STM32 %s Coefficients ---\n', methodName);
    fprintf('const double b0 = %.12f; // z^0\n', num(1));
    fprintf('const double b1 = %.12f; // z^-1\n', num(2));
    fprintf('const double b2 = %.12f; // z^-2\n', num(3));
    fprintf('const double a1 = %.12f; // z^-1\n', den(2));
    fprintf('const double a2 = %.12f; // z^-2\n', den(3));
    fprintf('// w[k] = -a1*w[k-1] - a2*w[k-2] + b0*v[k] + b1*v[k-1] + b2*v[k-2]\n\n');
end