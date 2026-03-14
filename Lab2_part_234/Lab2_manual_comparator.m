%% DATABASE STRUCTURE REFERENCE: Lab 2 Control System (720-0 Test)
% This script serves as a dictionary for the 'data' structure.

%% 1. GROUP: data.sensor
% Focus: Goal vs. Reality
% data.sensor.ref_rad              % [Target] The desired angle (Setpoint)
% data.sensor.err_rad              % [Error]  Difference (Ref - Measured)
% data.sensor.sensor_measured      % [Truth]  The clean angle feedback used by PID
% data.sensor.sensor_measured_raw  % [Raw]    Encoder signal before filtering
% data.sensor.sensor_noise         % [Noise]  The simulated interference applied

%% 2. GROUP: data.controller
% Focus: The "Brain" of the PID (Theoretical vs. Saturated)

% --- Proportional (Current Error) ---
% data.controller.KP               % [Raw P] Theoretical Muscle (Kp * Error)
% data.controller.KP_sat           % [Real P] Portion of 12V limit used by P-term

% --- Integral (Accumulated Error) ---
% data.controller.KI               % [Raw I] Total accumulated error memory
% data.controller.KI_sat           % [Real I] Integral term with Anti-Windup Applied

% --- Derivative (Rate of Change) ---
% data.controller.KD               % [Raw D] Raw speed-based correction (usually noisy)
% data.controller.KD_sat           % [Real D] D-term after the N-Filter (Predictor)

% --- Total Outputs ---
% data.controller.v_pid            % Theoretical sum (could be >100V!)
% data.controller.v_pid_sat        % The actual command capped at 12V

%% 3. GROUP: data.plant_effort
% Focus: Physics and Hardware Limits

% data.plant_effort.time           % The master clock (X-axis for all plots)
% data.plant_effort.plant_input_sat % The actual voltage hitting the motor pins
% data.plant_effort.plant_input     % Desired voltage before physical saturation
% data.plant_effort.v_compense     % Gravity cancellation voltage (Anti-Gravity)
% data.plant_effort.v_pid_out       % PID portion of the total plant input

%% 1. Configuration
% Define the Root path once
base_path = 'C:\Users\User\Documents\GitHub\FRA233_Lab2_G04\Lab2_part_234\';

% Matrix 1: Only the unique sub-folders
% We use 'fullfile' inside the loop to join these to the base_path
sub_folders = {
   'lab2_part2_results\KI3_aw\P0.06_I0.01_D0.00\Run_05_2026-03-14_232754_TimeSeries';
   'lab2_part2_results\KI3_aw\P0.06_I0.05_D0.00\Run_05_2026-03-14_232817_TimeSeries';
};

% Matrix 2: The Signals (1-to-1 mapping)
process_list = {
    'sensor', 'ref_rad',        'left';
    'sensor', 'ref_rad','left';
};

%% 2. Processing and Plotting Logic
clf; 
fig = gcf;
set(fig, 'Color', 'w', 'Units', 'normalized', 'Position', [0.1, 0.1, 0.8, 0.7]);

% Initialize Detectors
hasLeft = false;   
hasRight = false;  
leftLabel = '';
rightLabel = '';

hold on; grid on;
colors = lines(numel(sub_folders));

for i = 1:numel(sub_folders)
    % LOGIC: Combine the base_path with the sub_folder
    f_path      = fullfile(base_path, sub_folders{i});
    group_name  = process_list{i, 1};
    signal_name = process_list{i, 2};
    side_pref   = process_list{i, 3}; 
    
    mat_file = fullfile(f_path, 'raw_sim_data.mat');
    
    if exist(mat_file, 'file')
        load(mat_file); 
        t = data.plant_effort.time;
        
        try
            y = data.(group_name).(signal_name);
            
            % Select side
            yyaxis(side_pref); 
            
            % Unit logic & Dynamic Label Syncing
            if strcmp(group_name, 'sensor')
                y = y * (180/pi); 
                unit_tag = '[deg]';
                current_type = 'Angle (Degrees)';
            else
                unit_tag = '[V]';
                current_type = 'Control Effort (Volts)';
            end
            
            % Sync Labels
            if strcmp(side_pref, 'left')
                hasLeft = true; leftLabel = current_type;
            else
                hasRight = true; rightLabel = current_type;
            end
            
            % Use the folder name in the legend so you know which I-gain it is
            folder_parts = strsplit(sub_folders{i}, '\');
            run_info = folder_parts{2}; % This gets the "P0.06_I0.05..." part
            
            display_name = sprintf('%s: %s', run_info, signal_name);
            plot(t, y, 'LineWidth', 1.5, 'DisplayName', display_name, 'Color', colors(i,:));
            
        catch ME
            fprintf('[ERROR] Signal "%s" failed in folder %d\n', signal_name, i);
        end
    else
        fprintf('[PATH ERROR] Cannot find: %s\n', f_path);
    end
end

%% 3. FINAL FORMATTING (Synced to Actual Inputs)
xlabel('Time (s)');

% Update Left Side
yyaxis left;
if ~hasLeft
    set(gca, 'YTick', [], 'YColor', 'none'); 
    ylabel('');
else
    ylabel(leftLabel); 
    set(gca, 'YColor', 'k', 'YTickMode', 'auto');
end

% Update Right Side
yyaxis right;
if ~hasRight
    set(gca, 'YTick', [], 'YColor', 'none'); 
    ylabel('');
else
    ylabel(rightLabel);
    set(gca, 'YColor', 'k', 'YTickMode', 'auto');
end

title('Comparative Analysis (Unit Synced)');

% Legend outside the box prevents blocking the "sawtooth" spikes
legend('show', 'Location', 'northeastoutside', 'Interpreter', 'none');