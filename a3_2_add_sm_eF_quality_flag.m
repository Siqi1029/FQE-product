% =========================================================
% Generate quality flag for smooth eF
% Flag definition:
% 0 - Invalid or missing data
% 1 - Cloudy or low quality
% 2 - Good quality (recommended)
%

% *************************************************************************
% *		Authors: Siqi Shi (s.shi@utwente.nl)
% *		ITC
% *		University of Twente
% *		24-Jan-2026
% *************************************************************************

clc;
clear; close all;
% clf;
addpath(genpath('./eF_function/'))
%% ===================== Input data ===========================
tic
file_folder_sm          =   '../04_smooth_eF/iPAR_40/';
file_list_sm            =   dir(strcat(file_folder_sm,'*.mat'));
file_length_sm          =   length(file_list_sm);

file_folder             =   '../03_QA_added/raw_eF_QualityF/';
file_list               =   dir(strcat(file_folder,'*.mat'));
file_length             =   length(file_list);

out_folder              =   '../03_QA_added/sm_eF_QualityF/';
if ~exist(out_folder, 'dir')
    mkdir(out_folder)
end
% --------------------------------------------------------------
all_days                =   2131;
% ---------------------------------------------------------

for i = 827:827
    file_name_sm        =   file_list_sm(i).name;
    fprintf('Processing file %d of %d: %s\n', i, file_length_sm, file_name_sm);
    % [~, name, ~]              =   fileparts(file_name);
    data_sm             =   load(strcat(file_folder_sm, file_name_sm)).data;
    
    file_name           =   file_list(i).name;
    fprintf('Processing file %d of %d: %s\n', i, file_length, file_name);
    % [~, name, ~]              =   fileparts(file_name);
    data                =   load(strcat(file_folder, file_name)).data;
    
    % -------------------------
    % Read variables
    % -------------------------
    eF                  =   data.eF;
    pix_num             =   length(eF) ./ all_days;
    eF_pixs             =   reshape(eF, [pix_num, all_days]);
    QF_raw              =   data.QualityFlag;
    QF_raw_pixs         =   reshape(QF_raw, [pix_num, all_days]);
    eF_smooth           =   data_sm.smooth_eF;
%     eF_smooth_pixs      =   reshape(eF_smooth, [pix_num, all_days]);
    % -------------------------
    % Initialize
    % -------------------------
    QF_smooth           =   int8(2 * ones([pix_num, all_days]));   % default: good

    % -------------------------
    % 1. Invalid or missing data
    % -------------------------
    invalid_idx         =   isnan(eF_smooth) | eF_smooth < 0 | eF_smooth > 1e-4;
    QF_smooth(invalid_idx)      =   0;

    % -------------------------
    % 2. Low confidence based on observational support
    % -------------------------
    win                 =   10;              % smoothing window (e.g., ±2)
    min_ratio           =   0.5;      % minimum good-quality support

    for t = 1:all_days
        t1              =   max(1, t - floor(win/2));
        t2              =   min(all_days, t + floor(win/2));

        good_cnt        =   sum(QF_raw_pixs(:, t1:t2) == 2, 2);
        total_cnt       =   sum(QF_raw_pixs(:, t1:t2) > 0, 2);   % exclude invalid

        support_ratio   =   good_cnt ./ total_cnt;

        low_conf_idx    =   support_ratio < min_ratio & ~invalid_idx(:, t);
        QF_smooth(low_conf_idx, t) = 1;
    end
    data2               =       struct();
    % -------------------------
    % Save
    % -------------------------
    data2.eF            =       eF_pixs;
    data2.QualityFlag   =       QF_raw_pixs;
    data2.smooth_eF     =       eF_smooth;
    data2.QualityFlag_smooth_eF=       QF_smooth;
    out_name         =       strcat('eF_all_', file_name);
    parsave(strcat(out_folder,out_name) , data2);
end
