function j_dot = get_j_dot(block)
%     r = getGlobalRobot();
%     [r, j_dot] = r.get_j_dot();
%     setGlobalRobot(r);
% end
setup(block);
end

%% Set up the block:
function setup(block)
% Register number of input and output ports
block.NumInputPorts  = 2;
block.NumOutputPorts = 1;

block.NumDialogPrms = 1;

block.InputPort(1).Dimensions = 7;  % 7 DOF robot configuration
block.InputPort(1).DatatypeID = 0;  % double
block.InputPort(1).Complexity = 'Real';
block.InputPort(1).DirectFeedthrough = true;

block.InputPort(2).Dimensions = 7;  % 7 DOF robot configuration
block.InputPort(2).DatatypeID = 0;  % double
block.InputPort(2).Complexity = 'Real';
block.InputPort(2).DirectFeedthrough = true;

% Setup output port
block.OutputPort(1).Dimensions = [3, 7];
block.OutputPort(1).DatatypeID = 0; % double
block.OutputPort(1).Complexity = 'Real';
block.OutputPort(1).SamplingMode = 'Sample';

% Set block sample time
block.SampleTimes = [0 0];

% Register methods
block.RegBlockMethod('Outputs', @Outputs);
end

% %% Initial conditions:
% function InitConditions(block)
%     % Initialize Dwork:
%     block.ContStates.Data = block.DialogPrm(3).Data;
% end

%% Set up the output:
function Outputs(block)
    q = block.InputPort(1).Data;
    qdot = block.InputPort(2).Data;

    global robot
    [r, j_dot] = robot.get_j_dot(q, qdot);
    robot = r;
    j_dot = double(j_dot);
    
    % r = getGlobalRobot();
    % 
    % [r, j_dot] = r.get_j_dot();
    % setGlobalRobot(r);
    block.OutputPort(1).Data = j_dot;
end