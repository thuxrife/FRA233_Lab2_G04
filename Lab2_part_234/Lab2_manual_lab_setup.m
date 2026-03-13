%% --- Multi-Run Test Matrix Setup ---

% 1. Shared Baseline (Parameters that rarely change)
p_base.ref_time = [0, 10]; 
p_base.ref_data = [180, 180];
p_base.init = 0;
p_base.method = 1;
p_base.stop_time = 10;
p_base.master_folder = 'lab2_part2_results';
p_base.gravity_mode = 1; 

% 2. The Test Matrix (Each row is a new Run)
% Columns: [Kp, Ki, Kd, N]
test_matrix = [
    0.06, 0.00, 0.00, 100;  % Run 1: Pure P-control
    0.06, 0.01, 0.00, 100;  % Run 2: PI-control (testing Ki)
    0.06, 0.01, 0.02, 100;  % Run 3: PID-control (testing Kd)
    0.06, 0.01, 0.02, 50 ;  % Run 4: PID-control (testing N/Filter)
];

% Custom names for the folders to keep them organized
trial_names = {'P_Only', 'PI_Test', 'PID_Base', 'PID_Low_N'};

% 3. Automated Execution Loop
for i = 1:size(test_matrix, 1)
    p = p_base;
    
    % Map the matrix row to the parameter struct
    p.kp = test_matrix(i, 1);
    p.ki = test_matrix(i, 2);
    p.kd = test_matrix(i, 3);
    p.N  = test_matrix(i, 4);
    p.trial_name = trial_names{i};
    
    fprintf('--- Executing Run %d: %s ---\n', i, p.trial_name);
    fprintf('Settings: Kp=%.3f, Ki=%.3f, Kd=%.3f, N=%d\n', p.kp, p.ki, p.kd, p.N);
    
    Lab2_manual_simulate_controller(p);
end

fprintf('Done. All results saved to %s\n', p_base.master_folder);