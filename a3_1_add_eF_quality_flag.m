% =========================================================
% Generate quality flag for eF product
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
file_folder         =   '../03_QA_added/2/';
file_list           =   dir(strcat(file_folder,'*.mat'));
file_length         =   length(file_list);

out_folder          =   '../03_QA_added/raw_eF_QualityF/';
if ~exist(out_folder, 'dir')
    mkdir(out_folder)
end
parfor i = 1:file_length
    %%
    QA_flag_bit         =   [2, 2, 2, 2, 0, 6, 5, 3, 4, 7];
    %     try
    file_name                   =       file_list(i).name;
    fprintf('Processing file %d of %d: %s\n', i, file_length, file_name);
    % [~, name, ~]            =   fileparts(file_name);
    data                        =       load(strcat(file_folder, file_name)).data;
    % -------------------------
    % Read variables
    % -------------------------
    eF              =       data.eF;        % double, [pix_num × all_days]
    RQA             =       int16(data.RQA);
    FCVI            =       data.FCVI;

    % -------------------------
    % Initialize flag
    % -------------------------
    QualityFlag              =       int8(2 * ones(size(eF)));   % default = good quality (2)

    % -------------------------
    % 1. Invalid or missing data
    % -------------------------
    invalid_idx     =       isnan(eF) | eF < 0 | eF > 1e-4;
    QualityFlag(invalid_idx) =       0;

    % -------------------------
    % 2. Cloudy or low quality
    % (only applied to valid eF pixels)
    % -------------------------
    cloud_bits = ...
        bitget(RQA, 2) ...
        + bitget(RQA, 3) ...
        + bitget(RQA, 4) ...
        + bitget(RQA, 6);

    cloudy_idx      =       cloud_bits ~= 4;
    low_FCVI_idx    =       FCVI<=0.05;
    % Apply cloudy flag only where not already invalid
    QualityFlag(cloudy_idx & ~invalid_idx)  =   1;
    QualityFlag(low_FCVI_idx)               =   1;

    data2           =       struct();

    % -------------------------
    % Save to struct
    % -------------------------
    data2.eF         =       eF;
    data2.QualityFlag=       QualityFlag;
    out_name         =       strcat('eF_QF_', file_name);
    parsave(strcat(out_folder,out_name) , data2);
end
