%% --- LAB 2: AUTOMATION SCRIPT (DEGREE VERSION) ---
clear; clc;
MASTER_FOLDER = 'lab2_part2_results'; 
if ~exist(MASTER_FOLDER, 'dir'), mkdir(MASTER_FOLDER); end

% --- CONFIGURATION TABLE ---
% รูปแบบ: [Kp, Ki, Kd, N, GravityMode]
tuning_configs = [
    % 0.06, 0.0, 0.0, 100, 0;
    0.633530931368352, 0.000, 0.00, 1000, 1;
];


angles_to_test = 30:30:360; 

model_name = 'Lab2_single_loop_controller_student';
load_system(model_name); 

for row = 1:size(tuning_configs, 1)
    kp_val  = tuning_configs(row, 1);
    ki_val  = tuning_configs(row, 2);
    kd_val  = tuning_configs(row, 3);
    n_val   = tuning_configs(row, 4);
    grav_val = tuning_configs(row, 5);
    
    grav_str = 'NoGrav'; if grav_val == 1, grav_str = 'WithGrav'; end
    if ki_val == 0 && kd_val == 0
        trial_name = sprintf('P_tuning_Kp_%.4f_%s', kp_val, grav_str);
    else
        trial_name = sprintf('PID_Kp_%.2f_Ki_%.2f_Kd_%.2f_N_%.0f_%s', ...
                             kp_val, ki_val, kd_val, n_val, grav_str);
    end
    
    for target_deg = angles_to_test
        % --- 1. ส่งตัวแปรไป Base Workspace (หน่วย Degree) ---
        assignin('base', 'kp', kp_val);
        assignin('base', 'ki', ki_val);
        assignin('base', 'kd', kd_val);
        assignin('base', 'N', n_val);
        assignin('base', 'gravity_mode', grav_val); 
        
        % --- 2. เตรียมชุด Params สำหรับฟังก์ชัน Simulate & Save ---
        params.kp = kp_val; 
        params.ki = ki_val; 
        params.kd = kd_val;
        params.N  = n_val; 
        params.gravity_mode = grav_val;
        
        params.init = 0; 
        params.method = 1; 
        params.stop_time = 20.0;
        params.master_folder = MASTER_FOLDER;
        params.trial_name = trial_name;
        
        % --- จุดที่แก้ไข: ไม่ต้องใช้ deg2rad แล้ว ส่ง target_deg ไปตรงๆ ---
        params.ref_time = [0; 0.1; 5.0];
        params.ref_data = [0; target_deg; target_deg]; % <--- เป็น Degree แล้ว
        params.moter    = [1; 1; 1];
        
        fprintf('Simulating %s at %d deg...\n', trial_name, target_deg);
        
        % เรียกใช้ฟังก์ชันเดิมของคุณ
        Lab2_manual_simulate_controller(params); 
    end
end