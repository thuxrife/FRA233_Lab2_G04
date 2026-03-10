%% --- Define Physical Parameters ---
% Parameters from your simulation setup
kt = 50.6e-3;   % Torque constant
ke = 52.8e-3;   % Back-emf constant
Lm = 2.8544e-3; % Motor inductance
Rm = 3.3133;    % Motor resistance
bm = 77.851e-6; % Viscous friction
Jm = 58.559e-6; % Rotor inertia

%% --- Create Transfer Function ---
% The equation: Gp(s) = Kt / (s * [(Lm*s + Rm)*(Jm*s + bm) + Kt*Ke])
s = tf('s');

% Inner bracket: (Lm*s + Rm)*(Jm*s + bm)
inner_bracket = (Lm*s + Rm) * (Jm*s + bm);

% Full Denominator: s * [inner_bracket + Kt*Ke]
denominator = s * (inner_bracket + kt*ke);

% Final Plant
plant = kt / denominator;

%% --- Launch Root Locus Designer ---
% Opens the interactive GUI for tuning
controlSystemDesigner('rlocus', plant);