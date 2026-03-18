%% --- LAB 2: AUTOMATION SCRIPT (DEGREE VERSION - STEP INPUT) ---
clear; clc;
MASTER_FOLDER = 'lab2_part2_results'; 
if ~exist(MASTER_FOLDER, 'dir'), mkdir(MASTER_FOLDER); end

% --- CONFIGURATION TABLE ---
% รูปแบบ: [Kp, Ki, Kd, N, GravityMode]
tuning_configs = [
    % 0.066353093136835, 0.00, 0.00, 1000,1;
    % 0.066353093136835, 0.000, 0.00, 1000, 1;
    0.1,0,0,0,1;
    0.02,0,0,0,1;
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
        % --- 1. ส่งตัวแปรไป Base Workspace ---
        assignin('base', 'kp', kp_val);
        assignin('base', 'ki', ki_val);
        assignin('base', 'kd', kd_val);
        assignin('base', 'N', n_val);
        assignin('base', 'gravity_mode', grav_val); 
        
        % --- 2. เตรียมชุด Params สำหรับการ Simulate ---
        params.kp = kp_val; 
        params.ki = ki_val; 
        params.kd = kd_val;
        params.N  = n_val; 
        params.gravity_mode = grav_val;
        
        params.init = 0; 
        params.method = 5; 
        params.stop_time = 20.0; % เวลาสิ้นสุดการรัน Simulation
        params.master_folder = MASTER_FOLDER;
        params.trial_name = trial_name;
        
        % --- แก้ไขจุดนี้: ปรับเป็น Unit Step ให้เริ่มที่วินาทีที่ 1 ---
        % ใช้เวลา 1.0 และ 1.0001 เพื่อให้ค่ากระโดดขึ้นทันที
        % และใช้ 20.0 (เท่ากับ stop_time) เพื่อให้ค่าค้างไว้จนจบการรัน
        params.ref_time = [0; 0.00000001; params.stop_time];
        params.ref_data = [target_deg; target_deg; target_deg]; 
        params.moter    = [1; 1; 1];
        
        fprintf('Simulating %s at %d deg (Step at 1s)...\n', trial_name, target_deg);
        
        % เรียกใช้ฟังก์ชัน Simulate
        Lab2_manual_simulate_controller(params); 
    end
end