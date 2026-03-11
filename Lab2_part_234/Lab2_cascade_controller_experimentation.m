% %  FOR MANUAL TASK
% Pendulum Param
L = 0.1;     % [m]  (massless link)
mp = 0.05;   % [kg] (point mass)
g = 9.81;    % [m/s^2]

% DC Motor Param from experiment
kt = 50.6e-3;
ke = 52.8e-3;
Lm = 2.8544e-3;
Rm = 3.3133;
R = Rm;
bm = 77.851e-6;
b = bm;
Jm = 58.559e-6;
J = Jm;
T = Lm/Rm;

kp = 0.071701766537834;
ki = 0;
kd = 0.1111;
N = 100; % Filter and Shit
ref_angle = 180;
init_angle = 0;
gravity_compensation_mode = 1;
method_pid = 2;


z2 = (Jm * mp*L^2)* Lm;
z1 = (mp*L^2 + Jm);
z0 = (kt * ke);

p2 = (kt*T^2);
p1 = (2*kt*T);
p0 = (kt);

sampling_time = 1/1000;
sampling_time_pos = (sampling_time) * 5;
sampling_time_vel = (sampling_time) * 1;
