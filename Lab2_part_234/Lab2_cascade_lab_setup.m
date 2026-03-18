%% --- 1. Setup Environment & Physical Parameters ---
% ... [ส่วน Setup เหมือนเดิมของคุณ] ...
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
p_base.sampling_time = 1/1000;
p_base.sampling_ratio = 5; 
p_base.init_angle = 0;
p_base.gravity_mode = 1;
p_base.master_folder = 'lab2_part4_results';
p_base.stop_time = 8.0; 

% 2. The Cascade Test Matrix
test_matrix = [
    0.00, 0.000, 0.00,  0.090, 0.00, 0.000, 100, 100; 
];
categories = {'AntiWindup_Cascade_Test'};

% 3. Automated Execution Loop
for i = 1:size(test_matrix, 1)
    p = p_base;
    p.Kp_pos = test_matrix(i, 1); p.Ki_pos = test_matrix(i, 2); p.Kd_pos = test_matrix(i, 3);
    p.Kp_vel = test_matrix(i, 4); p.Ki_vel = test_matrix(i, 5); p.Kd_vel = test_matrix(i, 6);
    p.N_pos  = test_matrix(i, 7); p.N_vel  = test_matrix(i, 8);
    
    run_details = sprintf('PosP%.2f_I%.2f_VelP%.2f', p.Kp_pos, p.Ki_pos, p.Kp_vel);
    p.trial_name = fullfile(categories{1}, run_details);
    
    fprintf('\n--- [%d/%d] Executing: %s ---\n', i, size(test_matrix, 1), run_details);
    
    data = Lab2_cascade_simulate_controller(p, 1); 
    
    % --- [ADD] Criteria Checker ---
    check_criteria(data);
    
    show_live_plot(data, run_details);
    pause(1.0);
end

%% --- New Function: Criteria Checker ---
function check_criteria(data)
    if length(data.time) <= 1, fprintf('   [!] No data to check.\n'); return; end
    
    % 1. ดึงค่าจาก Data
    os_v = data.verify.os_vel;
    err_v = data.verify.abs_err_vel;
    os_p = data.verify.os_pos;
    err_p = data.verify.abs_err_pos;
    
    % 2. ประเมินเกณฑ์
    v_os_pass  = os_v <= 2.0;
    v_err_pass = err_v <= 0.02;
    p_os_pass  = os_p <= 2.0;
    p_err_pass = err_p <= 0.004;
    
    % 3. แสดงผลใน Terminal
    fprintf('   [ CRITERIA CHECK RESULTS ]\n');
    fprintf('   ------------------------------------------------------------\n');
    fprintf('   1. Vel Overshoot      : %.2f %% \t(Target <= 2%%)   \t-> %s\n', os_v, get_stat(v_os_pass));
    fprintf('   2. Vel Tracking Err   : %.4f rad/s \t(Target <= 0.02)  \t-> %s\n', err_v, get_stat(v_err_pass));
    fprintf('   3. Pos Overshoot      : %.2f %% \t(Target <= 2%%)   \t-> %s\n', os_p, get_stat(p_os_pass));
    fprintf('   4. Pos Tracking Err   : %.4f rad \t(Target <= 0.004) \t-> %s\n', err_p, get_stat(p_err_pass));
    fprintf('   ------------------------------------------------------------\n');
    
    if v_os_pass && v_err_pass && p_os_pass && p_err_pass
        fprintf('   >>> OVERALL STATUS: [ PASS ] <<<\n');
    else
        fprintf('   >>> OVERALL STATUS: [ FAIL ] <<<\n');
    end
end

function str = get_stat(pass)
    if pass, str = 'PASS'; else, str = 'FAIL'; end
end

%% --- Helper Function: Show Plot on Screen ---
function show_live_plot(data, title_str)
    if length(data.time) <= 1, return; end
    figure('Name', title_str, 'Color', 'w');
    subplot(2,1,1);
    plot(data.time, data.position_loop.position_ref, 'k--', 'LineWidth', 1.2); hold on;
    plot(data.time, data.position_loop.position_measured, 'b', 'LineWidth', 1.2);
    yline(data.position_loop.position_ref(end)+0.004, 'r:'); yline(data.position_loop.position_ref(end)-0.004, 'r:');
    title(['Position Tracking (Max AbsErr: ', num2str(data.verify.abs_err_pos, '%.4f'), ')']);
    grid on; legend('Ref', 'Meas', 'Limit Band');
    
    subplot(2,1,2);
    plot(data.time, data.velocity_loop.velocity_ref, 'k--', 'LineWidth', 1.2); hold on;
    plot(data.time, data.velocity_loop.velocity_measured, 'r', 'LineWidth', 1.2);
    title(['Velocity Tracking (Max AbsErr: ', num2str(data.verify.abs_err_vel, '%.4f'), ')']);
    grid on; legend('Ref', 'Meas');
end

%% --- Core Function: Simulate Controller (ปรับแก้จุดคำนวณ OS) ---
function data = Lab2_cascade_simulate_controller(params, save_flag)
    if nargin < 2, save_flag = 0; end 
    
    vars = fieldnames(params);
    for i = 1:length(vars), assignin('base', vars{i}, params.(vars{i})); end
    assignin('base', 'R', params.Rm);
    assignin('base', 'sampling_time_pos', params.sampling_time * params.sampling_ratio);
    assignin('base', 'sampling_time_vel', params.sampling_time);
    assignin('base', 'gravity_compensation_mode', params.gravity_mode);
    
    try
        sim_out = sim('Lab2_cascade_controller_student', 'StopTime', num2str(params.stop_time));
        vel_mat  = sim_out.velocity_loop.Data;
        pos_mat  = sim_out.position_loop.Data;
        eff_mat  = sim_out.control_effort.Data;
        
        data.time = sim_out.tout;
        data.velocity_loop.velocity_ref = vel_mat(:,1);
        data.velocity_loop.velocity_measured = vel_mat(:,2);
        data.velocity_loop.velocity_error = vel_mat(:,3);
        data.position_loop.position_ref = pos_mat(:,1);
        data.position_loop.position_measured = pos_mat(:,2);
        data.position_loop.position_error = pos_mat(:,3);
        data.control_effort.vin = eff_mat(:,1);
        
        % --- [CRITICAL] การคำนวณเกณฑ์ ---
        % Velocity OS: อ้างอิงจาก Peak Velocity ของ Reference
        ss_vel_ref = max(abs(data.velocity_loop.velocity_ref));
        if ss_vel_ref == 0, ss_vel_ref = 1; end
        s_info_vel = stepinfo(data.velocity_loop.velocity_measured, data.time, ss_vel_ref);
        data.verify.os_vel = s_info_vel.Overshoot;
        
        % Position OS: อ้างอิงจาก Final Position
        s_info_pos = stepinfo(data.position_loop.position_measured, data.time, data.position_loop.position_ref(end));
        data.verify.os_pos = s_info_pos.Overshoot;
        
        % Absolute Tracking Error (คำนวณจากทุกจุดในช่วงเวลาที่พิจารณา)
        % พิจารณาตั้งแต่ 0.5 วินาทีเป็นต้นไป เพื่อข้ามช่วงเริ่มต้นที่ Error สูงตามธรรมชาติ
        idx_eval = find(data.time > 0.5);
        data.verify.abs_err_vel = max(abs(data.velocity_loop.velocity_error(idx_eval)));
        data.verify.abs_err_pos = max(abs(data.position_loop.position_error(idx_eval)));
        
        % --- Save Logic เหมือนเดิม ---
        if save_flag == 1
             trial_root = fullfile(params.master_folder, params.trial_name);
             if ~exist(trial_root, 'dir'), mkdir(trial_root); end
             T = table(data.time, data.position_loop.position_ref, data.position_loop.position_measured, ...
                       data.velocity_loop.velocity_ref, data.velocity_loop.velocity_measured, ...
                       'VariableNames', {'Time', 'Pos_Ref', 'Pos_Meas', 'Vel_Ref', 'Vel_Meas'});
             writetable(T, fullfile(trial_root, 'sim_results.xlsx'));
        end
    catch ME
        data.time = [0]; data.verify.os_vel = 999; data.verify.os_pos = 999;
        data.verify.abs_err_vel = 999; data.verify.abs_err_pos = 999;
    end
end