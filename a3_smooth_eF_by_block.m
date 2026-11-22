% Edited by Siqi Shi for smoothing data with multiply variables
% *************************************************************************
% *		Authors: Siqi Shi (s.shi@utwente.nl)
% *		ITC
% *		University of Twente
% *		05-March-2025
% *************************************************************************

clc;
clear; close all;
% clf;
addpath(genpath('./eF_function/'))
%% ===================== Input data ===========================
tic
file_folder         =   '../03_QA_added/2/';
file_list           =   dir(strcat(file_folder,'*.mat'));
file_length         =   length(file_list);

out_folder          =   '../04_smooth_eF/1/';
if ~exist(out_folder, 'dir')
    mkdir(out_folder)
end
%%
Vars                =   {'Rblue', 'Rgreen', 'Rred', 'Rnir', 'RQA', 'FCVI', 'NDVI', 'SIF', 'PAR', 'eF', 'QualityFlag'};
% smooth_Vars         =   {'Rblue', 'Rgreen', 'Rred', 'Rnir', 'RQA', 'smooth_FCVI', 'smooth_NDVI', 'smooth_SIF', 'smooth_PAR', 'smooth_eF', 'QualityFlag'};

all_days            =   2131;
QA_id               =   find(strcmp(Vars, 'QualityFlag'));
% Define the converg_thresold for each variable, which need to be used in
% interative SG filter (see IteraSG function in smooth_IteraSG function)
% converg_thres       =   [1, 1, 1, 1, 0, 0.01, 0.01, 0.01, 10, 0.00001];
% Define the quality flag bits for each variable 
% QA_flag_bit         =   [2, 2, 2, 2, 0, 6, 5, 3, 4, 7];
% 2, reflectance_flag   % Second bit for reflectance quality
% 3, SIF_flag
% 4, PAR_flag
% 5, NDVI_flag
% 6, FCVI_flag
% 7, eF_flag

%%
parfor i = 1:file_length
    %%
        converg_thres       =   [1, 1, 1, 1, 0, 0.01, 0.01, 0.01, 1, 5*1e-5];
        QA_flag_bit         =   [2, 2, 2, 2, 0, 6, 5, 3, 4, 7];
        smooth_Vars         =   {'Rblue', 'Rgreen', 'Rred', 'Rnir', 'RQA', 'smooth_FCVI', 'smooth_NDVI', 'smooth_SIF', 'smooth_PAR', 'smooth_eF', 'QualityFlag'};

        smooth_data         =   struct();
%     try
        file_name                   =       file_list(i).name;
        fprintf('Processing file %d of %d: %s\n', i, file_length, file_name);
        % [~, name, ~]            =   fileparts(file_name);
        data                        =       load(strcat(file_folder, file_name)).data;

%         smooth_data                 =       nan(size(data));    % Initialize an array for smoothed data

        % ---------- Process each variable (excluding QualityFlag) --------
        for Vars_id                 =       10 : length(Vars) - 1 % the last one is QualityFlag
%             try
                data_var            =       data.(Vars{Vars_id}); % Extract the variable's data
                
                pix_num             =       length(data_var) ./ all_days;
                data_var_pixs       =       reshape(data_var, [pix_num, all_days]); % Reshape data into time series per pixel
                data_QA             =       data.QualityFlag;                          % Extract the QualityFlag column
                data_QA_pixs        =       reshape(data_QA, [pix_num, all_days]);  % to match the size of "data_var_pixs"
                QA_int              =       int16(data_QA_pixs);                    % Convert the quality flag data to integer type for bitwise operations
                QA_flag_st_idx      =       QA_flag_bit(Vars_id);                    % Get the corresponding quality flag bit for the variable
                % ---------------------------------------------------------
                RQA                 =       int16(data.RQA);
                RQA_pixs            =       reshape(RQA, [pix_num, all_days]);
%                 cloud_bits          =       bitget(RQA_pixs, 1) + bitget(RQA_pixs, 2) * 2;
                cloud_bits          =       bitget(RQA_pixs, 2) + bitget(RQA_pixs, 3) + bitget(RQA_pixs, 4) + bitget(RQA_pixs, 6);
                % ---------------------------------------------------------
                bad_quality_idx     =       find(bitget(QA_int, QA_flag_st_idx) == 0 | cloud_bits ~= 4);
                data_var_pixs(bad_quality_idx)  =   nan;
                % ---------------------------------------------------------
                smooth_data_pixs    =       cell(size(data_var_pixs,1),1);          % using a cell array for use in parfor

                % Parallel loop for processing time series data for each pixel
                for pix_id           =       1 : size(data_var_pixs, 1)
                    data_var_1_pix      =       data_var_pixs(pix_id,:); 
                    data_var_1_pix(data_var_1_pix<=0)     =       nan;
                    smooth_data_pixs{pix_id,1}            =       smooth_LUE_SG(data_var_1_pix, converg_thres(Vars_id));
                end
% %             catch ME
% %                 warning('Processing failed for variable %s in file %s. Error: %s', Vars{Vars_id}, file_name, ME.message);
% %             end
            smooth_data_vars                    =       cell2mat(smooth_data_pixs);
            smooth_data.(smooth_Vars{Vars_id})         =       smooth_data_vars;

        end
%         smooth_data(:,Vars_id)            =       smooth_data_vars;
        outname                             =       strcat(out_folder, 'smooth_eF', file_name);
        parsave(outname, smooth_data);
%     catch ME
%         warning('Failed to load file: %s. Error: %s', file_name, ME.message);
%         continue
%     end
end
fprintf('processing completed.\n');
toc
%%
function parsave(filename, data)
    save(filename, 'data', '-v7.3');
end
