function Lab2_manual_simulate_controller(params)
    % 1. --- Map Input Parameters ---
    % (Keeping your original mapping logic)
    kp = params.kp; ki = params.ki; kd = params.kd; N = params.N; 
    init_angle = params.init;
    method_pid = params.method; 
    gravity_compensation_mode = params.gravity_mode; 
    ref_signal = [params.ref_time(:), params.ref_data(:)];
    motor_toggle = [params.ref_time(:), params.moter(:)];

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
        
        data.plant_effort.time = sim_out.tout;
        
        % --- NEW: Sync Motor State with Simulation Time ---
        % This recreates the 0/1 signal to match the length of the other data
        data.motor_state = interp1(params.ref_time, params.moter, data.plant_effort.time, 'previous', 'extrap');
        
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
        
        % --- Controller (Indices 1-8) ---
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
        fprintf('Error: %s\n', ME.message);
        return;
    end

    % 4. --- Storage (Including Motor State in Table) ---
    trial_root = fullfile(params.master_folder, params.trial_name);
    if ~exist(trial_root, 'dir'), mkdir(trial_root); end
    
    existing_dirs = dir(fullfile(trial_root, 'Run_*'));
    run_index = sum([existing_dirs.isdir]);
    folder_name = sprintf('Run_%02d_%s_TimeSeries', run_index, datestr(now, 'yyyy-mm-dd_HHMMss'));
    
    SAVE_PATH = fullfile(trial_root, folder_name);
    if ~exist(SAVE_PATH, 'dir'), mkdir(SAVE_PATH); end

    % Save .mat file
    save(fullfile(SAVE_PATH, 'raw_sim_data.mat'), 'data');
    
    % --- Updated Table with 'Motor_Toggle' column ---
    T_all = table(data.plant_effort.time, ...
        data.motor_state, ...  % <--- NEW COLUMN
        data.plant_effort.plant_input_sat, data.plant_effort.plant_input, ...
        data.plant_effort.v_pid_out, data.plant_effort.v_compense, ...
        data.sensor.ref_rad, data.sensor.err_rad, ...
        data.sensor.sensor_measured_raw, data.sensor.sensor_noise, ...
        data.sensor.sensor_measured, ...
        data.controller.v_pid, data.controller.v_pid_sat, ...
        data.controller.KP, data.controller.KP_sat, ...
        data.controller.KI, data.controller.KI_sat, ...
        data.controller.KD, data.controller.KD_sat, ...
        'VariableNames', {'Time', 'Motor_Toggle', 'plant_input_sat', 'plant_input', ...
        'v_pid_out', 'v_compense', 'ref_rad', 'err_rad', 'sensor_measured_raw', ...
        'sensor_noise', 'sensor_measured', 'v_pid', 'v_pid_sat', 'KP', 'KP_sat', ...
        'KI', 'KI_sat', 'KD', 'KD_sat'});
    
    writetable(T_all, fullfile(SAVE_PATH, 'raw_sim_data.xlsx'));
    
    % Save Metadata
    save(fullfile(SAVE_PATH, 'metadata.mat'), 'params');
    T_meta = struct2table(params, 'AsArray', true);
    writetable(T_meta, fullfile(SAVE_PATH, 'metadata.xlsx'));
    
    fprintf('SUCCESS: Saved Data (19 signals) and Metadata in %s\n', SAVE_PATH);
end