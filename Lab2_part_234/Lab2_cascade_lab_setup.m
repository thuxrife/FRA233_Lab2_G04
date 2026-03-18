%% --- 1. Setup Environment & Physical Parameters ---
clear; clc; close all;

% Physical Parameters (Input ตามที่คุณกำหนด)
p_base.L = 0.1; p_base.mp = 0.05; p_base.g = 9.81;
p_base.kt = 50.6e-3; p_base.ke = 52.8e-3;
p_base.Lm = 2.8544e-3; p_base.Rm = 3.3133;
p_base.bm = 77.851e-6; p_base.b = p_base.bm;
p_base.Jm = 58.559e-6; p_base.J = p_base.Jm;
p_base.T = p_base.Lm/p_base.Rm;

% Intermediate Calculation (z & p parameters)
p_base.z2 = (p_base.Jm * p_base.mp * p_base.L^2) * p_base.Lm;
p_base.z1 = (p_base.mp * p_base.L^2 + p_base.Jm);
p_base.z0 = (p_base.kt * p_base.ke);
p_base.p2 = (p_base.kt * p_base.T^2);
p_base.p1 = (2 * p_base.kt * p_base.T);
p_base.p0 = (p_base.kt);

% Simulation Configuration
p_base.sampling_time = 1/1000;
p_base.sampling_ratio = 5; 
p_base.init_angle = 0;
p_base.gravity_mode = 1;
p_base.master_folder = 'lab2_part4_results';
p_base.stop_time = 8.0; 

% 2. The Cascade Test Matrix (ใส่ค่าที่คุณจูนได้ล่าสุดที่นี่)
% Columns: [Kp_pos, Ki_pos, Kd_pos, Kp_vel, Ki_vel, Kd_vel, N_pos, N_vel]
test_matrix = [
    0.50, 0.010, 0.01,  0.081, 0.012, 0.005, 100, 100; % เคสที่ 1
];

categories = {'AntiWindup_Cascade_Test'};

% 3. Automated Execution Loop
for i = 1:size(test_matrix, 1)
    p = p_base;
    p.Kp_pos = test_matrix(i, 1); p.Ki_pos = test_matrix(i, 2); p.Kd_pos = test_matrix(i, 3);
    p.Kp_vel = test_matrix(i, 4); p.Ki_vel = test_matrix(i, 5); p.Kd_vel = test_matrix(i, 6);
    p.N_pos  = test_matrix(i, 7); p.N_vel  = test_matrix(i, 8);
    
    current_cat = categories{min(i, length(categories))};
    run_details = sprintf('PosP%.2f_I%.2f_VelP%.2f', p.Kp_pos, p.Ki_pos, p.Kp_vel);
    p.trial_name = fullfile(current_cat, run_details);
    
    fprintf('--- [%d/%d] Executing: %s ---\n', i, size(test_matrix, 1), run_details);
    
    % *** สำคัญ: ใส่เลข 1 เพื่อให้เซฟภาพ และรับค่า data เพื่อมาโชว์บนจอ ***
    data = Lab2_cascade_simulate_controller(p, 1); 
    
    % สั่งให้โชว์กราฟบนหน้าจอทันที
    show_live_plot(data, run_details);
    
    pause(1.0);
end

%% --- Helper Function: Show Plot on Screen ---
function show_live_plot(data, title_str)
    if length(data.time) <= 1, return; end
    figure('Name', title_str, 'Color', 'w');
    subplot(2,1,1);
    plot(data.time, data.position_loop.position_ref, 'k--', 'LineWidth', 1.2); hold on;
    plot(data.time, data.position_loop.position_measured, 'b', 'LineWidth', 1.2);
    title(['Position Tracking (AbsErr: ', num2str(data.verify.abs_err_pos, '%.4f'), ')']);
    grid on; legend('Ref', 'Meas');
    
    subplot(2,1,2);
    plot(data.time, data.velocity_loop.velocity_ref, 'k--', 'LineWidth', 1.2); hold on;
    plot(data.time, data.velocity_loop.velocity_measured, 'r', 'LineWidth', 1.2);
    title(['Velocity Tracking (AbsErr: ', num2str(data.verify.abs_err_vel, '%.4f'), ')']);
    grid on; legend('Ref', 'Meas');
end

%% --- Core Function: Simulate Controller ---
function data = Lab2_cascade_simulate_controller(params, save_flag)
    if nargin < 2, save_flag = 0; end 
    
    % Map Parameters to Base Workspace for Simulink
    vars = fieldnames(params);
    for i = 1:length(vars)
        assignin('base', vars{i}, params.(vars{i}));
    end
    assignin('base', 'R', params.Rm);
    assignin('base', 'sampling_time_pos', params.sampling_time * params.sampling_ratio);
    assignin('base', 'sampling_time_vel', params.sampling_time);
    assignin('base', 'gravity_compensation_mode', params.gravity_mode);

    try
        sim_out = sim('Lab2_cascade_controller_student', 'StopTime', num2str(params.stop_time));
        
        % ดึงข้อมูล
        vel_mat  = sim_out.velocity_loop.Data;
        pos_mat  = sim_out.position_loop.Data;
        eff_mat  = sim_out.control_effort.Data;
        dist_mat = sim_out.disturbance.Data;
        
        data.time = sim_out.tout;
        data.velocity_loop.velocity_ref = vel_mat(:,1);
        data.velocity_loop.velocity_measured = vel_mat(:,2);
        data.velocity_loop.velocity_error = vel_mat(:,3);
        data.position_loop.position_ref = pos_mat(:,1);
        data.position_loop.position_measured = pos_mat(:,2);
        data.position_loop.position_error = pos_mat(:,3);
        data.control_effort.vin = eff_mat(:,1);
        
        % Verification (Absolute Tracking Error ในทุกจุด)
        idx_check = round(length(data.time)*0.2) : length(data.time); % เช็คตั้งแต่เริ่มเสถียร
        data.verify.abs_err_vel = max(abs(data.velocity_loop.velocity_error(idx_check)));
        data.verify.abs_err_pos = max(abs(data.position_loop.position_error(idx_check)));
        data.verify.os_pos = stepinfo(data.position_loop.position_measured, data.time, data.position_loop.position_ref(end)).Overshoot;

        % --- Save Logic ---
        if save_flag == 1
            trial_root = fullfile(params.master_folder, params.trial_name);
            if ~exist(trial_root, 'dir'), mkdir(trial_root); end
            
            % เซฟภาพ Performance
            fig_save = figure('Visible', 'off'); 
            subplot(2,1,1); plot(data.time, data.position_loop.position_ref, 'k--', data.time, data.position_loop.position_measured, 'b');
            title('Position Loop'); grid on;
            subplot(2,1,2); plot(data.time, data.velocity_loop.velocity_ref, 'k--', data.time, data.velocity_loop.velocity_measured, 'r');
            title('Velocity Loop'); grid on;
            saveas(fig_save, fullfile(trial_root, 'performance_plot.png'));
            close(fig_save);
            
            % เซฟ Excel
            T = table(data.time, data.position_loop.position_ref, data.position_loop.position_measured, ...
                      data.velocity_loop.velocity_ref, data.velocity_loop.velocity_measured, data.control_effort.vin, ...
                      'VariableNames', {'Time', 'Pos_Ref', 'Pos_Meas', 'Vel_Ref', 'Vel_Meas', 'Voltage'});
            writetable(T, fullfile(trial_root, 'sim_results.xlsx'));
            fprintf('   [+] Data and Plot saved to: %s\n', trial_root);
        end
        
    catch ME
        fprintf('   [!] Simulation Failed: %s\n', ME.message);
        data.time = [0]; data.verify.abs_err_pos = 999;
    end
end