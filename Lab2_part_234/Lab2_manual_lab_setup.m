%% --- 1. Setup Environment & Physical Parameters ---
% (ส่วนพารามิเตอร์อื่นๆ p_base... คงไว้ตามเดิม)
step_time = 0.5; 
total_time = 10.0; 
p_base.ref_time = [0, step_time, step_time + 1e-9, total_time]; 
p_base.ref_data = [0, 0, 90, 90]; 
p_base.moter    = [1, 1, 1, 1]; 
p_base.stop_time     = p_base.ref_time(end); 
p_base.init          = 0;
p_base.master_folder = 'lab2_part6_1_results'; 
p_base.gravity_mode  = 1;

% --- 2. Upgraded Test Matrix (จัดกลุ่มให้ตรวจสอบง่าย) ---
% Columns: [Kp, Ki, Kd, N, Method, Ts]
% Method: 5=Ideal/Tustin(?), 6=Forward, 7=Backward, 8=Tustin
test_matrix = [
    % Block 1: 1000 Hz (Ts = 0.001)
    % 0.06, 0.05, 0.04, 1000, 5, 0.001;
    % 0.06, 0.05, 0.04, 1000, 6, 0.001;
    % 0.06, 0.05, 0.04, 1000, 7, 0.001;
    % 0.06, 0.05, 0.04, 1000, 8, 0.001;
    
    % Block 2: 100 Hz (Ts = 0.01)
    % 0.06, 0.05, 0.04, 1000, 6, 0.01;
    % 0.06, 0.05, 0.04, 1000, 7, 0.01;
    % 0.06, 0.05, 0.04, 1000, 8, 0.01;
    
    % Block 3: 10 Hz (Ts = 0.1)
    % 0.06, 0.05, 0.04, 1000, 6, 0.1;
    % 0.06, 0.05, 0.04, 1000, 7, 0.1;
    % 0.06, 0.05, 0.04, 1000, 8, 0.1;
    
    % Block 4: 1 Hz (Ts = 1.0)
    % 0.06, 0.05, 0.04, 1000, 6, 1.0;
    % 0.06, 0.05, 0.04, 1000, 7, 1.0;
    % 0.06, 0.05, 0.04, 1000, 8, 1.0


    % Block 1: 1000 Hz (Ts = 0.001) Change PID
    % 0.06, 0.05, 0.04, 100, 5, 0.001;
    0.08, 0.05, 0.015, 100, 6, 0.001;
    0.08, 0.05, 0.015, 100, 7, 0.001;
    0.08, 0.05, 0.015, 100, 8, 0.001;
];

% ชื่อ Category (ระบุให้ชัดเจนตาม Ts และ Method)
categories = { ...
    % 'Hz1000_Ideal',
    'Hz1000_Forward',
    'Hz1000_Backward',
    'Hz1000_Tustin', ...
    % 'Hz100_Forward', 'Hz100_Backward', 'Hz100_Tustin', ...
    % 'Hz10_Forward',  'Hz10_Backward',  'Hz10_Tustin', ...
    % 'Hz1_Forward',   'Hz1_Backward',   'Hz1_Tustin' ...
};

% ตรวจสอบความผิดพลาดก่อนรัน (Safety Check)
if size(test_matrix, 1) ~= length(categories)
    error('จำนวนแถวใน test_matrix (%d) ไม่ตรงกับจำนวน categories (%d)!', ...
        size(test_matrix, 1), length(categories));
end

%% --- 3. Automated Execution Loop ---
for i = 1:size(test_matrix, 1)
    p = p_base;
    p.kp            = test_matrix(i, 1);
    p.ki            = test_matrix(i, 2);
    p.kd            = test_matrix(i, 3);
    p.N             = test_matrix(i, 4);
    p.method        = test_matrix(i, 5); 
    p.sampling_time = test_matrix(i, 6); 
    
    current_cat = categories{i};
    run_details = sprintf('M%d_Ts%.3f', p.method, p.sampling_time);
    p.trial_name = fullfile(current_cat, run_details);
    
    fprintf('--- [%d/%d] Cat: %s | Ts: %.3f ---\n', i, size(test_matrix, 1), current_cat, p.sampling_time);
    Lab2_manual_simulate_controller(p);
    pause(0.5); 
end