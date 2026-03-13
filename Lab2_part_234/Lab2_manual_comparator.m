%% 1. Load the Data
% Update this path to the specific run folder you want to analyze
run_folder = 'Lab2_part_234\lab2_part2_results\Test_Run\Run_2026-03-12_181523_TimeSeries'; 
load(fullfile(run_folder, 'raw_sim_data.mat')); % Loads 'data' struct
load(fullfile(run_folder, 'metadata.mat'));     % Loads 'params' struct

t = data.plant_effort.time;

%% 2. Create the Analysis Figure
fig = figure('Color', 'w', 'Name', ['Analysis: ' params.trial_name]);

% --- TOP PLOT: Sensor Tracking ---
subplot(3, 1, 1);
plot(t, data.sensor.ref_rad * (180/pi), 'k--', 'LineWidth', 1.5); hold on;
plot(t, data.sensor.sensor_measured * (180/pi), 'b', 'LineWidth', 2);
grid on; ylabel('Angle (deg)');
legend('Reference', 'Actual', 'Location', 'best');
title(['PID Performance: Kp=', num2str(params.kp), ' Ki=', num2str(params.ki)]);

% --- MIDDLE PLOT: Controller Internal (P, I, D signals) ---
subplot(3, 1, 2);
plot(t, data.controller.KP_sat, 'r', 'LineWidth', 1.2); hold on;
plot(t, data.controller.KI_sat, 'g', 'LineWidth', 1.2);
plot(t, data.controller.KD_sat, 'b', 'LineWidth', 1.2);
grid on; ylabel('Term Output (V)');
legend('P-Term', 'I-Term', 'D-Term');
title('Individual Controller Contributions (Saturated)');

% --- BOTTOM PLOT: Plant Effort & Saturation ---
subplot(3, 1, 3);
plot(t, data.plant_effort.v_pid_out, 'm--', 'LineWidth', 1); hold on;
plot(t, data.plant_effort.plant_input_sat, 'k', 'LineWidth', 1.5);
yline(12, 'r:'); yline(-12, 'r:'); % Saturation limits
grid on; ylabel('Voltage (V)'); xlabel('Time (s)');
legend('Ideal PID', 'Actual Saturated', 'Sat Limit');
title('Final Output to Plant');

% Adjust layout
linkaxes(findall(fig, 'type', 'axes'), 'x'); % Sync zooming on Time axis