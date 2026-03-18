%% --- 1. Setup Environment & Physical Parameters ---
clear; clc; close all;
p_base.L = 0.1; p_base.mp = 0.05; p_base.g = 9.81;
p_base.kt = 50.6e-3; p_base.ke = 52.8e-3;
p_base.Lm = 2.8544e-3; p_base.Rm = 3.3133;
p_base.bm = 77.851e-6; p_base.b = p_base.bm;
p_base.Jm = 58.559e-6; p_base.J = p_base.Jm;
p_base.T = p_base.Lm/p_base.Rm;
p_base.z2 = (p_base.Jm * p_base.mp * p_base.L^2) * p_base.Lm;
p_base.z1 = (p_base.mp * p_base.L^2 + p_base.Jm);
p_base.z0 = (p_base.kt * p_base.ke);
p_base.p2 = (p_base.kt * p_base.T^2);
p_base.p1 = (2 * p_base.kt * p_base.T);
p_base.p0 = (p_base.kt);
p_base.sampling_time = 1/1000; p_base.sampling_ratio = 5;
p_base.init_angle = 0; p_base.gravity_mode = 1;
p_base.master_folder = 'lab2_optimization_results';
p_base.stop_time = 15.0; 

% Initial Gains (PID)
p_base.Kp_pos = 0.06; p_base.Ki_pos = 0.01; p_base.Kd_pos = 0.001; p_base.N_pos = 100;
p_base.Kp_vel = 0.10; p_base.Ki_vel = 0.01; p_base.Kd_vel = 0.001; p_base.N_vel = 100;

%% --- 2. Adaptive Balanced PID Tuning ---
params = p_base;
max_iter = 60;
found = false;
gamma_base = 0.4; 
stop_threshold = 1e-4; 
fprintf('>>> Starting Anti-Oscillation Tuning (Damping Focus)...\n');

for iter = 1:max_iter
    kp_v_old = params.Kp_vel; 
    res = Lab2_cascade_simulate_controller(params, 0);
    
    cur_os_v  = res.verify.os_vel;   cur_err_v = res.verify.abs_err_vel;
    cur_os_p  = res.verify.os_pos;   cur_err_p = res.verify.abs_err_pos;
    
    status_v = 'FAIL'; if cur_os_v <= 2.0 && cur_err_v <= 0.02, status_v = 'PASS'; end
    status_p = 'FAIL'; if cur_os_p <= 2.0 && cur_err_p <= 0.004, status_p = 'PASS'; end
    
    fprintf('\n[Iter %d Results] ----------------------------------\n', iter);
    fprintf('Vel: %s [O.P.: %.2f%%, AbsErr: %.4f]\n', status_v, cur_os_v, cur_err_v);
    fprintf('Pos: %s [O.P.: %.2f%%, AbsErr: %.4f]\n', status_p, cur_os_p, cur_err_p);

    % --- Smart Divergence Guard (ข้ามเคส Inf Velocity) ---
    if isnan(cur_os_v) || isnan(cur_os_p) || cur_os_p > 1000
        fprintf('   [!] Divergence Detected: Scaling down Kp...\n');
        params.Kp_vel = max(0.05, params.Kp_vel * 0.7); 
        params.Kp_pos = max(0.05, params.Kp_pos * 0.7);
        continue; 
    end
    
    if strcmp(status_v, 'PASS') && strcmp(status_p, 'PASS'), found = true; break; end

    %% --- 3. Balanced Update Law (เน้นลด Oscillation) ---
    if strcmp(status_v, 'FAIL')
        % --- จูน Velocity (วงใน) ---
        e_os_v = cur_os_v - 2.0;
        e_tr_v = cur_err_v - 0.02;
        
        if e_os_v > 0
            % เพิ่ม Kd (เบรก) และลด Kp เปอร์เซ็นต์คงที่
            params.Kd_vel = params.Kd_vel + 0.01 * (e_os_v/5); 
            params.Kp_vel = params.Kp_vel * 0.9; 
        elseif e_tr_v > 0
            params.Kp_vel = params.Kp_vel * (1 + 0.1 * (e_tr_v/0.02)); 
        end
        if e_tr_v > 0.005, params.Ki_vel = min(params.Ki_vel + 0.002, 5.0); end
    else
        % --- จูน Position (วงนอก) ---
        e_os_p = cur_os_p - 2.0;
        e_tr_p = cur_err_p - 0.004;

        if e_os_p > 0
            % ดึงเบรก Kd_pos และลดความดุ Kp_pos
            params.Kd_pos = params.Kd_pos + 0.015 * (e_os_p/5); 
            params.Kp_pos = params.Kp_pos * 0.85; 
        elseif e_tr_p > 0
            params.Kp_pos = params.Kp_pos * (1 + 0.05 * (e_tr_p/0.004)); 
        end
        if e_tr_p > 0.001, params.Ki_pos = min(params.Ki_pos + 0.001, 1.5); end
    end

    %% --- 4. Strict Safety Guard & Next PID Print ---
    % จำกัดขอบเขตเข้มงวดเพื่อหยุดการสั่น
    params.Kp_vel = max(0.05, min(params.Kp_vel, 10.0));
    params.Ki_vel = max(0.01, min(params.Ki_vel, 4.0));
    params.Kd_vel = max(0.00, min(params.Kd_vel, 10.0));
    
    params.Kp_pos = max(0.05, min(params.Kp_pos, 10.0));
    params.Ki_pos = max(0.01, min(params.Ki_pos, 4.0));
    params.Kd_pos = max(0.00, min(params.Kd_pos, 10.0));

    fprintf('   Next Vel PID = [%.4f, %.4f, %.4f]\n', params.Kp_vel, params.Ki_vel, params.Kd_vel);
    fprintf('   Next Pos PID = [%.4f, %.4f, %.4f]\n', params.Kp_pos, params.Ki_pos, params.Kd_pos);

    if abs(params.Kp_vel - kp_v_old) < stop_threshold && iter > 25, break; end
end % end of for loop

%% --- 5. Final Result ---
if found
    fprintf('\n*** OPTIMIZATION SUCCESS! ***\n');
    params.trial_name = 'AntiOscillation_PID_Final';
    Lab2_cascade_simulate_controller(params, 1);
end