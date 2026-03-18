function data = Lab2_cascade_simulate_controller(params, save_flag)
    if nargin < 2, save_flag = 0; end 
    
    % 1. --- Map Input & Finite Guard ---
    % ตรวจสอบ Gain ทุกตัวว่าต้องเป็น Finite (ไม่ใช่ NaN/Inf) และห้ามเป็นลบ
    gains = {'Kp_pos', 'Ki_pos', 'Kd_pos', 'Kp_vel', 'Ki_vel', 'Kd_vel'};
    for i = 1:length(gains)
        if ~isfinite(params.(gains{i})) || params.(gains{i}) < 0
            params.(gains{i}) = 1e-5; % กันพลาดให้เป็นค่าต่ำๆ ไว้
        end
    end

    % Assign to Base Workspace
    vars = fieldnames(params);
    for i = 1:length(vars)
        assignin('base', vars{i}, params.(vars{i}));
    end
    assignin('base', 'R', params.Rm);
    assignin('base', 'sampling_time_pos', params.sampling_time * params.sampling_ratio);
    assignin('base', 'sampling_time_vel', params.sampling_time);
    assignin('base', 'gravity_compensation_mode', params.gravity_mode);

    % 2. --- Run Simulation ---
    try
        sim_out = sim('Lab2_cascade_controller_student', 'StopTime', num2str(params.stop_time));
        
        % 3. --- Organize Data ---
        dist_mat = sim_out.disturbance.Data;
        eff_mat  = sim_out.control_effort.Data;
        vel_mat  = sim_out.velocity_loop.Data;
        pos_mat  = sim_out.position_loop.Data;
        
        data.time = sim_out.tout;
        data.motor_state = ones(size(data.time));
        
        data.disturbance.noise_torque = dist_mat(:,1);
        data.disturbance.noise_sensor = dist_mat(:,2);
        data.control_effort.vin        = eff_mat(:,1);
        data.control_effort.u_position = eff_mat(:,2);
        data.control_effort.u_velocity = eff_mat(:,3);
        data.control_effort.RFF        = eff_mat(:,4);
        data.control_effort.DFF        = eff_mat(:,5);
        data.velocity_loop.velocity_ref      = vel_mat(:,1);
        data.velocity_loop.velocity_measured = vel_mat(:,2);
        data.velocity_loop.velocity_error    = vel_mat(:,3);
        data.position_loop.position_ref      = pos_mat(:,1);
        data.position_loop.position_measured = pos_mat(:,2);
        data.position_loop.position_error    = pos_mat(:,3);

        % --- Verification Logic ---
        % ใช้ try-catch กัน stepinfo พังกรณีสัญญาณ Diverge
        try
            s_info_vel = stepinfo(data.velocity_loop.velocity_measured, data.time, data.velocity_loop.velocity_ref(end));
            s_info_pos = stepinfo(data.position_loop.position_measured, data.time, data.position_loop.position_ref(end));
            data.verify.os_vel = s_info_vel.Overshoot;
            data.verify.os_pos = s_info_pos.Overshoot;
        catch
            data.verify.os_vel = 999; data.verify.os_pos = 999;
        end
        
        % Steady State Error (คำนวณจากช่วงท้าย 20%)
        idx_check = round(length(data.time)*0.8) : length(data.time);
        data.verify.abs_err_vel = max(abs(data.velocity_loop.velocity_error(idx_check)));
        data.verify.abs_err_pos = max(abs(data.position_loop.position_error(idx_check)));
        
    catch ME
        % กรณี Sim พัง (Diverge) ให้คืนค่า Error สูงๆ เพื่อให้ตัวจูนรู้
        data.time = [0];
        data.verify.os_vel = 999; data.verify.os_pos = 999;
        data.verify.abs_err_vel = 999; data.verify.abs_err_pos = 999;
        if save_flag, fprintf('Sim Error: %s\n', ME.message); end
    end

    % 4. --- Storage & Excel (Only if save_flag is 1) ---
    if save_flag == 1 && length(data.time) > 1
        trial_root = fullfile(params.master_folder, params.trial_name);
        if ~exist(trial_root, 'dir'), mkdir(trial_root); end
        
        SAVE_PATH = fullfile(trial_root, sprintf('FinalRun_%s', datestr(now, 'HHMMss')));
        mkdir(SAVE_PATH);
        
        save(fullfile(SAVE_PATH, 'raw_sim_data.mat'), 'data');
        
        % Excel Export (15 Columns)
        T_all = table(data.time, data.motor_state, ...
            data.position_loop.position_ref, data.position_loop.position_measured, data.position_loop.position_error, ...
            data.velocity_loop.velocity_ref, data.velocity_loop.velocity_measured, data.velocity_loop.velocity_error, ...
            data.control_effort.vin, data.control_effort.u_position, data.control_effort.u_velocity, ...
            data.control_effort.RFF, data.control_effort.DFF, ...
            data.disturbance.noise_torque, data.disturbance.noise_sensor, ...
            'VariableNames', {'Time', 'Motor_Toggle', 'Pos_Ref', 'Pos_Meas', 'Pos_Err', ...
            'Vel_Ref', 'Vel_Meas', 'Vel_Err', 'Vin', 'U_Pos', 'U_Vel', 'RFF', 'DFF', ...
            'Noise_Torque', 'Noise_Sensor'});
        
        writetable(T_all, fullfile(SAVE_PATH, 'raw_sim_data.xlsx'));
        
        % Plot Performance
        fig = figure('Visible', 'off'); % ไม่ต้องโชว์หน้าต่างตอนเซฟ
        subplot(2,1,1);
        plot(data.time, data.position_loop.position_ref, 'k--', data.time, data.position_loop.position_measured, 'b');
        title(['Position Loop (OS: ', num2str(data.verify.os_pos, '%.2f'), '%)']); grid on;
        subplot(2,1,2);
        plot(data.time, data.velocity_loop.velocity_ref, 'k--', data.time, data.velocity_loop.velocity_measured, 'r');
        title(['Velocity Loop (OS: ', num2str(data.verify.os_vel, '%.2f'), '%)']); grid on;
        saveas(fig, fullfile(SAVE_PATH, 'performance_plot.png'));
        close(fig);
    end
end