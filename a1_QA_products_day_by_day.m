% *************************************************************************
% *     functions: calculate eF from SIF, PAR and reflectance data        *
% *     Authors:   Peiqi Yang (p.yang@njnu.edu.cn)                        *
% *     Date:      26/Dec/2024                                            *
% *     School of Geography, Nanjing Normal University                    *
% *************************************************************************
clc; clear; close all;

%% 01 define input directories
dir_input_lv1           = dir(fullfile('..', '..', '01_data', '02_processed_lv1_data', '04_SIF_R_PAR_eF_in_one'));
dir_input_lv1(ismember({dir_input_lv1.name}, {'.', '..'})) = [];     % remove . and ..

%% 02 define output directories
outdir = fullfile('..', '..', '01_data', '02_processed_lv1_data', '04_SIF_R_PAR_eF_in_one','QA_added');

%% 03 do it year by year
for year_id         =   1:length(dir_input_lv1)
    dir_input_LV2   =   [dir_input_lv1(year_id).folder,'\',dir_input_lv1(year_id).name,'\'];
    outdir_sub      =   fullfile(outdir, dir_input_lv1(year_id).name);
    if ~exist(outdir_sub, 'dir')
        mkdir(outdir_sub)
    end

    input_file_list       =   dir([dir_input_LV2,'*.mat']);              % number of days
    tic
    parfor day_id    =    1:length(input_file_list)
        input_fullpath  =   [input_file_list(day_id).folder,'\',input_file_list(day_id).name];
        temp_data       =   load(input_fullpath);
        T               =   getfield(temp_data,string(fieldnames(temp_data)));
        T.eF            =   T.eF*1e-3;              % nm-1
        Tland           =   add_quality_flag(T);
        % save the results
        out_filename        =   [outdir_sub,'\',input_file_list(day_id).name];
        parsave(out_filename , Tland)
    end
    toc
end
