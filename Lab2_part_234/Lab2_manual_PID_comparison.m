%% --- LAB 2: FINAL PERFORMANCE PLOT (MULTI-TRIAL & NAMED LIMITS) ---
clear; clc; close all;
MASTER_FOLDER = 'lab2_part2_results'; 
TYPE = 'PID'; % เลือก 'P' หรือ 'PID'

% --- 1. ตั้งค่าเกณฑ์และชื่อตามประเภท Controller ---
if strcmp(TYPE, 'P')
    sub_trials = dir(fullfile(MASTER_FOLDER, 'P_tuning*'));
    num_plots = 2; labels = {'Percent Overshoot (P.O.)', 'Peak Time (Tp)'};
    limits = [10, 3.0];
    limit_names = {'P.O. Limit', 'Tp Limit'};
else
    sub_trials = dir(fullfile(MASTER_FOLDER, 'PID_Kp*'));
    num_plots = 3; labels = {'Percent Overshoot (P.O.)', 'Settling Time (Ts)', 'Steady State Error (Ess)'};
    limits = [5, 2.5, 0.004];
    limit_names = {'P.O. Limit', 'Ts Limit', 'Ess Limit'};
end

sub_trials = sub_trials([sub_trials.isdir]);
fig = figure('Color', 'w', 'Units', 'normalized', 'Position', [0.05, 0.05, 0.9, 0.85]);
ax_handles = gobjects(1, num_plots);

fprintf('====================================================\n');
fprintf('   ANALYSIS START: %d TRIALS FOUND (%s MODE)\n', length(sub_trials), TYPE);
fprintf('====================================================\n');

% --- 2. วนลูปอ่านข้อมูลทีละชุด Gain (Trial) ---
for i = 1:length(sub_trials)
    current_sub = sub_trials(i).name;
    sub_path = fullfile(MASTER_FOLDER, current_sub);
    runs = dir(fullfile(sub_path, 'Run_*'));
    angles = []; data_matrix = [];
    
    fprintf('\n[STATE] Processing Trial %d: %s\n', i, current_sub);
    
    for j = 1:length(runs)
        run_dir = fullfile(sub_path, runs(j).name);
        file_data = fullfile(run_dir, 'raw_sim_data.mat');
        file_meta = fullfile(run_dir, 'metadata.mat');
        
        if exist(file_data, 'file') && exist(file_meta, 'file')
            S_data = load(file_data); S_meta = load(file_meta);
            
            % ดึงค่า Gain และเป้าหมาย
            kp = S_meta.params.kp; 
            ki = ifthen(isfield(S_meta.params, 'ki'), S_meta.params.ki, 0);
            kd = ifthen(isfield(S_meta.params, 'kd'), S_meta.params.kd, 0);
            ref_deg = S_meta.params.ref_data(2); 
            
            fprintf('   > Reading Angle: %3d deg\n', ref_deg);
            
            time_vec = S_data.data.plant_effort.time;
            measured_vec = S_data.data.sensor.sensor_measured;
            
            % --- จุดสำคัญ: คำนวณ P.O. และ Ts (2%) เทียบกับ Steady State จริง ---
            actual_ss_val = measured_vec(end);
            s_info = stepinfo(measured_vec, time_vec, actual_ss_val, 'SettlingThreshold', 0.02); 
            
            % คำนวณ Error เทียบกับเป้าหมาย (ref_deg)
            ss_err_rad = deg2rad(ref_deg) - deg2rad(actual_ss_val);
            
            angles(end+1) = ref_deg;
            if strcmp(TYPE, 'P')
                data_matrix(end+1,:) = [s_info.Overshoot, s_info.PeakTime];
                data_legend = sprintf('Kp=%.2f', kp);
            else
                data_matrix(end+1,:) = [s_info.Overshoot, s_info.SettlingTime, ss_err_rad];
                data_legend = sprintf('Kp=%.2f, Ki=%.3f, Kd=%.4f', kp, ki, kd);
            end
        end
    end

    if isempty(data_matrix), continue; end

    % --- 3. พล็อตข้อมูล Trial ลงแกนกราฟ ---
    for k = 1:num_plots
        if ~isgraphics(ax_handles(k)), ax_handles(k) = subplot(num_plots, 1, k); hold on; grid on; end
        
        % พล็อตเส้นกราฟพร้อมระบุชื่อ Gain ใน Legend
        p = plot(ax_handles(k), angles, data_matrix(:,k), '-o', 'MarkerSize', 5, 'LineWidth', 1.2, ...
            'DisplayName', data_legend);
        
        % ตัวเลขกำกับจุด (0.4f)
        for pt = 1:length(angles)
            val = data_matrix(pt,k);
            txt = ifthen(isnan(val), 'NaN', sprintf('%.4f', val));
            text(ax_handles(k), angles(pt), val, txt, 'VerticalAlignment', 'bottom', ...
                'HorizontalAlignment', 'center', 'FontSize', 8, 'Color', p.Color);
        end
    end
end

% --- 4. จัดการ Layout และ Named Legend สำหรับเส้น Limit (ทำครั้งเดียว) ---
valid_axes = ax_handles(isgraphics(ax_handles));
for k = 1:length(valid_axes)
    ax = valid_axes(k);
    limit_val = limits(k);
    limit_label = limit_names{k};
    xl = [0, 400]; set(ax, 'XLim', xl);
    
    if k <= 2 % สำหรับ P.O. และ Time (แกนเริ่มที่ 0, Limit อยู่กลาง)
        y_range_max = limit_val * 2;
        lines = findobj(ax, 'Type', 'line'); y_all = [];
        for ln = 1:length(lines), y_all = [y_all, get(lines(ln), 'YData')]; end
        y_all = y_all(~isnan(y_all) & ~isinf(y_all));
        if ~isempty(y_all) && max(y_all) > y_range_max, y_range_max = max(y_all) * 1.2; end
        set(ax, 'YLim', [0, y_range_max]);
        
        % วาดเส้น Limit และตั้งชื่อใน Legend
        yline(ax, limit_val, '--r', 'LineWidth', 2, 'DisplayName', limit_label);
        
        % พื้นที่สี (Patch)
        patch(ax, [xl(1) xl(2) xl(2) xl(1)], [0 0 limit_val limit_val], [0.8 1 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.1, 'HandleVisibility', 'off');
        patch(ax, [xl(1) xl(2) xl(2) xl(1)], [limit_val y_range_max*2 y_range_max*2 limit_val], [1 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.1, 'HandleVisibility', 'off');
        
    else % สำหรับ Ess (+/- Limit สมมาตรรอบ 0)
        y_range_edge = limit_val * 2;
        lines = findobj(ax, 'Type', 'line'); y_all = [];
        for ln = 1:length(lines), y_all = [y_all, get(lines(ln), 'YData')]; end
        y_all = y_all(~isnan(y_all) & ~isinf(y_all));
        if ~isempty(y_all) && max(abs(y_all)) > y_range_edge, y_range_edge = max(abs(y_all)) * 1.2; end
        set(ax, 'YLim', [-y_range_edge, y_range_edge]);
        
        % วาดเส้น Limit +/- และตั้งชื่อใน Legend
        yline(ax, limit_val, '--r', 'LineWidth', 1.5, 'DisplayName', ['+' limit_label]);
        yline(ax, -limit_val, '--r', 'LineWidth', 1.5, 'DisplayName', ['-' limit_label]);
        yline(ax, 0, 'k-', 'HandleVisibility', 'off');
        
        % พื้นที่สี
        patch(ax, [xl(1) xl(2) xl(2) xl(1)], [-limit_val -limit_val limit_val limit_val], [0.8 1 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.1, 'HandleVisibility', 'off');
        patch(ax, [xl(1) xl(2) xl(2) xl(1)], [limit_val limit_val 10 10], [1 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.1, 'HandleVisibility', 'off');
        patch(ax, [xl(1) xl(2) xl(2) xl(1)], [-limit_val -limit_val -10 -10], [1 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.1, 'HandleVisibility', 'off');
    end
    
    ylabel(ax, labels{k}, 'FontWeight', 'bold');
    
    % แสดง Legend สรุปทั้งข้อมูล Gain และชื่อเส้น Limit
    lgd = legend(ax, 'show', 'Location', 'eastoutside', 'Interpreter', 'none');
    
    set(ax, 'Position', [0.1, 0.95 - k*(0.9/num_plots) + 0.05, 0.60, (0.8/num_plots)]);
end
if ~isempty(valid_axes), xlabel(valid_axes(end), 'Target Angle (Degrees)', 'FontWeight', 'bold'); end
fprintf('\n[FINISHED] Multi-trial Analysis Complete.\n');

function out = ifthen(cond, valTrue, valFalse)
    if cond, out = valTrue; else, out = valFalse; end
end