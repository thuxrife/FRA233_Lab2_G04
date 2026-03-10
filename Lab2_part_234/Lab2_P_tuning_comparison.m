%% --- 1. CONFIGURATION ---
clear; clc;
MASTER_FOLDER = 'lab2_part2_results'; 
angles_header = 30:30:360; 

% Requirements for Status Calculation (Matches your 10-item Notation)
PO_LIMIT_VAL = 10; 
TP_LIMIT_VAL = 3.0;

% Get list of all sub-trial folders
sub_trials = dir(fullfile(MASTER_FOLDER, 'P_tuning*')); 
sub_trials = sub_trials([sub_trials.isdir]); 

%% --- 2. DATA EXTRACTION & ANALYSIS ---
summary_data = struct([]); 
error_map_data = struct([]); 
po_deg_map = struct([]); % Store PO in Degrees for coloring logic

for i = 1:length(sub_trials)
    current_sub = sub_trials(i).name;
    sub_path = fullfile(MASTER_FOLDER, current_sub);
    runs = dir(fullfile(sub_path, 'sim_run_*'));
    runs = runs([runs.isdir]);
    
    if isempty(runs), continue; end
    
    tuning_row = struct('Tuning', current_sub, 'Kp', NaN);
    error_row = struct('Tuning', current_sub, 'Kp', NaN);
    po_row = struct('Tuning', current_sub, 'Kp', NaN);
    
    for ang = angles_header
        col_name = sprintf('Deg_%d', ang);
        tuning_row.(col_name) = 'MISSING';
        error_row.(col_name) = NaN;
        po_row.(col_name) = NaN;
    end
    
    for j = 1:length(runs)
        run_folder = runs(j).name;
        profile_file = fullfile(sub_path, run_folder, 'System_Profile.xlsx');
        
        if exist(profile_file, 'file')
            T_prof = readtable(profile_file); 
            
            if j == 1
                tuning_row.Kp = T_prof.Kp(1); 
                error_row.Kp = T_prof.Kp(1);
                po_row.Kp = T_prof.Kp(1);
            end
            
            ang_val = T_prof.Target_Angle(1);
            col_name = sprintf('Deg_%d', ang_val);
            
            % Extract Performance Metrics
            act_po = T_prof.Actual_PO(1); 
            act_tp = T_prof.Actual_Tp(1); 
            ss_err = abs(T_prof.SS_Error(1)); 
            init_ang_val = T_prof.Init_Angle(1);
            
            % SAFETY CHECK: Handle missing 'Actual_PO_Deg' in old files
            if ismember('Actual_PO_Deg', T_prof.Properties.VariableNames)
                act_po_deg = T_prof.Actual_PO_Deg(1); 
            else
                % Calculate on the fly if the column is missing
                act_po_deg = (act_po / 100) * abs(T_prof.Steady_State(1) - init_ang_val);
            end
            
            % Status Calculation Logic (Standardized Variable Names)
            if strcmpi(T_prof.Status{1}, 'UNSTABLE')
                tuning_row.(col_name) = 'VIB';
            elseif act_po <= PO_LIMIT_VAL && act_tp <= TP_LIMIT_VAL
                tuning_row.(col_name) = 'PASSED';
            elseif act_po > PO_LIMIT_VAL && act_tp > TP_LIMIT_VAL
                tuning_row.(col_name) = 'BOTH';
            elseif act_po > PO_LIMIT_VAL
                tuning_row.(col_name) = 'O.P.';
            else
                tuning_row.(col_name) = 'Tp';
            end
            
            error_row.(col_name) = ss_err;
            po_row.(col_name) = act_po; 
        end
    end
    summary_data = [summary_data, tuning_row]; %#ok<AGROW>
    error_map_data = [error_map_data, error_row]; %#ok<AGROW>
    po_deg_map = [po_deg_map, po_row]; %#ok<AGROW>
end

% Sort Tables
FinalTable = struct2table(summary_data);
ErrorTable = struct2table(error_map_data);
POTable = struct2table(po_deg_map);
[~, sort_idx] = sort(FinalTable.Kp);
FinalTable = FinalTable(sort_idx, :);
ErrorTable = ErrorTable(sort_idx, :);
POTable = POTable(sort_idx, :);

%% --- 3. VISUALIZATION (Corrected Coloring Logic) ---
fig = figure('Name', 'Control Analysis Heatmap', 'Color', 'w', 'Position', [100, 100, 1450, 500]);
display_data = table2cell(FinalTable);
error_vals = table2cell(ErrorTable);
po_vals = table2cell(POTable);

% Formatting Kp
display_data(:,2) = cellfun(@(x) sprintf('%.9f', x), display_data(:,2), 'UniformOutput', false);

uit = uitable(fig, 'Data', display_data, 'ColumnName', FinalTable.Properties.VariableNames, ...
    'Units', 'Normalized', 'Position', [0.05 0.05 0.9 0.9]);

[rows, cols] = size(display_data);
for r = 1:rows
    for c = 3:cols 
        status_val = display_data{r,c};
        err = error_vals{r,c};
        po_act = po_vals{r,c};
        
        if strcmpi(status_val, 'MISSING'), continue; end
        
        if strcmpi(status_val, 'PASSED')
            addStyle(uit, uistyle('BackgroundColor', [0.8 1.0 0.8]), 'cell', [r, c]); % Green
            
        elseif strcmpi(status_val, 'VIB')
            addStyle(uit, uistyle('BackgroundColor', [0.3 0.3 0.3], 'FontColor', 'w'), 'cell', [r, c]); % Black
            
        else
            % PRIORITY: Severity of Overshoot (O.P. or BOTH)
            if (strcmpi(status_val, 'O.P.') || strcmpi(status_val, 'BOTH')) && po_act > 30
                % High Overshoot (like your 44.21%): Red
                addStyle(uit, uistyle('BackgroundColor', [1.0 0.6 0.6], 'FontWeight', 'bold'), 'cell', [r, c]);
            elseif (strcmpi(status_val, 'O.P.') || strcmpi(status_val, 'BOTH'))
                % Moderate Overshoot: Orange
                addStyle(uit, uistyle('BackgroundColor', [1.0 0.8 0.4]), 'cell', [r, c]);
            elseif err >= 0.1
                % High Error failures: Darker Yellow/Red
                addStyle(uit, uistyle('BackgroundColor', [1.0 0.7 0.7]), 'cell', [r, c]);
            else
                % Minor failures (Tp only) with good precision: Yellow
                addStyle(uit, uistyle('BackgroundColor', [1.0 1.0 0.7]), 'cell', [r, c]);
            end
        end
    end
end