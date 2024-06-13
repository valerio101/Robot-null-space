classdef TorqueControllers
% TorqueControllers The class that defines all the controllers used for Cartesian control in this project
    
    properties(Constant)
        K_p = 10;
        K_d = 10;
        K_v = 10;
    end

    methods(Static)
        function [robot, u] = fullLinearizationInNullSpace(robot, curr_joint_pos, curr_joint_vel, curr_cart_pos)
            % Returns a control law that performs linearization and decoupling of the robot in the
            %  Cartesian Space, while following the provided trajectory.
            % robot: The KukaLbrRobot instance that represents the robot that this control law is applied to.
            % curr_joint_pos: The position of all the joints at the current instant (q_i).
            % curr_joint_vel: The velocity of all the joints at the current instant (q_dot_i).
            % curr_cart_pos: The position to reach in the Cartesian space at the current instant (p_des(t)).
            
            % Compute the dynamic terms in the current configuration
            [robot, M_q, c_q_qdot, g_q] = robot.get_numerical_dyn_terms();
            curr_joint_pos_cell = num2cell(curr_joint_pos);
            curr_joint_vel_cell = num2cell(curr_joint_vel);
            M_q = M_q(curr_joint_pos_cell{2:7});
            c_q_qdot = c_q_qdot(curr_joint_pos_cell{2:7}, curr_joint_vel_cell{:});
            g_q = g_q(curr_joint_pos_cell{:});

            % Compute the numeric value of the Jacobian in the current configuration (J(q))
            [robot, J_q] = robot.get_jacobian(curr_joint_pos);
            J_q = double(J_q);
            J_q_pinv = pinv(J_q);
            [robot, J_dot_q] = robot.get_j_dot(curr_joint_pos, curr_joint_vel);
            J_dot_q = double(J_dot_q);

            % Compute the direct kinematics with the actual data
            [robot, A0e] = robot.compute_direct_kinematics(curr_joint_pos);
            curr_ee_pos = A0e(1:3, 4);
            a = J_q_pinv * (TorqueControllers.K_p * (curr_cart_pos - curr_ee_pos) - J_dot_q * curr_joint_vel) - ...
                (eye(robot.num_joints) - J_q_pinv * J_q) * (TorqueControllers.K_v * curr_joint_vel);
            u = M_q*a + c_q_qdot + g_q;
            u = double(u);
        end
    end
end