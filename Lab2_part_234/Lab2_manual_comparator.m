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

%% LAB 2 ANALYSIS: COMPARATIVE PLOT (LOCKED COLOR PER RUN)
% -------------------------------------------------------------------------

%% 1. Configuration & Paths
base_path = 'C:\Users\User\Documents\GitHub\FRA233_Lab2_G04\Lab2_part_234\';

% ARRAY 1: Data Slots (ระบุ Folder ที่ต้องการเปรียบเทียบ)
folder_slots = {
    
    %% Integration Windup
    'lab2_part2_results\Integration Windup1\P0.06_I0.01_D0.00\Run_00_2026-03-18_120236_TimeSeries';
    'lab2_part2_results\Integration Windup1\P0.06_I0.01_D0.00\Run_01_2026-03-18_120530_TimeSeries';
    'lab2_part2_results\Integration Windup1\P0.05_I0.01_D0.00\Run_00_2026-03-18_120801_TimeSeries';

    %% Gravity Compensation Test
    % 'lab2_part2_results\Gravity_Compense_Test2\P0.00_I0.00_D0.00\Run_00_2026-03-18_022441_TimeSeries';
    % 'lab2_part2_results\Gravity_Compense_Test2\P0.00_I0.00_D0.00\Run_01_2026-03-18_022526_TimeSeries';
    
    %% P Controller with DFF
    % 'lab2_part2_results\Gravity_Compense_Test2\P0.05_I0.00_D0.00\Run_00_2026-03-18_023826_TimeSeries';
    %% P Controller Without DFF
    % 'lab2_part2_results\Gravity_Compense_Test2\P6.00_I0.00_D0.00\Run_00_2026-03-18_022749_TimeSeries';
    % 'lab2_part2_results\Gravity_Compense_Test2\P2.00_I0.00_D0.00\Run_00_2026-03-18_022906_TimeSeries';
    % 'lab2_part2_results\Gravity_Compense_Test2\P10.00_I0.00_D0.00\Run_00_2026-03-18_022811_TimeSeries';
    % 'lab2_part2_results\Gravity_Compense_Test2\P20.00_I0.00_D0.00\Run_00_2026-03-18_023150_TimeSeries';
    % 'lab2_part2_results\Gravity_Compense_Test2\P60.00_I0.00_D0.00\Run_00_2026-03-18_023246_TimeSeries';

    %% KD Test
    % 'lab2_part3_results\PD4_Noise_Sensitivity_test\P0.06_I0.00_D0.02\Run_03_2026-03-18_011025_TimeSeries';
    % 'lab2_part3_results\PD4_Noise_Sensitivity_test\P0.06_I0.00_D0.02\Run_02_2026-03-18_011006_TimeSeries';
    % 'lab2_part3_results\PD4_Noise_Sensitivity_test\P0.06_I0.00_D0.02\Run_01_2026-03-18_010948_TimeSeries';
    % 'lab2_part3_results\PD4_Noise_Sensitivity_test\P0.06_I0.00_D0.00\Run_00_2026-03-18_010917_TimeSeries';    
    % 'lab2_part3_results\PD4_Noise_Sensitivity_test\P0.06_I0.00_D0.02\Run_00_2026-03-18_010933_TimeSeries';
    % 'lab2_part3_results\PD3_Noise_Sensitivity_test\P0.06_I0.00_D0.02\Run_05_2026-03-18_004901_TimeSeries';
};

% --- TIME WINDOW (กำหนดช่วงเวลาที่จะพลอตกราฟตรงนี้) ---
plot_start = 0.0;    % เริ่มที่วินาทีที่...
plot_stop  = 20.0;   % จบที่วินาทีที่...

% --- COLOR PALETTE (ล็อคสีประจำ Run) ---
run_color_palette = {'#0072BD', '#D95319', '#7E2F8E', '#107C10', '#cc0041','#7c70ff'};

% ARRAY 2: Properties
% Columns: {Group, Signal, Y-Axis, Base_Color, Line_Style}
compare_props = {
    % --- GROUP 1: SENSORS (Left Axis: Degrees) ---
    'sensor',       'ref_rad',             'left',  '#000000',   '-';   % BLACK (The King)
    % 'sensor',       'sensor_measured',     'left',  '#982598',   '-';   % ORANGE 
    % 'sensor',       'err_rad',             'left',  '#A52A2A',   '.-';  
    % 'sensor',       'sensor_noise',        'left',  '#D2691E',   ':';   
    % 'sensor',       'sensor_measured_raw', 'left',  '#808080',   '-';   


    % % --- GROUP 2: CONTROLLER (Right Axis: Volts) ---
    % 'controller',   'v_pid_sat',           'right', '#1A05A2',   '-';   % BLUE
    'controller',   'v_pid',               'right', '#1A05A2',   '-';  
    % 'controller',   'KP_sat',              'right', '#8F0177',   '-';   % CYAN
    % 'controller',   'KP',                  'right', '#8F0177',   ':';  
    % 'controller',   'KI_sat',              'right', '#F67D31',   '-';   % ROYAL BLUE
    'controller',   'KI',                  'right', '#F67D31',   '--';  
    % 'controller',   'KD_sat',              'right', '#8A2BE2',   '--';   % PURPLE
    % 'controller',   'KD',                  'right', '#8A2BE2',   '-';  
    
    % % --- GROUP 3: PLANT EFFORT (Right Axis: Volts) ---
    % 'plant_effort', 'plant_input_sat',     'right', '#FF0000',   '-';   % RED
    % 'plant_effort', 'plant_input',         'right', '#FF0000',   '-';  
    % 'plant_effort', 'v_pid_out',           'right', '#FF6347',   '-';   
    % 'plant_effort', 'v_compense',          'right', '#8B0000',   ':';   % MAROON
};

%% 2. Plot Execution
figure(1); clf; 
set(gcf, 'Color', 'w', 'Units', 'normalized', 'Position', [0.1, 0.1, 0.6, 0.6]);

run_analysis_integrated(folder_slots, compare_props, base_path, run_color_palette, plot_start, plot_stop, 'P Controller with and without Gravity Compensation');

%% 3. INTEGRATED CORE LOGIC FUNCTION
function run_analysis_integrated(slots, props, base, palette, t_start, t_stop, title_str)
    hold on; grid on;
    hasLeft = false; hasRight = false;
    
    for f = 1:numel(slots)
        % Load Data
        data_path = fullfile(base, slots{f}, 'raw_sim_data.mat');
        if ~exist(data_path, 'file')
            warning('Data not found: %s', data_path);
            continue;
        end
        load(data_path);
        t = data.plant_effort.time;
        
        % --- COLOR LOGIC (Locked per Run) ---
        color_idx = mod(f-1, numel(palette)) + 1;
        run_hex = palette{color_idx};
        run_color = [hex2dec(run_hex(2:3)), hex2dec(run_hex(4:5)), hex2dec(run_hex(6:7))]/255;

        for p = 1:size(props, 1)
            grp=props{p,1}; sig=props{p,2}; side=props{p,3}; style=props{p,5}; % ดึงค่าจาก Column 5
            
            try
                y = data.(grp).(sig);
                yyaxis(side);
                if strcmp(side, 'left'), hasLeft = true; else, hasRight = true; end
                
                % --- SIGNAL COLOR & LINE STYLE ---
                if strcmp(sig, 'ref_rad')
                    final_c = [0 0 0]; % ล็อค Reference เป็นสีดำ
                    lw = 1.5;
                else
                    final_c = run_color; % ใช้สีจาก Palette
                    lw = 1.2; % ปรับเส้นให้บางลงเล็กน้อยเพื่อให้เห็น Noise ชัดขึ้น
                end
                
                % Convert Units
                if strcmp(grp, 'sensor'), y = y * (180/pi); end
                
                % Plot (Force NO MARKERS)
                plot(t, y, 'Color', final_c, 'LineWidth', lw, 'LineStyle', style, ...
                     'Marker', 'none', ... % สั่งปิดจุด (Marker) อย่างเด็ดขาด
                     'DisplayName', sprintf('Run%d: %s', f, sig));
            catch
                fprintf('Error plotting: %s.%s\n', grp, sig);
            end
        end
    end
    
    % --- FINAL FORMATTING ---
    if hasLeft
        yyaxis left; ylabel('Angle (Deg)'); set(gca, 'YColor', 'k');
        yl = ylim; pad = diff(yl) * 0.10; ylim([yl(1)-pad, yl(2)+pad]);
    end
    
    if hasRight
        yyaxis right; ylabel('Effort (V)'); set(gca, 'YColor', 'k');
        yr = ylim; pad = diff(yr) * 0.10; ylim([yr(1)-pad, yr(2)+pad]);
    end
    
    xlabel('Time (s)'); xlim([t_start, t_stop]);
    title(title_str, 'FontSize', 14);
    legend('show', 'Location', 'northeastoutside', 'Interpreter', 'none');
    grid on;
end