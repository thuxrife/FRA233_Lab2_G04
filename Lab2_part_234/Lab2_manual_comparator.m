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
base_path = 'C:\Users\User\Documents\GitHub\FRA233_Lab2_G04\Lab2_part_234\';


% ARRAY 1: Data Slots (The "Subjects")
% Add as many folders as you want here.
folder_slots = {
   % 'lab2_part2_results\KI_test\P0.06_I0.01_D0.00\Run_00_2026-03-15_004534_TimeSeries';
    % 'lab2_part2_results\KI_test\P0.06_I0.05_D0.00\Run_00_2026-03-15_004616_TimeSeries';
    % 'lab2_part2_results\KI_test\P0.06_I0.01_D0.00\Run_02_2026-03-15_022025_TimeSeries';
    % 'lab2_part2_results\KI_test\P0.06_I0.05_D0.00\Run_02_2026-03-15_022059_TimeSeries';
    % 'lab2_part2_results\KI_test\P0.06_I0.50_D0.00\Run_01_2026-03-15_022900_TimeSeries';
    'lab2_part2_results\PID_Kp_0.06_Ki_0.00_Kd_0.00_N_100_WithGrav\Run_11_2026-03-15_174947_TimeSeries';

};

% --- TIME WINDOW (Viewfinder) ---
plot_start = 0.0;
plot_stop  = 20.0;

% ARRAY 2: Properties
% Columns: {Group, Signal, Y-Axis, Base_Color, Line_Style}
compare_props = {
    % --- GROUP 1: SENSORS (Left Axis: Degrees) ---
    'sensor',       'ref_rad',             'left',  '#000000',   '-';   % BLACK (The King)
    'sensor',       'sensor_measured',     'left',  '#982598',   '-';   % ORANGE 
    % 'sensor',       'err_rad',             'left',  '#A52A2A',   '--';  
    % 'sensor',       'sensor_measured_raw', 'left',  '#808080',   ':';   
    % 'sensor',       'sensor_noise',        'left',  '#D2691E',   ':';   

    % % --- GROUP 2: CONTROLLER (Right Axis: Volts) ---
    % 'controller',   'v_pid_sat',           'right', '#1A05A2',   '-';   % BLUE
    % 'controller',   'v_pid',               'right', '#1A05A2',   '--';  
    % 'controller',   'KP_sat',              'right', '#8F0177',   '-';   % CYAN
    % 'controller',   'KP',                  'right', '#8F0177',   '--';  
    % 'controller',   'KI_sat',              'right', '#F67D31',   '-';   % ROYAL BLUE
    'controller',   'KI',                  'right', '#F67D31',   '--';  
    % 'controller',   'KD_sat',              'right', '#8A2BE2',   '--';   % PURPLE
    % 'controller',   'KD',                  'right', '#8A2BE2',   '-';  
    
    % % --- GROUP 3: PLANT EFFORT (Right Axis: Volts) ---
    % 'plant_effort', 'plant_input_sat',     'right', '#FF0000',   '-';   % RED
    % 'plant_effort', 'plant_input',         'right', '#FF0000',   '--';  
    % 'plant_effort', 'v_pid_out',           'right', '#FF6347',   '-';   
    % 'plant_effort', 'v_compense',          'right', '#8B0000',   '-';   % MAROON
};

%% 2. TASK 1: THE COMBINED PICTURE (Comparison)
figure(1); clf; hold on; grid on;
set(gcf, 'Color', 'w', 'Units', 'normalized', 'Position', [0.05, 0.5, 0.4, 0.4]);

white_ratios = [0.0, 0.25, 0.65, 0.90]; 
run_analysis(folder_slots, compare_props, base_path, white_ratios, plot_start, plot_stop, 'All-in-One Comparison');

%% 3. TASK 2: INDIVIDUAL PICTURES (Deep Dives)
for i = 1:numel(folder_slots)
    figure(i + 1); clf; hold on; grid on;
    set(gcf, 'Color', 'w', 'Units', 'normalized', 'Position', [0.5, 0.5 - (i*0.1), 0.4, 0.4]);
    
    % Logic: For individual plots, we use [0] so the color is 100% vibrant
    individual_slot = folder_slots(i);
    run_analysis(individual_slot, compare_props, base_path, [0], plot_start, plot_stop, sprintf('Individual Analysis: Run %d', i));
end

%% --- REUSABLE CORE LOGIC (Hex Markers + 10% Margin) ---
function run_analysis(slots, props, base, ratios, t_start, t_stop, title_str)
    hasLeft = false; hasRight = false;
    
    % Step 1: Signal Plotting Loop
    for f = 1:numel(slots)
        load(fullfile(base, slots{f}, 'raw_sim_data.mat'));
        t = data.plant_effort.time;
        
        for p = 1:size(props, 1)
            grp=props{p,1}; sig=props{p,2}; side=props{p,3}; hex=props{p,4}; style=props{p,5};
            try
                y = data.(grp).(sig);
                yyaxis(side);
                if strcmp(side, 'left'), hasLeft = true; else, hasRight = true; end
                
                c = [hex2dec(hex(2:3)), hex2dec(hex(4:5)), hex2dec(hex(6:7))]/255;
                if strcmp(sig, 'ref_rad'), final_c = [0 0 0]; lw = 2; else, final_c = c + (1-c)*ratios(f); lw = 1.5; end
                
                if strcmp(grp, 'sensor'), y = y * (180/pi); end
                plot(t, y, 'Color', final_c, 'LineWidth', lw, 'LineStyle', style, ...
                     'Marker', 'none', 'DisplayName', sprintf('Run%d: %s', f, sig));
            catch, end
        end
        
        % Step 2: VERTICAL EVENT MARKERS (Hex Colored)
        if isfield(data, 'motor_state') && f == 1
            yyaxis left; 
            state = data.motor_state;
            changes = find(diff(state) ~= 0);
            for idx = 1:length(changes)
                t_ev = t(changes(idx));
                
                if state(changes(idx)) == 1 && state(changes(idx)+1) == 0
                    % STALL: Using Hex #D9534F (Soft Red)
                    c_hex = '#D9534F';
                    xl = xline(t_ev, '--', 'Stall', 'LineWidth', 2);
                else
                    % RELEASE: Using Hex #5CB85C (Soft Green)
                    c_hex = '#5CB85C';
                    xl = xline(t_ev, '-', 'Release', 'LineWidth', 2);
                end
                
                % Apply Hex Color to Line and Text
                xl.Color = [hex2dec(c_hex(2:3)), hex2dec(c_hex(4:5)), hex2dec(c_hex(6:7))]/255;
                
                % Label Formatting (Horizontal & Centered)
                xl.LabelOrientation = 'horizontal';
                xl.LabelVerticalAlignment = 'top';
                xl.LabelHorizontalAlignment = 'center';
                xl.HandleVisibility = 'off';
            end
        end
    end
    
    % Step 3: APPLY 10% VERTICAL MARGINS
    % Margin for Left (Degrees)
    yyaxis left;
    yl_l = ylim; padding_l = diff(yl_l) * 0.10;
    ylim([yl_l(1) - padding_l, yl_l(2) + padding_l]);
    ylabel('Angle (Deg)'); set(gca, 'YColor', 'k');
    
    % Margin for Right (Voltage)
    yyaxis right;
    yl_r = ylim; padding_r = diff(yl_r) * 0.10;
    ylim([yl_r(1) - padding_r, yl_r(2) + padding_r]);
    ylabel('Effort (V)'); set(gca, 'YColor', 'k');
    
    % Step 4: Final Formatting
    xlabel('Time (s)'); xlim([t_start, t_stop]);
    title(title_str); 
    legend('show', 'Location', 'northeastoutside', 'Interpreter', 'none');
    grid on;
end