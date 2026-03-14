function Lab2_manual_simulate_controller(params)
    % 1. --- Map Input Parameters ---
    % (Keeping your original mapping logic)
    kp = params.kp; ki = params.ki; kd = params.kd; N = params.N; 
    init_angle = params.init;
    method_pid = params.method; 
    gravity_compensation_mode = params.gravity_mode; 
    ref_angle = params.ref_data(1); 
    ref_signal = [params.ref_time(:), params.ref_data(:)];
    
    % Plant Parameters
    R = 3.3133; Lm = 2.8544e-3; J = 58.559e-6; b = 77.851e-6;
    kt = 50.6e-3; ke = 52.8e-3; mp = 0.05; L = 0.1; g = 9.81;
    T = Lm / R;

    % 2. --- Run Simulation ---
    sim_out = sim('Lab2_single_loop_controller_student', ...
                  'StopTime', num2str(params.stop_time), ...
                  'SrcWorkspace', 'current');

    % 3. --- Organize Data ---
    try
        eff_mat  = sim_out.plant_effort.Data;
        sens_mat = sim_out.sensor.Data;
        ctrl_mat = sim_out.controller.Data;
        
        data.plant_effort.time            = sim_out.tout;
        
        % --- Plant Effort (Indices 1-4) ---
        data.plant_effort.plant_input_sat = eff_mat(:,1);
        data.plant_effort.plant_input     = eff_mat(:,2);
        data.plant_effort.v_pid_out       = eff_mat(:,3);
        data.plant_effort.v_compense      = eff_mat(:,4);
        
        % --- Sensor (Indices 1-5) ---
        data.sensor.ref_rad             = sens_mat(:,1);
        data.sensor.err_rad             = sens_mat(:,2);
        data.sensor.sensor_measured_raw = sens_mat(:,3);
        data.sensor.sensor_noise        = sens_mat(:,4);
        data.sensor.sensor_measured     = sens_mat(:,5);
        
        % --- Controller (Indices 1-8: Matches Image 2) ---
        data.controller.v_pid     = ctrl_mat(:,1);
        data.controller.v_pid_sat = ctrl_mat(:,2);
        data.controller.KP        = ctrl_mat(:,3);
        data.controller.KP_sat    = ctrl_mat(:,4);
        data.controller.KI        = ctrl_mat(:,5);
        data.controller.KI_sat    = ctrl_mat(:,6);
        data.controller.KD        = ctrl_mat(:,7);
        data.controller.KD_sat    = ctrl_mat(:,8);
        
    catch ME
        fprintf('\n--- EXTRACTION ERROR ---\n');
        fprintf('Check your Simulink Mux. It MUST have 8 signals to match this script.\n');
        fprintf('Error: %s\n', ME.message);
        return;
    end

 % 4. --- Storage (Split into Data and Metadata with Auto-Increment) ---
    
    % Define the trial root path (e.g., .../trial_name/)
    trial_root = fullfile(params.master_folder, params.trial_name);
    if ~exist(trial_root, 'dir'), mkdir(trial_root); end

    % Count existing folders starting with "Run_" to determine next index
    existing_dirs = dir(fullfile(trial_root, 'Run_*'));
    % Filter to ensure we only count directories
    is_dir = [existing_dirs.isdir];
    run_index = sum(is_dir); % If 0 folders exist, next is 0. If 2 exist, next is 2.

    % Create folder name with index and timestamp (e.g., Run_02_2026-03-14...)
    timestamp = datestr(now, 'yyyy-mm-dd_HHMMss');
    folder_name = sprintf('Run_%02d_%s_TimeSeries', run_index, timestamp);
    
    SAVE_PATH = fullfile(trial_root, folder_name);
    if ~exist(SAVE_PATH, 'dir'), mkdir(SAVE_PATH); end
    
    % --- FILE 1: The Raw Simulation Data ---
    save(fullfile(SAVE_PATH, 'raw_sim_data.mat'), 'data');
    
    T_all = table(data.plant_effort.time, ...
        data.plant_effort.plant_input_sat, data.plant_effort.plant_input, ...
        data.plant_effort.v_pid_out, data.plant_effort.v_compense, ...
        data.sensor.ref_rad, data.sensor.err_rad, ...
        data.sensor.sensor_measured_raw, data.sensor.sensor_noise, ...
        data.sensor.sensor_measured, ...
        data.controller.v_pid, data.controller.v_pid_sat, ...
        data.controller.KP, data.controller.KP_sat, ...
        data.controller.KI, data.controller.KI_sat, ...
        data.controller.KD, data.controller.KD_sat, ...
        'VariableNames', {'Time','plant_input_sat','plant_input','v_pid_out','v_compense',...
        'ref_rad','err_rad','sensor_measured_raw','sensor_noise','sensor_measured',...
        'v_pid','v_pid_sat','KP','KP_sat','KI','KI_sat','KD','KD_sat'});
    
    writetable(T_all, fullfile(SAVE_PATH, 'raw_sim_data.xlsx'));
    
    % --- FILE 2: The Metadata (Parameters) ---
    save(fullfile(SAVE_PATH, 'metadata.mat'), 'params');
    
    % Convert params struct to table for Excel
    T_meta = struct2table(params, 'AsArray', true);
    writetable(T_meta, fullfile(SAVE_PATH, 'metadata.xlsx'));
    
    fprintf('SUCCESS: Saved Data and Metadata in %s\n', SAVE_PATH);
end