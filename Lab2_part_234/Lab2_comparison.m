%% --- 1. CONFIGURATION ---
clear; clc;
MASTER_FOLDER = 'lab2_part2_results'; 
angles_header = 30:30:330; 

% Requirements for Status Calculation
PO_LIMIT_VAL = 10; 
TP_LIMIT_VAL = 3.0;

% Get list of all sub-trial folders (P_tuning_1, P_tuning_2, etc.)
sub_trials = dir(fullfile(MASTER_FOLDER, 'P_tuning_*'));
sub_trials = sub_trials([sub_trials.isdir]); 

%% --- 2. DATA EXTRACTION & ERROR ANALYSIS ---
summary_data = {}; 
error_map_data = {}; % Parallel storage for error magnitudes

for i = 1:length(sub_trials)
    current_sub = sub_trials(i).name;
    sub_path = fullfile(MASTER_FOLDER, current_sub);
    runs = dir(fullfile(sub_path, 'sim_run_*'));
    runs = runs([runs.isdir]);
    
    if isempty(runs), continue; end
    
    tuning_row = struct('Tuning', current_sub, 'Kp', NaN);
    error_row = struct('Tuning', current_sub, 'Kp', NaN);
    
    for ang = angles_header
        tuning_row.(sprintf('Deg_%d', ang)) = 'MISSING';
        error_row.(sprintf('Deg_%d', ang)) = NaN;
    end
    
    for j = 1:length(runs)
        run_folder = runs(j).name;
        profile_file = fullfile(sub_path, run_folder, 'System_Profile.xlsx');
        data_file = fullfile(sub_path, run_folder, 'Data_Sheet.xlsx');
        
        if exist(profile_file, 'file') && exist(data_file, 'file')
            T_prof = readtable(profile_file); 
            T_data = readtable(data_file); % Load raw data to get final error
            
            if j == 1
                tuning_row.Kp = T_prof.Kp(1); 
                error_row.Kp = T_prof.Kp(1);
            end
            
            ang_val = T_prof.Target_Angle(1);
            col_name = sprintf('Deg_%d', ang_val);
            
            % 1. Calculate Status
            act_po = T_prof.Actual_PO(1); 
            act_tp = T_prof.Actual_Tp(1); 
            
            if act_po <= PO_LIMIT_VAL && act_tp <= TP_LIMIT_VAL
                tuning_row.(col_name) = 'PASSED';
            elseif act_po > PO_LIMIT_VAL && act_tp > TP_LIMIT_VAL
                tuning_row.(col_name) = 'BOTH';
            elseif act_po > PO_LIMIT_VAL
                tuning_row.(col_name) = 'O.P.';
            else
                tuning_row.(col_name) = 'Tp';
            end
            
            % 2. Extract Final Steady-State Error magnitude
            final_err = abs(T_data.Error_deg(end)); 
            error_row.(col_name) = final_err;
        end
    end
    summary_data{end+1} = tuning_row; %#ok<AGROW>
    error_map_data{end+1} = error_row; %#ok<AGROW>
end

% Convert and Sort by Kp Value
FinalTable = struct2table([summary_data{:}]);
ErrorTable = struct2table([error_map_data{:}]);

[~, sort_idx] = sort(FinalTable.Kp);
FinalTable = FinalTable(sort_idx, :);
ErrorTable = ErrorTable(sort_idx, :);

%% --- 3. VISUALIZATION (Pass Priority + Error Heatmap) ---
fig = figure('Name', 'P-Tuning Precision Analysis', 'Color', 'w', 'Position', [100, 100, 1450, 500]);

display_data = table2cell(FinalTable);
error_vals = table2cell(ErrorTable);

% Normalize Kp display
formatted_kps = cellfun(@(x) sprintf('%.4e', x), display_data(:,2), 'UniformOutput', false);
display_data(:,2) = formatted_kps;

uit = uitable(fig, 'Data', display_data, 'ColumnName', FinalTable.Properties.VariableNames, ...
    'Units', 'Normalized', 'Position', [0.05 0.05 0.9 0.9]);

% Apply Coloring Logic
[rows, cols] = size(display_data);
for r = 1:rows
    for c = 3:cols 
        status_val = display_data{r,c};
        err = error_vals{r,c};
        
        if strcmpi(status_val, 'MISSING') || isnan(err), continue; end
        
        % 1. Priority: If PASSED, it is Green
        if strcmpi(status_val, 'PASSED')
            addStyle(uit, uistyle('BackgroundColor', [0.7 1.0 0.7]), 'cell', [r, c]);
        
        % 2. If FAILED (Tp, O.P., or BOTH), use Error Heatmap
        else
            if err >= 0.1
                % High Error: Red
                addStyle(uit, uistyle('BackgroundColor', [1.0 0.6 0.6], 'FontWeight', 'bold'), 'cell', [r, c]);
            elseif err >= 0.01
                % Moderate Error: Orange
                addStyle(uit, uistyle('BackgroundColor', [1.0 0.8 0.4]), 'cell', [r, c]);
            else
                % Low Error but failed requirements: Yellow
                addStyle(uit, uistyle('BackgroundColor', [1.0 1.0 0.6]), 'cell', [r, c]);
            end
        end
    end
end

fprintf('Analysis Complete. Green = PASSED. Failures colored by Error Magnitude.\n');