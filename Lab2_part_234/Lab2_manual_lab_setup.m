%% --- Categorized Multi-Run Setup ---

% [Start, Just-Before-Jump, The-Jump, End]
p_base.ref_time = [0,  2,  2.001,  10]; 
p_base.ref_data = [0,  0,  90,     90];
% Automatically set stop_time based on the last value in ref_time
p_base.stop_time     = p_base.ref_time(end); 

p_base.init          = 0;
p_base.method        = 1;
p_base.master_folder = 'lab2_part2_results';
p_base.gravity_mode  = 1;

% 2. The Multi-Category Test Matrix
% Columns: [Kp, Ki, Kd, N]
test_matrix = [
    0.06, 0.01, 0.00, 100;  % Run 1 (Ki Category)
    0.06, 0.05, 0.00, 100;  % Run 2 (Ki Category)
];

% Corresponding Category Labels
% Note: Using 'Ki' twice will put both Run 1 and Run 2 in the same 'Ki' folder.
categories = {'KI3_aw', 'KI3_aw'};

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