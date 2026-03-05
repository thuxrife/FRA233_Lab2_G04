% %  FOR MANUAL TASK
% Pendulum Param
L = 0.1;     % [m]  (massless link)
mp = 0.05;   % [kg] (point mass)
g = 9.81;    % [m/s^2]

% DC Motor Param from experiment
kt = 50.6e-3;
ke = 52.8e-3;
Lm = 2.8544e-3;
R = 3.3133;
b = 77.851e-6;
J = 58.559e-6;
T = 0.0002;

% PID Terms
% kp = 0.00110; % รอด
% kp = 1.7161 * ((R*J)/kt); % เชี่ยไรวะ ไม่รอด
kp = 0.000;
ki = 0.000;
kd = 0.000;

ref_angle = 180;

% 0 No, 1 Yes
gravity_compensation_mode = 1;

% 1 = Gain Block (Manually PID)
% 2 = Use PID(S) Block
% 3 = Use PID(Z) Block
% 4 - 9 = Might be another case (such as Anti Windup vs No Anti Windup)
% Also placement of Saturation Block
method_pid = 1;