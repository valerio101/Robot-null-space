clear;
clc;
% Example script on how to use the MATLAB Robotics Toolbox for a trajectory tracking control task in joint space

%% Load the robot
robot_model = importrobot("../robot_model/kuka-lwr-4plus/model1.urdf", 'DataFormat', 'column');
n           = 7; % Number of DOFs
robot_model.Gravity = [0; 0; -9.80665];
% robot_model.Gravity = [0; 0; 0];
setFixedTransform(robot_model.Bodies{8}.Joint, eye(4));

% Define the acceleration bounds
acc_up_bound = +20;
acc_low_bound = -20;

%% Simulation parameters
simulation_time = 10;
q_0             = zeros(n, 1); % Initial configuration
q_0(4,1) = pi/2;
dq_0            = zeros(n, 1); % Initial velocity

%% Define a joint trajectory as a cubic spline from q_start to q_end with zero velocities
% q_d_start           = zeros(n, 1);
% q_d_end             = [pi/2; pi/4; -pi/3; pi/4; -3*pi/4; pi/4; -pi/8];
% syms t real
radius = 0.5;
circle_center = [0; 0; 0.4];
% u_circle_plane = [1; 0; 0];  % must be unit vec and orth to v
% v_circle_plane = [0; 1; 0];  % must be unit vec and orth to u
u_circle_plane = [sqrt(2)/2; 0; sqrt(2)/2];  % must be unit vec and orth to v
v_circle_plane = [0; sqrt(2)/2; sqrt(2)/2];  % must be unit vec and orth to u
T = simulation_time;  % trajectory duration in seconds
path = @(t) circle_center + u_circle_plane*radius*cos((t/T) * (2*pi)) + v_circle_plane*radius*sin((t/T) * (2*pi));
path_dot = @(t) -u_circle_plane*radius*(2*pi/T)*sin((t/T) * (2*pi)) + v_circle_plane*radius*(2*pi/T)*cos((t/T) * (2*pi));
path_ddot = @(t) -u_circle_plane*radius*(2*pi/T)*(2*pi/T)*cos((t/T) * (2*pi)) - v_circle_plane*radius*(2*pi/T)*(2*pi/T)*sin((t/T) * (2*pi));

%% Open the simulink model
open('model1acc.slx');

% Display the trajectory in Simscape
n = 10;
omega = linspace(0, T, n);
data_points = "[";
for i=1:n-1
    data_points = data_points + num2str(double(path(omega(i))')) + "; ";
end
data_points = data_points + "]";
set_param('model1acc/RobotModel/trajectorySpline', 'DataPoints', data_points);

%% Simulate the simulink model and store the results for plotting purposes
out = sim('model1acc.slx');
save("simulation_results", "out");

%% Plotting the results
load("simulation_results.mat");

f1 = figure; grid on; box on; hold on;
title("Configuration plot", "FontName", "courier", "FontSize", 14);
pl = plot(out.q.Time, out.q.Data, "LineWidth", 2);
pbaspect([2, 1, 1]);
xlabel("Time [s]", "Interpreter", "latex", "FontSize", 14);
ylabel("Configuration [rad]", "Interpreter", "latex", "FontSize", 14);
% pl = plot(out.q_d.Time, out.q_d.Data, "k--", "LineWidth", 2);
% set(pl, {'HandleVisibility'},  [{"on"}; repmat({"off"}, n-1, 1)]); % Keep the visibility in the legend of only one reference
legend([arrayfun(@(i) sprintf('$q_{%d}$', i), 1:n, "UniformOutput", false)'; {'$q_{d}$'}], ...
        "Interpreter", "latex", ...
       "FontSize", 14, ...
       "NumColumns", 6, ...
       "Location", "southoutside");

% Control action
f2 = figure; grid on; box on; hold on;
title("Joint Acceleration plot", "FontName", "courier", "FontSize", 14);
plot(out.tau.Time, reshape(out.tau.Data, 7, size(out.tau.Time, 1))', "LineWidth", 2);
pbaspect([2, 1, 1]);
xlabel("Time [s]", "Interpreter", "latex", "FontSize", 14);
ylabel("Joint Acceleration [$\frac{rad}{s^2}$]", "Interpreter", "latex", "FontSize", 14);
legend([arrayfun(@(i) sprintf('$\\ddot{q_{%d}}$', i), 1:n, "UniformOutput", false)'; {'$\\ddot{q_{d}}$'}], ...
        "Interpreter", "latex", ...
       "FontSize", 14, ...
       "NumColumns", 6, ...
       "Location", "southoutside");
grid on; box on;
ylim([acc_low_bound-10, acc_up_bound+10]);

% Plot cartesian error
f3 = figure; grid on; box on; hold on;
title("Cartesian Error plot", "FontName", "courier", "FontSize", 14);
plot(out.cart_err.Time, reshape(out.cart_err.Data, 3, size(out.tau.Time, 1))', "LineWidth", 2);
pbaspect([2, 1, 1]);
xlabel("Time [s]", "Interpreter", "latex", "FontSize", 14);
ylabel("Cartesian Error [m]", "Interpreter", "latex", "FontSize", 14);
legend([arrayfun(@(i) sprintf('$e_{%d}$', i), 1:n, "UniformOutput", false)'; {'$e_{d}$'}], ...
        "Interpreter", "latex", ...
       "FontSize", 14, ...
       "NumColumns", 6, ...
       "Location", "southoutside");
grid on; box on;


% Save the figures
exportgraphics(f1, "./fig/q.pdf");
exportgraphics(f2, "./fig/acc.pdf");
exportgraphics(f3, "./fig/cart_err.pdf");