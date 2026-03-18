%% --- 1. เตรียมสภาพแวดล้อม (Physical Parameters) ---
clear; clc;
% (ใช้ค่า Physical Parameters เดิมของคุณ)
p_base.L = 0.1; p_base.mp = 0.05; p_base.g = 9.81;
p_base.kt = 50.6e-3; p_base.ke = 52.8e-3;
p_base.Lm = 2.8544e-3; p_base.Rm = 3.3133;
p_base.bm = 77.851e-6; p_base.b = p_base.bm;
p_base.Jm = 58.559e-6; p_base.J = p_base.Jm;
p_base.T = p_base.Lm/p_base.Rm;

% Intermediate Calculation
p_base.z2 = (p_base.Jm * p_base.mp * p_base.L^2) * p_base.Lm;
p_base.z1 = (p_base.mp * p_base.L^2 + p_base.Jm);
p_base.z0 = (p_base.kt * p_base.ke);
p_base.p2 = (p_base.kt * p_base.T^2);
p_base.p1 = (2 * p_base.kt * p_base.T);
p_base.p0 = (p_base.kt);

% Sampling & Simulation Config
p_base.sampling_time = 1/1000;
p_base.sampling_ratio = 5/1; 
p_base.init_angle = 0;
p_base.gravity_mode = 1;
p_base.master_folder = 'lab2_optimization_results';
p_base.stop_time = 10.0;
p_base.N_pos = 100; p_base.N_vel = 100;

%% --- 2. เริ่มการปรับ Gain อัตโนมัติ (Heuristic Search - Velocity & Position) ---
params = p_base;

% --- ตั้งค่าเริ่มต้น (Initial Guess) ---
params.Kp_pos = 2.0;  params.Ki_pos = 0.05; params.Kd_pos = 0.01;
params.Kp_vel = 0.2;  params.Ki_vel = 0.01; params.Kd_vel = 0.001;

max_iterations = 60; 
lr = 0.1; % Learning Rate
found = false;

fprintf('>>> Starting Adaptive Optimization for Dual Loop (Velocity & Position)...\n');

for iter = 1:max_iterations
    % 1. รัน Simulation (Flag 0 = No Save)
    res = Lab2_cascade_simulate_controller(params, 0); 
    
    % 2. ตรวจสอบเงื่อนไข 4 ข้อ
    cond_os_v  = res.verify.os_vel <= 2;
    cond_err_v = res.verify.abs_err_vel <= 0.02;
    cond_os_p  = res.verify.os_pos <= 2;
    cond_err_p = res.verify.abs_err_pos <= 0.004;
    
    % แสดงสถานะปัจจุบันแบบละเอียด
    fprintf('Iter %d | Vel: [OS:%.2f%%, Err:%.4f] | Pos: [OS:%.2f%%, Err:%.4f]\n', ...
        iter, res.verify.os_vel, res.verify.abs_err_vel, res.verify.os_pos, res.verify.abs_err_pos);

    % เช็คว่าผ่านครบทุกข้อหรือยัง
    if cond_os_v && cond_err_v && cond_os_p && cond_err_p
        found = true;
        break;
    end

    % --- Logic การปรับค่าแบบ Adaptive (Priority: Velocity Loop First) ---
    
    % ส่วนที่ 1: จัดการ Velocity Loop (Inner Loop)
    if ~cond_os_v || ~cond_err_v
        if res.verify.os_vel > 2
            params.Kp_vel = params.Kp_vel * (1 - lr);
            params.Kd_vel = params.Kd_vel * (1 - lr);
        elseif res.verify.abs_err_vel > 0.02
            params.Kp_vel = params.Kp_vel * (1 + lr);
            params.Ki_vel = params.Ki_vel + 0.002;
        end
    end

    % ส่วนที่ 2: จัดการ Position Loop (Outer Loop)
    if ~cond_os_p || ~cond_err_p
        if res.verify.os_pos > 2
            params.Kp_pos = params.Kp_pos * (1 - lr);
            params.Kd_pos = params.Kd_pos * (1 - lr);
        elseif res.verify.abs_err_pos > 0.004
            params.Kp_pos = params.Kp_pos * (1 + lr);
            params.Ki_pos = params.Ki_pos + 0.005;
        end
    end
    
    % ป้องกันค่าติดลบ หรือเป็น 0
    params.Kp_pos = max(0.01, params.Kp_pos); params.Ki_pos = max(0, params.Ki_pos); params.Kd_pos = max(0, params.Kd_pos);
    params.Kp_vel = max(0.01, params.Kp_vel); params.Ki_vel = max(0, params.Ki_vel); params.Kd_vel = max(0, params.Kd_vel);
end

%% --- 3. บันทึกผลลัพธ์สุดท้าย ---
if found
    fprintf('\nBingo! Found Valid Gains for both loops at iteration %d\n', iter);
    fprintf('Final Gains: \n  Pos: [P:%.2f, I:%.3f, D:%.3f]\n  Vel: [P:%.2f, I:%.3f, D:%.3f]\n', ...
        params.Kp_pos, params.Ki_pos, params.Kd_pos, params.Kp_vel, params.Ki_vel, params.Kd_vel);
    
    params.trial_name = 'Optimized_DualLoop_Adaptive';
    Lab2_cascade_simulate_controller(params, 1); 
    disp('Optimization Complete. Data and Plots saved.');
else
    disp('--------------------------------------------------');
    disp('Search Finished: No valid gains found within max iterations.');
end