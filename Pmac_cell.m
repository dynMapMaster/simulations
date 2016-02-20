classdef Pmac_cell < handle
    %IMC_CELL Summary of this class goes here
    %   Detailed explanation goes here
    properties(Constant)
        max_N = 1e4;
        recency_weightning = 2000/2001;
        OCCUPIED = 1, FREE = 0;
        no_of_initial_statistics_updates = 100;
        T_MAX = 10000;
        BETA = 0.9;
    end
    
    properties
        obs_occ, obs_free;
        release; % occupied -> free
        entry; % free -> occupied
        last_obs;
        unknown_since_last_obs;
        last_prob_occ;
        last_update_t;
    end
    
    methods
        function obj = Pmac_cell(obj)
            obj.obs_occ = 0;
            obj.obs_free = 0;
            obj.release = 0;
            obj.entry = 0;
            obj.last_obs = 0;
            obj.unknown_since_last_obs = 0;
            obj.last_prob_occ = 0.5;
            obj.last_update_t = 0;
        end
        function [] = update(obj, prob_occ, t)
            if(prob_occ >= 0)
                yt = prob_occ > 0.5;
                delta_t = t - obj.last_update_t;
                alpha = obj.BETA * min([delta_t, obj.T_MAX]) / obj.T_MAX;
                prob_occ = (1-alpha)*obj.last_prob_occ + prob_occ*alpha;
                obj.last_update_t = t;
                % update estimate'                
                prob_free = (1 - prob_occ);
                if yt == 1 % occupied cell
                    obj.obs_occ = obj.obs_occ + prob_occ;
                    % change ?
                    if obj.last_obs  == 0
                        last_prob_free = 1 - obj.last_prob_occ;
                        %obj.entry = obj.entry + (last_prob_free - prob_free);
                        obj.entry = obj.entry + last_prob_free;
                    end
                else
                    obj.obs_free = obj.obs_free + prob_free;
                    % change ?
                    if obj.last_obs  == 1
                        %obj.release = obj.release + (obj.last_prob_occ - prob_occ);
                        obj.release = obj.release + obj.last_prob_occ;
                    end
                end            
                % recency weightning
%                 if yt == obj.OCCUPIED
%                     % update active state
%                     if obj.obs_occ > obj.max_N
%                         obj.release = obj.release * obj.max_N / obj.obs_occ;
%                         obj.obs_occ = obj.max_N;                        
%                     end
%                     % update inactive state
%                     obj.entry = 1 + (obj.entry - 1) * obj.recency_weightning;
%                     obj.obs_free = 1 + (obj.obs_free - 1) * obj.recency_weightning;
%                 else
%                     % update active state
%                     if obj.obs_free > obj.max_N                        
%                         obj.entry = obj.entry * obj.max_N / obj.obs_free;
%                         obj.obs_free = obj.max_N;
%                     end
%                     % update inactive state
%                     obj.release = 1 + (obj.release - 1) * obj.recency_weightning;
%                     obj.obs_occ = 1 + (obj.obs_occ - 1) * obj.recency_weightning;
%                 end

                obj.unknown_since_last_obs = 0;

                % prepare for next update
                obj.last_prob_occ = prob_occ;
                obj.last_obs = yt;
            end
        end
        
        function a = getTransitionMatrix(obj)
            lambda_entry = (obj.entry + 1) / (obj.obs_free + 1);
            lambda_exit = (obj.release + 1) / (obj.obs_occ + 1);
            
            % correct for using mobile observer
            %             if (obj.obs_free + obj.obs_occ) > obj.no_of_initial_statistics_updates
            %                 lambda_exit = sqrt(4*lambda_exit + 1) / 2 - 0.5;
            %                 lambda_entry = -(lambda_exit * lambda_entry) / (lambda_entry - lambda_exit);
            %
            %                 if lambda_exit < 0 || lambda_entry < 0
            % %                     lambda_entry = (obj.entry + 1) / (obj.obs_free + 1);
            % %                     lambda_exit = (obj.release + 1) / (obj.obs_occ + 1);
            %                     disp('underflow');
            %                 elseif lambda_exit > 1 || lambda_entry > 1
            % %                     lambda_entry = (obj.entry + 1) / (obj.obs_free + 1);
            % %                     lambda_exit = (obj.release + 1) / (obj.obs_occ + 1);
            %                     disp('overflow');
            %                 end
            %             end
            a(1:2,1:2) = [1-lambda_exit, lambda_exit; lambda_entry, 1-lambda_entry];
        end
        
        function updateProject(obj)
            obj.unknown_since_last_obs = obj.unknown_since_last_obs + 1;
        end
        
        function [est_q] = project(obj)
            if obj.last_obs == obj.FREE
                q = [1 0];
            else
                q = [0 1];
            end
            q_est = q * obj.a;
        end
        
        function [q_est] = estimateOccupancy(obj)
            a = obj.getTransitionMatrix();
            est_q = [0.5 0.5];
            for i=1:obj.unknown_since_last_obs
                est_q = q_est * a;
            end
        end
        
        function [q_est] = longOccupancy(obj)
            a = obj.getTransitionMatrix();
            q_est = 1.0 / (a(2,1) + a(1,2)) * [a(2,1)  a(1,2)];
        end
        
        function [q_est] = projectOccupancy(obj, steps)
            a = obj.getTransitionMatrix();
            q_est = 0;
            for i=1:steps
                q_est = obj.q * a;
            end
        end
    end
    
end
