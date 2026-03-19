%% --- 1. Setup Environment & Physical Parameters ---
clear; clc; close all;
% [Physical Parameters คงเดิม]
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
p_base.init_angle = 0;
p_base.gravity_mode = 1;
p_base.master_folder = 'lab2_part7_Yes_Transistion_Yes_Sat';
p_base.stop_time = 10.0; 

% --- 2. Define Test Space ---
all_hz = [1000, 100, 10, 1];
all_ratios = [5, 2, 1, 0.5, 0.2, 0.1];

% เตรียมที่เก็บข้อมูลสำหรับสรุป (4 Hz x 6 Ratios)
summary_os_pos  = zeros(length(all_hz), length(all_ratios));
summary_err_pos = zeros(length(all_hz), length(all_ratios));
summary_os_vel  = zeros(length(all_hz), length(all_ratios));
summary_err_vel = zeros(length(all_hz), length(all_ratios));
summary_vib     = zeros(length(all_hz), length(all_ratios)); % สำหรับ FFT

% --- 3. Execution Loop ---
idx = 1;
for h = 1:length(all_hz)
    for r = 1:length(all_ratios)
        p = p_base;
        p.Kp_pos = 5.50; p.Ki_pos = 0.05; p.Kd_pos = 0.10;
        p.Kp_vel = 8.20; p.Ki_vel = 1.20; p.Kd_vel = 0.001;
        p.N_pos = 100; p.N_vel = 100;
        
        p.sampling_time = 1/all_hz(h);
        p.sampling_ratio = all_ratios(r);
        cat_name = sprintf('Hz_%d_Ratio_%.2f', all_hz(h), all_ratios(r));
        p.trial_name = cat_name;
        
        fprintf('\n--- [%d/24] Analyzing Jitter: %s ---\n', idx, cat_name);
        data = Lab2_cascade_simulate_controller(p, 1); 
        
        % เก็บสถิติ
        summary_os_pos(h,r)  = check_val(data.verify.os_pos, 100);
        summary_err_pos(h,r) = check_val(data.verify.abs_err_pos, 1);
        summary_os_vel(h,r)  = check_val(data.verify.os_vel, 100);
        summary_err_vel(h,r) = check_val(data.verify.abs_err_vel, 1);
        summary_vib(h,r)     = check_val(data.verify.vibration_power, 500); % เก็บค่า FFT
        
        idx = idx + 1;
    end
end

% --- 4. Image 25: Heatmap Summary (Position) ---
fig25 = figure('Name', 'Heatmap Position', 'Color', 'w', 'Position', [50, 50, 1100, 400]);
subplot(1,2,1); heatmap(all_ratios, all_hz, summary_err_pos, 'Title', 'Pos Error (rad)', 'XLabel', 'Ratio', 'YLabel', 'Hz');
subplot(1,2,2); heatmap(all_ratios, all_hz, summary_os_pos, 'Title', 'Pos Overshoot (%)', 'XLabel', 'Ratio', 'YLabel', 'Hz');
saveas(fig25, fullfile(p_base.master_folder, 'Image_25_Heatmap_Position.png'));

% --- 5. Image 26: Performance Trend with Criteria ---
fig26 = figure('Name', 'Trend Analysis', 'Color', 'w', 'Position', [100, 100, 1000, 900]);
colors = {'#0072BD', '#D95319', '#7E2F8E', '#EDB120'};
titles = {'Pos OS (%)', 'Pos Err (rad)', 'Vel OS (%)', 'Vel Err (rad/s)'};
limits = [2.0, 0.004, 2.0, 0.02];
data_fields = {summary_os_pos, summary_err_pos, summary_os_vel, summary_err_vel};

for k = 1:4
    subplot(4,1,k); hold on; grid on;
    for h = 1:length(all_hz)
        plot(all_ratios, data_fields{k}(h,:), '-o', 'Color', colors{h}, 'LineWidth', 1.5, 'DisplayName', [num2str(all_hz(h)) ' Hz']);
    end
    yline(limits(k), 'r--', 'Limit', 'LineWidth', 1.5);
    ylabel(titles{k}); set(gca, 'XDir', 'reverse');
    if k==1, legend show; title('Cascade Performance Trend'); end
end
saveas(fig26, fullfile(p_base.master_folder, 'Image_26_Performance_Trend.png'));

% --- 6. Image 27: FFT Jitter Analysis (NEW!) ---
fig27 = figure('Name', 'Vibration Analysis', 'Color', 'w', 'Position', [150, 150, 600, 500]);
h_vib = heatmap(all_ratios, all_hz, summary_vib);
h_vib.Title = 'Vibration Power Index (High-Freq FFT Energy)';
h_vib.XLabel = 'Sampling Ratio'; h_vib.YLabel = 'Frequency (Hz)';
h_vib.Colormap = jet; % ใช้ Jet เพื่อให้เห็นจุดที่ "ร้อน" (สั่นมาก) ชัดๆ
saveas(fig27, fullfile(p_base.master_folder, 'Image_27_Vibration_Heatmap.png'));

fprintf('\nSUCCESS: 27 Images and Data saved in: %s\n', p_base.master_folder);

%% --- Helper: Check NaN ---
function val = check_val(raw_val, limit)
    if isnan(raw_val) || raw_val > limit || raw_val < 0, val = NaN; else, val = raw_val; end
end

%% --- Core Function: Simulate Controller with FFT Logic ---
function data = Lab2_cascade_simulate_controller(params, save_flag)
    vars = fieldnames(params);
    for i = 1:length(vars), assignin('base', vars{i}, params.(vars{i})); end
    assignin('base', 'sampling_time_pos', params.sampling_time * params.sampling_ratio);
    assignin('base', 'sampling_time_vel', params.sampling_time);
    assignin('base', 'Ts', params.sampling_time);
    assignin('base', 'R', params.Rm);
    assignin('base', 'gravity_compensation_mode', params.gravity_mode);

    try
        sim_out = sim('Lab2_cascade_controller_student', 'StopTime', num2str(params.stop_time), 'SrcWorkspace', 'base');
        data.time = sim_out.tout;
        pos_mat = sim_out.position_loop.Data; vel_mat = sim_out.velocity_loop.Data;
        
        data.position_loop.position_ref = pos_mat(:,1);
        data.position_loop.position_measured = pos_mat(:,2);
        data.position_loop.position_error = pos_mat(:,3);
        data.velocity_loop.velocity_ref = vel_mat(:,1);
        data.velocity_loop.velocity_measured = vel_mat(:,2);
        data.velocity_loop.velocity_error = vel_mat(:,3);

        % --- [ FFT Calculation for Jitter ] ---
        Fs = 1/params.sampling_time; 
        L = length(data.time);
        if L > 1
            % วิเคราะห์ความสั่นจาก Velocity Error (จุดที่เห็น Jitter ชัดที่สุด)
            sig = data.velocity_loop.velocity_error;
            Y = fft(sig - mean(sig)); % ลบ DC offset ออก
            P2 = abs(Y/L);
            P1 = P2(1:floor(L/2)+1);
            P1(2:end-1) = 2*P1(2:end-1);
            f = Fs*(0:(L/2))/L;
            
            % นิยาม Vibration Power = ผลรวม Magnitude ในช่วงความถี่สูง (Jitter Zone)
            % ปกติ Jitter จาก Sampling จะเกิดที่ความถี่สูง
            jitter_idx = find(f > 5 & f < Fs/2); 
            data.verify.vibration_power = sum(P1(jitter_idx)) * 100; % Scale ให้ดูง่าย
        else
            data.verify.vibration_power = 999;
        end

        % OS & Error Calculation
        s_p = stepinfo(data.position_loop.position_measured, data.time, data.position_loop.position_ref(end));
        v_ref = max(abs(data.velocity_loop.velocity_ref)); if v_ref==0, v_ref=1; end
        s_v = stepinfo(data.velocity_loop.velocity_measured, data.time, v_ref);
        
        data.verify.os_pos = s_p.Overshoot;
        data.verify.os_vel = s_v.Overshoot;
        idx_eval = find(data.time > 0.5);
        data.verify.abs_err_pos = max(abs(data.position_loop.position_error(idx_eval)));
        data.verify.abs_err_vel = max(abs(data.velocity_loop.velocity_error(idx_eval)));

        if save_flag == 1
            trial_path = fullfile(params.master_folder, params.trial_name);
            if ~exist(trial_path, 'dir'), mkdir(trial_path, 'recursive'); end
            T = table(data.time, data.position_loop.position_ref, data.position_loop.position_measured, ...
                      data.velocity_loop.velocity_ref, data.velocity_loop.velocity_measured, ...
                      'VariableNames', {'Time', 'Pos_Ref', 'Pos_Meas', 'Vel_Ref', 'Vel_Meas'});
            writetable(T, fullfile(trial_path, 'raw_sim_data.xlsx'));
            
            % Individual Plot (โชว์ความสั่นในลูใน)
            fig_ind = figure('Visible', 'off');
            subplot(2,1,1); plot(data.time, data.position_loop.position_ref, 'k--', data.time, data.position_loop.position_measured, 'b');
            title(['Pos OS: ' num2str(data.verify.os_pos, '%.2f') '%']); grid on;
            subplot(2,1,2); plot(data.time, data.velocity_loop.velocity_measured, 'r');
            title(['Vel Response (Jitter Check) | Vib Power: ' num2str(data.verify.vibration_power, '%.2f')]); grid on;
            saveas(fig_ind, fullfile(trial_path, 'performance_plot.png')); close(fig_ind);
        end
    catch
        data.time = [0]; data.verify.os_pos = 999; data.verify.os_vel = 999;
        data.verify.abs_err_pos = 999; data.verify.abs_err_vel = 999;
        data.verify.vibration_power = 999;
    end
end