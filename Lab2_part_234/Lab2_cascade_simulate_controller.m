function Lab2_cascade_simulate_controller(params)
    % 1. --- Map Input Parameters & Assign to Base ---
    L = params.L; mp = params.mp; g = params.g;
    kt = params.kt; ke = params.ke; Lm = params.Lm; Rm = params.Rm;
    b = params.b; J = params.J; T = params.T; R = Rm;
    
    Kp_pos = params.Kp_pos; Ki_pos = params.Ki_pos; Kd_pos = params.Kd_pos;
    Kp_vel = params.Kp_vel; Ki_vel = params.Ki_vel; Kd_vel = params.Kd_vel;
    N_pos  = params.N_pos;  N_vel  = params.N_vel;
    
    % ส่งค่าเข้า Base Workspace เพื่อให้ Simulink เรียกใช้
    assignin('base', 'L', L); assignin('base', 'mp', mp); assignin('base', 'g', g);
    assignin('base', 'kt', kt); assignin('base', 'ke', ke); 
    assignin('base', 'Lm', Lm); assignin('base', 'Rm', Rm); 
    assignin('base', 'R', R);   assignin('base', 'T', T);
    assignin('base', 'b', b);   assignin('base', 'J', J);
    assignin('base', 'Kp_pos', Kp_pos); assignin('base', 'Ki_pos', Ki_pos); assignin('base', 'Kd_pos', Kd_pos);
    assignin('base', 'Kp_vel', Kp_vel); assignin('base', 'Ki_vel', Ki_vel); assignin('base', 'Kd_vel', Kd_vel);
    assignin('base', 'N_pos', N_pos);   assignin('base', 'N_vel', N_vel);
    assignin('base', 'gravity_compensation_mode', params.gravity_mode);
    assignin('base', 'init_angle', params.init_angle);
    assignin('base', 'sampling_time_pos', params.sampling_time * params.sampling_ratio);
    assignin('base', 'sampling_time_vel', params.sampling_time);
    assignin('base', 'z2', params.z2); assignin('base', 'z1', params.z1); assignin('base', 'z0', params.z0);
    assignin('base', 'p2', params.p2); assignin('base', 'p1', params.p1); assignin('base', 'p0', params.p0);

    % 2. --- Run Simulation ---
    sim_out = sim('Lab2_cascade_controller_student', 'StopTime', num2str(params.stop_time));

    % 3. --- Organize Data (ใช้ Matrix Indexing จาก To Workspace ตรงๆ) ---
    try
        dist_mat = sim_out.disturbance.Data;
        eff_mat  = sim_out.control_effort.Data;
        vel_mat  = sim_out.velocity_loop.Data;
        pos_mat  = sim_out.position_loop.Data;
        
        data.time = sim_out.tout;
        data.motor_state = ones(size(data.time));

        % Group 1: disturbance
        data.disturbance.noise_torque = dist_mat(:,1);
        data.disturbance.noise_sensor = dist_mat(:,2);
        
        % Group 2: control_effort
        data.control_effort.vin        = eff_mat(:,1);
        data.control_effort.u_position = eff_mat(:,2);
        data.control_effort.u_velocity = eff_mat(:,3);
        data.control_effort.RFF        = eff_mat(:,4);
        data.control_effort.DFF        = eff_mat(:,5);
        
        % Group 3: velocity_loop
        data.velocity_loop.velocity_ref      = vel_mat(:,1);
        data.velocity_loop.velocity_measured = vel_mat(:,2);
        data.velocity_loop.velocity_error    = vel_mat(:,3);
        
        % Group 4: position_loop
        data.position_loop.position_ref      = pos_mat(:,1);
        data.position_loop.position_measured = pos_mat(:,2);
        data.position_loop.position_error    = pos_mat(:,3);

        % --- [NEW] Verification Logic (Step Info & Tracking Error) ---
        % ใช้ค่าสุดท้ายของ Reference เป็น Target สำหรับ stepinfo
        ss_vel_target = data.velocity_loop.velocity_ref(end);
        ss_pos_target = data.position_loop.position_ref(end);

        s_info_vel = stepinfo(data.velocity_loop.velocity_measured, data.time, ss_vel_target);
        s_info_pos = stepinfo(data.position_loop.position_measured, data.time, ss_pos_target);

        % Absolute Tracking Error (เช็คช่วงท้ายของการซิม 20% เพื่อดูความแม่นยำตอนนิ่ง)
        idx_check = round(length(data.time)*0.8) : length(data.time);
        abs_err_vel = max(abs(data.velocity_loop.velocity_error(idx_check)));
        abs_err_pos = max(abs(data.position_loop.position_error(idx_check)));

        % สรุปผลตรวจสอบ
        data.verify.os_vel = s_info_vel.Overshoot;
        data.verify.os_pos = s_info_pos.Overshoot;
        data.verify.abs_err_vel = abs_err_vel;
        data.verify.abs_err_pos = abs_err_pos;

    catch ME
        fprintf('\n--- EXTRACTION ERROR --- \n');
        disp(ME.message); return;
    end

    % 4. --- Storage & Excel (ใช้ตาราง T_all ตามที่คุณกำหนด) ---
    trial_root = fullfile(params.master_folder, params.trial_name);
    if ~exist(trial_root, 'dir'), mkdir(trial_root); end
    run_index = sum([dir(fullfile(trial_root, 'Run_*')).isdir]);
    folder_name = sprintf('Run_%02d_%s_CascadeSeries', run_index, datestr(now, 'yyyy-mm-dd_HHMMss'));
    SAVE_PATH = fullfile(trial_root, folder_name);
    mkdir(SAVE_PATH);

    save(fullfile(SAVE_PATH, 'raw_sim_data.mat'), 'data');

    % --- สร้าง Excel Table ให้เก็บข้อมูลครบทุกตัวตามที่คุณส่งมา ---
    T_all = table(data.time, data.motor_state, ...
        data.position_loop.position_ref, data.position_loop.position_measured, data.position_loop.position_error, ...
        data.velocity_loop.velocity_ref, data.velocity_loop.velocity_measured, data.velocity_loop.velocity_error, ...
        data.control_effort.vin, data.control_effort.u_position, data.control_effort.u_velocity, ...
        data.control_effort.RFF, data.control_effort.DFF, ...
        data.disturbance.noise_torque, data.disturbance.noise_sensor, ...
        'VariableNames', {'Time', 'Motor_Toggle', ...
        'Pos_Ref', 'Pos_Meas', 'Pos_Err', ...
        'Vel_Ref', 'Vel_Meas', 'Vel_Err', ...
        'Vin', 'U_Pos', 'U_Vel', 'RFF', 'DFF', ...
        'Noise_Torque', 'Noise_Sensor'});

    writetable(T_all, fullfile(SAVE_PATH, 'raw_sim_data.xlsx'));
    
    save(fullfile(SAVE_PATH, 'metadata.mat'), 'params');
    writetable(struct2table(params, 'AsArray', true), fullfile(SAVE_PATH, 'metadata.xlsx'));

    % 5. --- Plot Graphs ---
    fig = figure('Name', 'Performance Analysis', 'Color', 'w');
    subplot(2,1,1);
    plot(data.time, data.position_loop.position_ref, 'k--', data.time, data.position_loop.position_measured, 'b');
    title(['Position Loop (P.O.: ', num2str(data.verify.os_pos, '%.2f'), '%)']);
    grid on; ylabel('Rad');

    subplot(2,1,2);
    plot(data.time, data.velocity_loop.velocity_ref, 'k--', data.time, data.velocity_loop.velocity_measured, 'r');
    title(['Velocity Loop (P.O.: ', num2str(data.verify.os_vel, '%.2f'), '%)']);
    grid on; ylabel('Rad/s'); xlabel('Time (s)');
    
    saveas(fig, fullfile(SAVE_PATH, 'performance_plot.png'));

    % 6. --- Print Results ---
    fprintf('\n--- VERIFICATION ---\n');
    fprintf('1. P.O. Velocity: %.2f%% (Goal <= 2%%) -> %s\n', data.verify.os_vel, pass_fail(data.verify.os_vel <= 2));
    fprintf('2. Max Err Vel: %.4f (Goal <= 0.02) -> %s\n', data.verify.abs_err_vel, pass_fail(data.verify.abs_err_vel <= 0.02));
    fprintf('3. P.O. Position: %.2f%% (Goal <= 2%%) -> %s\n', data.verify.os_pos, pass_fail(data.verify.os_pos <= 2));
    fprintf('4. Max Err Pos: %.4f (Goal <= 4e-3) -> %s\n', data.verify.abs_err_pos, pass_fail(data.verify.abs_err_pos <= 0.004));
end

function s = pass_fail(cond)
    if cond, s = 'PASS'; else, s = 'FAIL'; end
end