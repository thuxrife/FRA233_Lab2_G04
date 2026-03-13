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
kd = 0;
ref_angle = 180;
init_angle = 0;
gravity_compensation_mode = 1;
method_pid = 2;

N = 100;

% z2 = (Jm * mp*L^2)* Lm;
% z1 = (mp*L^2 + Jm);
% z0 = (kt * ke);
% 
% p2 = (kt*T^2);
% p1 = (2*kt*T);
% p0 = (kt);
% 
% sampling_time = 1/1000;
% sampling_time_pos = (sampling_time) * 5;
% sampling_time_vel = (sampling_time) * 1;
% 
% a1_DFF = Rm*bm + ke*kt ;
% a2_DFF = Lm*bm + Rm * ((mp*L*L) + Jm) ;
% a3_DFF = Lm * (Jm + (mp*L*L)) ;
% 
% kp_DFF_lower = 0;
% kp_DFF_upper = (a2_DFF*a1_DFF)/(kt*a3_DFF);
% 
% a1 = (Lm*mp*g*L) + (Rm*bm) + (ke*kt);
% a2 = Lm*bm + Rm*((mp*L*L) + Jm);
% a3 = Lm * (Jm + (mp*L*L));
% 
% kp_lower = -(Rm*mp*g*L)/kt;
% kp_upper = ((a2*a1)-a3*(Rm*mp*g*L))/(a3*kt);
% 
% kp_2nd = 1.7161 * (Rm * Jm) / (kt);
% 
% disp(T);
% disp(kp_2nd);
% fprintf("Kp with DFF has lower of $%.2f , and upper of $%.4f\n", kp_DFF_lower, kp_DFF_upper);
% fprintf("Kp with NO DFF has lower of $%.2f , and upper of $%.4f\n", kp_lower, kp_upper);