%% --- 1. คืนค่าพารามิเตอร์พื้นฐาน (Physical Parameters) ---
p_base.L = 0.1; p_base.mp = 0.05; p_base.g = 9.81;
p_base.kt = 50.6e-3; p_base.ke = 52.8e-3;
p_base.Lm = 2.8544e-3; p_base.Rm = 3.3133;
p_base.bm = 77.851e-6; p_base.Jm = 58.559e-6;
J_total = p_base.Jm + p_base.mp * p_base.L^2;
b_m = p_base.bm;
mgl = p_base.mp * p_base.g * p_base.L;
Kt = p_base.kt; Ke = p_base.ke; Rm = p_base.Rm;

s = tf('s');
G = Kt / ( (Rm * (J_total*s^2 + b_m*s + mgl)) + (Kt*Ke*s) );

%% --- 2. นิยาม Controller แต่ละประเภท (ไม่รวม Gain หลัก) ---
% เราจะแยก Gain (k) ออกเพื่อให้คำสั่ง rlocus คำนวณเส้นทางวิ่งได้
C_p_base   = 1;
C_pi_base  = (s + 0.4)/s;     % ตัวอย่าง Zero ที่ -Ki/Kp = -0.4
C_pd_base  = (0.03*s + 1);    % ตัวอย่าง Zero จาก Kd/Kp
C_pid_base = (0.15*s^2 + s + 0.2)/s; % PID Form

% กำหนดค่า Gain ที่จะจุดตำแหน่ง Current Poles (x)
Kp_val = 6.0;

%% --- 3. เริ่มการ Plot Root Locus Path แยกตาม Case ---
figure('Name', 'Root Locus Path Comparison', 'Color', 'w', 'Position', [100 100 1000 700]);
hold on; grid on;

% รายชื่อเคส สี และ Controller
% cases = {C_p_base, C_pi_base, C_pd_base, C_pid_base};
% colors = {'b', 'g', 'm', 'r'};
% names = {'P', 'PI', 'PD', 'PID'};


cases = {C_p_base, C_pi_base};
colors = {'b', 'g'};
names = {PD'};
for i = 1:length(cases)
    % ระบบ Open-loop ของแต่ละเคส (C * G)
    L = cases{i} * G;
    
    % พลอตเส้น Path ของ Root Locus
    [r, k] = rlocus(L);
    plot(real(r'), imag(r'), 'Color', colors{i}, 'LineWidth', 1.2, ...
        'HandleVisibility', 'off'); % ซ่อนเส้น Path ใน Legend ไม่ให้รก
    
    % พลอตจุด Current Poles (x) ณ ค่า Kp_val
    sys_cl = feedback(Kp_val * L, 1);
    p = pole(sys_cl);
    plot(real(p), imag(p), [colors{i} 'x'], 'MarkerSize', 12, 'LineWidth', 2.5, ...
        'DisplayName', ['Current Poles (', names{i}, ')']);
    
    % พลอต Open-loop Zeros (o) ของ Controller นั้นๆ
    z = zero(L);
    if ~isempty(z)
        plot(real(z), imag(z), [colors{i} 'o'], 'MarkerSize', 8, 'LineWidth', 1.5, ...
            'HandleVisibility', 'off');
    end
end

% พลอต Open-loop Poles เริ่มต้นของ Plant (k+)
ol_p = pole(G);
plot(real(ol_p), imag(ol_p), 'k+', 'MarkerSize', 10, 'LineWidth', 2, 'DisplayName', 'Plant OL-Poles');

% ตกแต่งแกน
title('Root Locus Path & Poles Comparison (P, PI, PD, PID)', 'FontSize', 12);
xlabel('Real Axis (seconds^{-1})'); ylabel('Imaginary Axis (seconds^{-1})');
legend('Location', 'bestoutside');

% Zoom Out เพื่อให้เห็นภาพกว้างของ Path
axis auto; axis tight;
curr = axis;
axis([curr(1)-20, 10, curr(3)-10, curr(4)+10]);