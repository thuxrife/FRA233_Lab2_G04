%% --- LAB 2: FINAL PERFORMANCE PLOT (UNIT CORRECTED & COLORED REGIONS) ---
clear; clc; close all;
MASTER_FOLDER = 'lab2_part2_results'; 
TYPE = 'P'; % เลือก 'P' หรือ 'PID'

% --- 1. ตั้งค่าเกณฑ์และชื่อตามประเภท Controller ---
if strcmp(TYPE, 'P')
    sub_trials = dir(fullfile(MASTER_FOLDER, 'P_tuning*'));
    num_plots = 2; labels = {'Percent Overshoot (P.O.)', 'Peak Time (Tp)'};
    limits = [10, 3.0];
    limit_names = {'P.O. Limit', 'Tp Limit'};
else
    sub_trials = dir(fullfile(MASTER_FOLDER, 'PID_Kp*'));
    num_plots = 3; 
    labels = {'Percent Overshoot (P.O.)', 'Settling Time (Ts)', 'Steady State Error (Ess)'};
    limits = [5, 2.5, 0.004]; 
    limit_names = {'P.O. Limit', 'Ts Limit', 'Ess Limit'};
end

sub_trials = sub_trials([sub_trials.isdir]);
fig = figure('Color', 'w', 'Units', 'normalized', 'Position', [0.05, 0.05, 0.9, 0.85]);
ax_handles = gobjects(1, num_plots);

% --- 2. วนลูปอ่านข้อมูลทีละชุด Gain (Trial) ---
for i = 1:length(sub_trials)
    current_sub = sub_trials(i).name;
    sub_path = fullfile(MASTER_FOLDER, current_sub);
    runs = dir(fullfile(sub_path, 'Run_*'));
    angles = []; data_matrix = [];
    
    for j = 1:length(runs)
        run_dir = fullfile(sub_path, runs(j).name);
        file_data = fullfile(run_dir, 'raw_sim_data.mat');
        file_meta = fullfile(run_dir, 'metadata.mat');
        
        if exist(file_data, 'file') && exist(file_meta, 'file')
            S_data = load(file_data); S_meta = load(file_meta);
            
            ref_deg = S_meta.params.ref_data(2); 
            time_vec = S_data.data.plant_effort.time;
            measured_vec = S_data.data.sensor.sensor_measured;
            
            % วิเคราะห์ค่า Performance เทียบกับค่าที่นิ่งจริง
            actual_ss_val = measured_vec(end);
            s_info = stepinfo(measured_vec, time_vec, actual_ss_val, 'SettlingThreshold', 0.02); 
            
            % คำนวณ Error (Radians)
            if isfield(S_data.data, 'err_rad')
                ss_err_rad = S_data.data.err_rad(end);
            else
                ss_err_rad = deg2rad(ref_deg) - actual_ss_val;
            end
            
            angles(end+1) = ref_deg;
            if strcmp(TYPE, 'P')
                data_matrix(end+1,:) = [s_info.Overshoot, s_info.PeakTime];
            else
                data_matrix(end+1,:) = [s_info.Overshoot, s_info.SettlingTime, ss_err_rad];
            end
            
            % สร้างชื่อ Legend จาก Gain
            kp = S_meta.params.kp; 
            ki = ifthen(isfield(S_meta.params, 'ki'), S_meta.params.ki, 0);
            kd = ifthen(isfield(S_meta.params, 'kd'), S_meta.params.kd, 0);
            if strcmp(TYPE, 'P'), data_legend = sprintf('Kp=%.2f', kp);
            else, data_legend = sprintf('Kp=%.2f, Ki=%.3f, Kd=%.4f', kp, ki, kd); end
        end
    end

    if isempty(data_matrix), continue; end

    % --- 3. พล็อตข้อมูล ---
    for k = 1:num_plots
        if ~isgraphics(ax_handles(k)), ax_handles(k) = subplot(num_plots, 1, k); hold on; grid on; end
        p = plot(ax_handles(k), angles, data_matrix(:,k), '-o', 'LineWidth', 1.2, 'DisplayName', data_legend);
        
        % Data Labels
        for pt = 1:length(angles)
            text(ax_handles(k), angles(pt), data_matrix(pt,k), sprintf('%.4f', data_matrix(pt,k)), ...
                'VerticalAlignment', 'bottom', 'FontSize', 8, 'Color', p.Color);
        end
    end
end

% --- 4. จัดการ Layout, Limit Lines และ Colored Regions ---
valid_axes = ax_handles(isgraphics(ax_handles));
for k = 1:length(valid_axes)
    ax = valid_axes(k);
    limit_val = limits(k);
    limit_label = limit_names{k};
    xl = [0, 400]; set(ax, 'XLim', xl);
    
    if k < 3 % สำหรับ P.O. และ Time (แกนบวกเท่านั้น)
        y_max = limit_val * 2.5; % เผื่อที่สำหรับสีแดง
        
        % --- แบ่งโซนสี ---
        % สีเขียว (Pass Zone): 0 ถึง Limit
        patch(ax, [xl(1) xl(2) xl(2) xl(1)], [0 0 limit_val limit_val], [0.8 1 0.8], ...
            'EdgeColor', 'none', 'FaceAlpha', 0.2, 'HandleVisibility', 'off');
        % สีแดง (Fail Zone): Limit ขึ้นไป
        patch(ax, [xl(1) xl(2) xl(2) xl(1)], [limit_val limit_val y_max y_max], [1 0.8 0.8], ...
            'EdgeColor', 'none', 'FaceAlpha', 0.2, 'HandleVisibility', 'off');
        
        yline(ax, limit_val, '--r', 'LineWidth', 2, 'DisplayName', limit_label);
        set(ax, 'YLim', [0, y_max]);
        
    else % สำหรับ Ess (สมมาตรรอบ 0)
        y_edge = limit_val * 2.5;
        
        % --- แบ่งโซนสี (Ess) ---
        % สีเขียว: ระหว่าง -Limit ถึง +Limit
        patch(ax, [xl(1) xl(2) xl(2) xl(1)], [-limit_val -limit_val limit_val limit_val], [0.8 1 0.8], ...
            'EdgeColor', 'none', 'FaceAlpha', 0.2, 'HandleVisibility', 'off');
        % สีแดง (บน): เหนือ +Limit
        patch(ax, [xl(1) xl(2) xl(2) xl(1)], [limit_val limit_val 10 10], [1 0.8 0.8], ...
            'EdgeColor', 'none', 'FaceAlpha', 0.2, 'HandleVisibility', 'off');
        % สีแดง (ล่าง): ต่ำกว่า -Limit
        patch(ax, [xl(1) xl(2) xl(2) xl(1)], [-limit_val -limit_val -10 -10], [1 0.8 0.8], ...
            'EdgeColor', 'none', 'FaceAlpha', 0.2, 'HandleVisibility', 'off');
            
        yline(ax, limit_val, '--r', 'LineWidth', 2, 'DisplayName', ['+' limit_label]);
        yline(ax, -limit_val, '--r', 'LineWidth', 2, 'DisplayName', ['-' limit_label]);
        yline(ax, 0, 'k-', 'HandleVisibility', 'off');
        set(ax, 'YLim', [-y_edge, y_edge]);
    end
    
    ylabel(ax, labels{k}, 'FontWeight', 'bold');
    legend(ax, 'show', 'Location', 'eastoutside', 'Interpreter', 'none');
    
    % ปรับระยะเพื่อให้ Legend ไม่เบียดกราฟ
    set(ax, 'Position', [0.1, 0.95 - k*(0.9/num_plots) + 0.05, 0.60, (0.75/num_plots)]);
end
xlabel(valid_axes(end), 'Target Angle (Degrees)', 'FontWeight', 'bold');

function out = ifthen(cond, valTrue, valFalse)
    if cond, out = valTrue; else, out = valFalse; end
end