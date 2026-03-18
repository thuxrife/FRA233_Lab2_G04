%% --- LAB 2: CASCADE AUTOMATED EXECUTION SETUP ---

% 1. Pendulum & DC Motor Parameters (Input ตามที่คุณกำหนด)
p_base.L = 0.1;      % [m]
p_base.mp = 0.05;    % [kg]
p_base.g = 9.81;     % [m/s^2]

% DC Motor Param from experiment
p_base.kt = 50.6e-3;
p_base.ke = 52.8e-3;
p_base.Lm = 2.8544e-3;
p_base.Rm = 3.3133;
p_base.bm = 77.851e-6;
p_base.b = p_base.bm;
p_base.Jm = 58.559e-6;
p_base.J = p_base.Jm;
p_base.T = p_base.Lm/p_base.Rm;

% Intermediate Calculation (z & p parameters)
p_base.z2 = (p_base.Jm * p_base.mp * p_base.L^2) * p_base.Lm;
p_base.z1 = (p_base.mp * p_base.L^2 + p_base.Jm);
p_base.z0 = (p_base.kt * p_base.ke);
p_base.p2 = (p_base.kt * p_base.T^2);
p_base.p1 = (2 * p_base.kt * p_base.T);
p_base.p0 = (p_base.kt);

% Sampling Configuration
p_base.sampling_time = 1/1000;
p_base.sampling_ratio = 5/1; % กำหนดเป็น Ratio ตามที่คุณต้องการ

% Simulation Setup
p_base.init_angle = 0;
p_base.gravity_mode = 1;
p_base.master_folder = 'lab2_part4_results';
p_base.stop_time = 10.0; % กำหนดเวลาหยุดรันคงที่

% 2. The Cascade Test Matrix
% Columns: [Kp_pos, Ki_pos, Kd_pos, Kp_vel, Ki_vel, Kd_vel, N_pos, N_vel]
test_matrix = [
    0.50, 0.010, 0.00,  0.1, 0.01, 0, 100, 100; % ตัวอย่างเคสที่ 1
];

% Category Labels
categories = {'AntiWindup_Cascade_Test'};

% 3. Automated Execution Loop
for i = 1:size(test_matrix, 1)
    p = p_base;
    
    % Extract Controller Parameters (Outer Loop)
    p.Kp_pos = test_matrix(i, 1);
    p.Ki_pos = test_matrix(i, 2);
    p.Kd_pos = test_matrix(i, 3);
    
    % Extract Controller Parameters (Inner Loop)
    p.Kp_vel = test_matrix(i, 4);
    p.Ki_vel = test_matrix(i, 5);
    p.Kd_vel = test_matrix(i, 6);
    
    % Filter Coefficients
    p.N_pos  = test_matrix(i, 7);
    p.N_vel  = test_matrix(i, 8);
    
    % Dynamic Folder Naming
    current_cat = categories{min(i, length(categories))};
    run_details = sprintf('PosP%.2f_I%.2f_VelP%.2f', p.Kp_pos, p.Ki_pos, p.Kp_vel);
    
    p.trial_name = fullfile(current_cat, run_details);
    
    fprintf('--- [%d/%d] Executing Cascade Simulation: %s ---\n', i, size(test_matrix, 1), run_details);
    
    % เรียกใช้ฟังก์ชันเดิม (ซึ่งคุณปรับปรุงให้รับ Output 4 กลุ่มแล้ว)
   Lab2_cascade_simulate_controller(p)
    
    pause(1.1);
end