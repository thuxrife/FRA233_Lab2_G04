%% --- Categorized Multi-Run Setup ---

% [Start, Just-Before-Jump, The-Jump, End]
% Time markers: [Start, Stall_Start, Release, Just_Before_Drop, The_Drop, End]
p_base.ref_time = [0,   0.0002,  5.0002,   10.00,   10.0002,   20]; 

% 1. Start at 180, Release at 180, then Drop to 0 at 10s
p_base.ref_data = [180, 180,    180,     180,     0,        0];

% 2. Motor Logic: [1=ON, 0=OFF]
% Motor is LOCKED from 0s to 5s, then RELEASED
p_base.moter    = [0,   0,      1,       1,       1,        1];

% Automatically set stop_time based on the last value in ref_time
p_base.stop_time     = p_base.ref_time(end); 

p_base.init          = 0;
p_base.method        = 1;
p_base.master_folder = 'lab2_part2_results';
p_base.gravity_mode  = 1;

% 2. The Multi-Category Test Matrix
% Columns: [Kp, Ki, Kd, N]
test_matrix = [
    % 0.06, 0.01, 0.00, 100;
    % 0.06, 0.05, 0.00, 100;
    0.06, 0.10, 0.00, 100;
    0.06, 0.50, 0.00, 100;
];

% Corresponding Category Labels
% Note: Using 'Ki' twice will put both Run 1 and Run 2 in the same 'Ki' folder.
categories = {'KI_test', 'KI_test'};

% 3. Automated Execution Loop
for i = 1:size(test_matrix, 1)
    p = p_base;
    
    % Extract Parameters
    p.kp = test_matrix(i, 1);
    p.ki = test_matrix(i, 2);
    p.kd = test_matrix(i, 3);
    p.N  = test_matrix(i, 4);
    
    % DYNAMIC CATEGORY NAMING
    % Structure: master_folder / Category_Name / Run_Details
    current_cat = categories{i};
    run_details = sprintf('P%.2f_I%.2f_D%.2f', p.kp, p.ki, p.kd);
    
    p.trial_name = fullfile(current_cat, run_details);
    
    fprintf('--- [%d/%d] Category: %s | Run: %s ---\n', i, length(categories), current_cat, run_details);
    
    Lab2_manual_simulate_controller(p);
    
    pause(1.1); % Ensure unique timestamps for the sub-folders
end