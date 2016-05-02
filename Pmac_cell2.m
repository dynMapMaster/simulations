classdef Pmac_cell2 < handle
    %PMAC2 Summary of this class goes here
    %   Detailed explanation goes here
    properties(Constant)
        max_N = 1e4;
        recency_weightning = 2000/2001;
        OCCUPIED = 1, FREE = 0;
        no_of_initial_statistics_updates = 100;
    end
    
    properties
        occupied_count, free_count;
        exit; % occupied -> free
        entry; % free -> occupied
        prev_occ_prob;
        last_entry_residue, last_exit_residue;
        last_exit_cnt, last_entry_cnt;
    end
    
    methods
        function obj = Pmac_cell2()
            obj.occupied_count = realmin('double');
            obj.free_count = realmin('double');
            obj.exit = realmin('double');
            obj.entry = realmin('double');
            obj.prev_occ_prob = 0;
            obj.occupied_count = 0;
            obj.free_count = 0;
            obj.last_entry_residue = 0;
            obj.last_exit_residue = 0;
            obj.last_exit_cnt = realmin('double');
            obj.last_entry_cnt = realmin('double');
        end
        
        function [] = update(obj,occ_prob)
            if(occ_prob > 0.5)
                occupied_prob = (occ_prob - 0.5) * 2;
                obj.occupied_count = obj.occupied_count + occupied_prob;
                % occ state
                if(obj.prev_occ_prob < 0.5)
                    obj.last_exit_residue = 0;
                    obj.last_exit_cnt = 0;
                    obj.last_entry_residue = obj.last_entry_residue / obj.last_entry_cnt;
                end
                obj.last_exit_cnt = obj.last_exit_cnt + 1;
                % start counting the exit max up
                obj.last_exit_residue = obj.last_exit_residue + occupied_prob;
                
                % increment entry event
                if(obj.last_entry_residue > 0.0)
                    next_entry_cnt = min(occupied_prob,obj.last_entry_residue);
                    obj.entry = obj.entry + next_entry_cnt;
                    obj.last_entry_residue = obj.last_entry_residue - next_entry_cnt;
                end
            else
                free_prob = (0.5 - occ_prob) * 2;
                obj.free_count = obj.free_count + free_prob;
                
                if(obj.prev_occ_prob > 0.5)
                    obj.last_entry_residue = 0;
                    obj.last_entry_cnt = 0;
                    obj.last_exit_residue = obj.last_exit_residue / obj.last_exit_cnt;
                end
                obj.last_entry_cnt = obj.last_entry_cnt + 1;
                
                obj.last_entry_residue = obj.last_entry_residue + free_prob;
                
                if(obj.last_exit_residue > 0.0)
                    next_exit_cnt = min(free_prob,obj.last_exit_residue);
                    obj.exit = obj.exit + next_exit_cnt;
                    obj.last_exit_residue = obj.last_exit_residue - next_exit_cnt;
                end
            end
            obj.prev_occ_prob = occ_prob;
        end
        
        function a = getTransitionMatrix(obj)
            lambda_entry = (obj.entry) / (obj.free_count);
            lambda_exit = (obj.exit) / (obj.occupied_count);
            
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
    end
end

