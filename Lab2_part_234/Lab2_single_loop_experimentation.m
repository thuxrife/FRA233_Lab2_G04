%% --- 1. CONFIGURATION & VARIABLES ---
clear; clc; close all;
% Master Folder Path
master_folder = 'lab2_part2_results'; 
% Shared Simulation Parameters
trial_name = 'P_tuning_1';
init_angle = 0;
PO_limit   = 10;
Tp_limit   = 3.0;
kp_val     = 0.06590;  
ki_val     = 0;
kd_val     = 0;
gravity_mode = 1; % Gravity Compensation
pid_method   = 1; % Discretization method
show_plots   = false;
stop_time    = 10.0;
% Define the range of angles to test
% Start: 30, Step: 30, End: 360
target_angles = 30:30:360; 
%% --- 2. PID EXPERIMENT SET (AUTOMATED LOOP) ---
fprintf('Starting automated experiment set: %s\n', trial_name);
for ref = target_angles
    fprintf('Running simulation for Target Angle: %d deg...\n', ref);
    
    % Parameters: master, sub_trial, init, ref, PO_lim, Tp_lim, kp, ki, kd, gravity, method, show, STOP_TIME
    run_lab2_experiment(master_folder, trial_name, init_angle, ref, ...
                        PO_limit, Tp_limit, kp_val, ki_val, kd_val, ...
                        gravity_mode, pid_method, show_plots, stop_time);
end
fprintf('All %d experiments completed successfully.\n', length(target_angles));
%% --- FUNCTION DEFINITION ---
function [status, po, tp] = run_lab2_experiment(master_folder, sub_trial_name, init_angle, ref_angle, PO_Limit, Peak_Time_Limit, kp, ki, kd, gravity_compensation_mode, method_pid, show_plot, simulation_time)
    
    % --- 1. Folder Setup ---
    TRIAL_PATH = fullfile(master_folder, sub_trial_name);
    if ~exist(TRIAL_PATH, 'dir'), mkdir(TRIAL_PATH); end
    ts = datestr(now, 'yyyy-mm-dd_HH-MM-ss'); 
    SAVE_PATH = fullfile(TRIAL_PATH, sprintf('sim_run_%s', ts));
    if ~exist(SAVE_PATH, 'dir'), mkdir(SAVE_PATH); end
    % --- 2. Params & 3. Simulation ---
    L = 0.1;
    mp = 0.05;
    g = 9.81;
    kt = 50.6e-3;
    ke = 52.8e-3;
    Lm = 2.8544e-3;
    R = 3.3133;
    b = 77.851e-6;
    J = 58.559e-6;
    T = Lm/R;
    out = sim('Lab2_single_loop_controller_student', 'StopTime', num2str(simulation_time), 'SrcWorkspace', 'current');
    Time = out.tout;
    RawData_Mat = out.single_loop.Data;
    Pendulum_Deg = RawData_Mat(:,2);
    Voltage_Out  = RawData_Mat(:,4);
  % --- 4. Analysis ---
    window_size = round(length(Pendulum_Deg) * 0.05);
    y_ss = mean(Pendulum_Deg(end-window_size:end));
    ss_error = ref_angle - y_ss;
    
    S = stepinfo(Pendulum_Deg, Time, y_ss, init_angle);
    po = S.Overshoot;
    tp = S.PeakTime;
    tr = S.RiseTime;
    ts_settle = S.SettlingTime;
    peak_val = S.Peak + init_angle;
    
    % NEW: Calculate Overshoot in Degrees
    % po_deg represents the absolute swing above the final steady-state value
    po_deg = (po / 100) * abs(y_ss - init_angle); 
    limit_po_deg = (PO_Limit / 100) * abs(y_ss - init_angle); 
    
    % Stability Check
    end_samples = round(1.0 / T); 
    oscillation = max(Pendulum_Deg(end-min(end,end_samples):end)) - min(Pendulum_Deg(end-min(end,end_samples):end));
    
    if oscillation > 0.5, status = 'UNSTABLE';
    elseif po > PO_Limit || tp > Peak_Time_Limit, status = 'FAILED';
    else, status = 'PASSED'; end
    
    upper_bar = y_ss * (1 + (PO_Limit/100));

    % --- 5. Plotting Area ---
    vis_setting = 'off'; if show_plot, vis_setting = 'on'; end
    fig = figure('Visible', vis_setting, 'Position', [50, 50, 1400, 800], 'Color', 'w');
    ax = axes('Position', [0.08, 0.12, 0.58, 0.80]);
    
    plot(Time, Pendulum_Deg, 'b', 'LineWidth', 2); hold on;
    yline(ref_angle, 'k--', 'LineWidth', 1.5);
    yline(y_ss, 'm-.', 'LineWidth', 1.5);
    yline(upper_bar, 'r:', 'LineWidth', 1.5);
    
    xline(Peak_Time_Limit, 'Color', '#006400', 'LineStyle', '--', 'LineWidth', 2.0);
    xline(tp, 'Color', 'r', 'LineStyle', '-.', 'LineWidth', 1.5);
    plot(tp, peak_val, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
    
    grid on; box on;
    xlabel('Time (s)'); ylabel('Angle (deg)');
    title('Control Analysis', 'FontSize', 14);
    
    lgd = legend('Actual Position', 'Target Ref', 'Steady State', 'PO Limit', 'Time Limit', 'Actual Peak', ...
           'Position', [0.70, 0.75, 0.22, 0.12], 'FontSize', 10);
           
    % UPDATED: Notation now shows % and Degree values for P.O.
    notation_text = sprintf(['Control Analysis:\n\n', ...
        '1. Init Angle: %.6f deg\n', ...
        '2. Ref. Angle: %.6f deg\n', ...
        '3. Limit Tp:   %.6f s\n', ...
        '4. Actual Tp:  %.6f s\n', ...
        '5. Limit P.O.: %.6f %% (%.2f deg)\n', ...
        '6. Actual P.O.: %.6f %% (%.2f deg)\n', ...
        '7. Kp Value:   %.6f\n', ...
        '8. Ki Value:   %.6f\n', ...
        '9. Kd Value:   %.6f\n', ...
        '10. Status:    %s'], ...
        double(init_angle), double(ref_angle), double(Peak_Time_Limit), tp, ...
        double(PO_Limit), limit_po_deg, po, po_deg, kp, ki, kd, status);
    
    annotation('textbox', [0.70, 0.15, 0.25, 0.55], 'String', notation_text, ...
        'FitBoxToText', 'on', 'BackgroundColor', 'w', 'EdgeColor', 'k', ...
        'FontName', 'Consolas', 'FontSize', 10, 'VerticalAlignment', 'top');

    saveas(fig, fullfile(SAVE_PATH, 'Response_Plot_Auto.png'));
    ylim(ax, [0 480]);
    saveas(fig, fullfile(SAVE_PATH, 'Response_Plot_Fixed.png'));
    if ~show_plot, close(fig); end

    % --- 6. Save Data (Complete System Profile) ---
    SystemProfile.Trial = sub_trial_name;
    SystemProfile.Timestamp = ts;
    SystemProfile.Init_Angle = init_angle;
    SystemProfile.Target_Angle = ref_angle;
    SystemProfile.Limit_Tp = Peak_Time_Limit;
    SystemProfile.Limit_PO = PO_Limit;
    SystemProfile.Limit_PO_Deg = limit_po_deg; % NEW
    SystemProfile.Kp = kp; SystemProfile.Ki = ki; SystemProfile.Kd = kd;
    SystemProfile.Steady_State = y_ss;
    SystemProfile.SS_Error = ss_error;
    SystemProfile.Rise_Time = tr;
    SystemProfile.Settling_Time = ts_settle;
    SystemProfile.Actual_PO = po;
    SystemProfile.Actual_PO_Deg = po_deg; % NEW
    SystemProfile.Actual_Tp = tp;
    SystemProfile.Status = status;
    
    % Save to Files
    save(fullfile(SAVE_PATH, 'System_Profile.mat'), 'SystemProfile');
    writetable(struct2table(SystemProfile), fullfile(SAVE_PATH, 'System_Profile.xlsx'));
    
    RawDataSummary.Time = Time;
    RawDataSummary.Angle = Pendulum_Deg;
    RawDataSummary.Voltage = Voltage_Out;
    save(fullfile(SAVE_PATH, 'Raw_Simulation_Data.mat'), 'RawDataSummary');
    
    fprintf('SUCCESS: %s complete results saved to %s\n', sub_trial_name, SAVE_PATH);
end