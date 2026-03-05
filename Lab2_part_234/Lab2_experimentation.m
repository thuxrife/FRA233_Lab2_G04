%% --- MAIN SCRIPT AREA ---
clear; clc; close all;

% Define the Master Trial Folder
master_folder = 'lab2_part2_results'; 

% run_lab2_experiment(master, sub_trial, init, ref, PO_lim, Tp_lim, kp, ki, kd, gravity, method, show)

% --- P_Tuning_1 Experiment Set ---
run_lab2_experiment(master_folder, 'P_tuning_19', 0, 30, 10, 3.0, 0.0011260, 0, 0, 1, 1, false);
run_lab2_experiment(master_folder, 'P_tuning_19', 0, 60, 10, 3.0, 0.0011260, 0, 0, 1, 1, false);
run_lab2_experiment(master_folder, 'P_tuning_19', 0, 90, 10, 3.0, 0.0011260, 0, 0, 1, 1, false);
run_lab2_experiment(master_folder, 'P_tuning_19', 0, 120, 10, 3.0, 0.0011260, 0, 0, 1, 1, false);
run_lab2_experiment(master_folder, 'P_tuning_19', 0, 150, 10, 3.0, 0.0011260, 0, 0, 1, 1, false);
run_lab2_experiment(master_folder, 'P_tuning_19', 0, 180, 10, 3.0, 0.0011260, 0, 0, 1, 1, false);
run_lab2_experiment(master_folder, 'P_tuning_19', 0, 210, 10, 3.0, 0.0011260, 0, 0, 1, 1, false);
run_lab2_experiment(master_folder, 'P_tuning_19', 0, 240, 10, 3.0, 0.0011260, 0, 0, 1, 1, false);
run_lab2_experiment(master_folder, 'P_tuning_19', 0, 270, 10, 3.0, 0.0011260, 0, 0, 1, 1, false);
run_lab2_experiment(master_folder, 'P_tuning_19', 0, 300, 10, 3.0, 0.0011260, 0, 0, 1, 1, false);
run_lab2_experiment(master_folder, 'P_tuning_19', 0, 330, 10, 3.0, 0.0011260, 0, 0, 1, 1, false);

%% --- FUNCTION DEFINITION ---
function [status, po, tp] = run_lab2_experiment(master_folder, sub_trial_name, init_angle, ref_angle, PO_Limit, Peak_Time_Limit, kp, ki, kd, gravity_compensation_mode, method_pid, show_plot)
    % 1. Hierarchical Folder Setup
    % Path structure: master_folder / sub_trial_name / sim_run_N_timestamp
    TRIAL_PATH = fullfile(master_folder, sub_trial_name);
    if ~exist(TRIAL_PATH, 'dir'), mkdir(TRIAL_PATH); end
    
    ts = datestr(now, 'yyyy-mm-dd_HH-MM-ss'); 
    source_prefix = 'sim'; 
    
    % Search for previous runs within the specific sub-trial folder
    search_pattern = fullfile(TRIAL_PATH, [source_prefix '_run_*']);
    existing_items = dir(search_pattern);
    next_num = sum([existing_items.isdir]) + 1;
    
    SAVE_PATH = fullfile(TRIAL_PATH, sprintf('%s_run_%d_%s', source_prefix, next_num, ts));
    mkdir(SAVE_PATH);

    % 2. Motor/Physical Params
    L = 0.1;
    mp = 0.05;
    g = 9.81;
    kt = 50.6e-3;
    ke = 52.8e-3;
    Lm = 2.8544e-3;
    R = 3.3133;
    b = 77.851e-6;
    J = 58.559e-6;
    T = 0.0002;

    % 3. Simulation
    out = sim('Lab2_single_loop_controller_student', 'StopTime', '10', 'SrcWorkspace', 'current'); 
    Time = out.tout;
    RawData_Mat = out.single_loop.Data;
    Pendulum_Deg = RawData_Mat(:,2);
    Voltage_Out  = RawData_Mat(:,4);

    % 4. Analysis
    upper_bar = ref_angle * (1 + (PO_Limit/100)); 
    peak_val = max(Pendulum_Deg);
    po = max(0, ((peak_val - ref_angle) / ref_angle) * 100); 
    tp = Time(find(Pendulum_Deg == peak_val, 1));
    
    status = 'PASSED';
    if po > PO_Limit || tp > Peak_Time_Limit, status = 'FAILED'; end

    % 5. Plotting
    vis_setting = 'off'; if show_plot, vis_setting = 'on'; end
    fig = figure('Visible', vis_setting, 'Position', [100, 100, 1400, 600], 'Color', 'w');
    axes('Position', [0.08, 0.15, 0.60, 0.75]); 
    
    plot(Time, Pendulum_Deg, 'b', 'LineWidth', 2); hold on;
    yline(ref_angle, 'k--', 'Reference', 'LineWidth', 1.5, 'FontSize', 10);
    yline(upper_bar, 'r:', 'LineWidth', 1.5); 
    xline(Peak_Time_Limit, 'Color', '#006400', 'LineStyle', '--', 'LineWidth', 2.0); 
    xline(tp, 'Color', 'r', 'LineStyle', '-.', 'LineWidth', 2.0);
    plot(tp, peak_val, 'ro', 'MarkerSize', 10, 'LineWidth', 2.5); 
    
    grid on; ylim([0 480]); xlabel('Time (s)'); ylabel('Angle (deg)');
    title(sprintf('[%s] Run %d: Control Analysis', sub_trial_name, next_num));
    
    lgd = legend('Pendulum Angle Position', 'Target (Ref)', 'P.O. Limit Bar', 'Time Limit (3s)', 'Actual Peak');
    set(lgd, 'Position', [0.72, 0.70, 0.20, 0.15]); 

    notation_text = sprintf(['System Notation:\n\n', ...
        'Trial: %s\n', ...
        'Init Angle: %d deg\n', ...
        'Target Angle: %d deg\n', ...
        '1. Limit Peak Time: %.2fs\n', ...
        '2. Actual Peak Time: %.2fs\n', ...
        '3. Limit P.O. : %d%%\n', ...
        '4. Actual P.O. : %.2f%%\n', ...
        '5. Kp Value: %.9f\n', ...
        '6. Ki Value: %.9f\n', ...
        '7. Kd Value: %.9f'], sub_trial_name, init_angle, ref_angle, Peak_Time_Limit, tp, PO_Limit, po, kp, ki, kd);
    
    annotation('textbox', [0.72, 0.25, 0.23, 0.45], 'String', notation_text, ...
        'FitBoxToText', 'on', 'BackgroundColor', 'w', 'EdgeColor', 'k', ...
        'LineWidth', 1.2, 'FontSize', 10, 'FontName', 'Consolas');
    
    saveas(fig, fullfile(SAVE_PATH, 'Response_Plot.png'));
    if ~show_plot, close(fig); end

    % 6. Save Data (Profile and Raw)
    SystemProfile.Trial = sub_trial_name;
    SystemProfile.Init_Angle = init_angle;
    SystemProfile.Target_Angle = ref_angle;
    SystemProfile.Kp = kp;
    SystemProfile.Ki = ki;
    SystemProfile.Kd = kd;
    SystemProfile.Actual_PO = po;
    SystemProfile.Actual_Tp = tp;
    SystemProfile.Status = status;
    
    save(fullfile(SAVE_PATH, 'System_Profile.mat'), 'SystemProfile');
    writetable(struct2table(SystemProfile), fullfile(SAVE_PATH, 'System_Profile.xlsx'));

    DataSummary.Time = Time; DataSummary.Signals = RawData_Mat;
    save(fullfile(SAVE_PATH, 'Raw_Data.mat'), 'DataSummary');
    T_data = table(Time, RawData_Mat(:,1), Pendulum_Deg, RawData_Mat(:,3), Voltage_Out, ...
        'VariableNames', {'Time_s', 'Ref_deg', 'Pendulum_deg', 'Error_deg', 'Motor_V'});
    writetable(T_data, fullfile(SAVE_PATH, 'Data_Sheet.xlsx'));
    
    fprintf('SUCCESS: %s [%s] Run %d saved to: %s\n', master_folder, sub_trial_name, next_num, SAVE_PATH);
end