%%
clc;
clear;

fprintf('processing completed.\n');
toc
%%
%
input_folder                =   '../03_QA_added/block_monthly_mat/';

start_date                  =       datetime(2018,5,1);
end_date                    =       datetime(2024,2,29);
dates                       =       start_date : end_date;

[years, months,days]        =       ymd(dates);
yearmonth                   =       years*100 + months;
yearmonthday                =       years*10000 + months*100 + days;

unique_yearmonth            =       unique(yearmonth);
num_months                  =       numel(unique_yearmonth);

out_folder_land             =   '../03_QA_added/globe_block_monthly_mat/';
if ~exist(out_folder_land, 'dir')
    mkdir(out_folder_land)
end
out_folder_globe             =   '../03_QA_added/globe_daily_mat/';
if ~exist(out_folder_globe, 'dir')
    mkdir(out_folder_globe)
end

% ------------------------ Load land mask ------------------------ 
tmp = load('../MCD12C1_water_land_0_1.mat');
land_mask = tmp.water_land;           % [3600 x 7200]

land_idx  = find(land_mask == 1);

% ------------------------ ----------- ------------------------ 
day_idx     =   1;
for m = 1 : num_months
    % globe_ym_data_all       =       struct();
    % -----------------------------------------------------------------
    ym                      =       unique_yearmonth(m);
    % ------------- days in current month -----------------------------
    block_list              =       dir(strcat(input_folder, '*', num2str(ym), '*.mat'));
    globe_data_eF           =       cell(length(block_list), 1);
    globe_data_QF           =       cell(length(block_list), 1);
    globe_data_smeF         =       cell(length(block_list), 1);
    globe_data_QF_smeF      =       cell(length(block_list), 1);


    parfor block_id         =       1 : length(block_list)
        block_ym_name       =       block_list(block_id).name;
        block_ym_data       =       load(strcat(input_folder, block_ym_name)).data;
        globe_data_eF{block_id, 1} =       block_ym_data.eF;
        globe_data_QF{block_id, 1} =       block_ym_data.QualityFlag;
        globe_data_smeF{block_id, 1}        =       block_ym_data.smooth_eF;
        globe_data_QF_smeF{block_id, 1}     =       block_ym_data.QualityFlag_smooth_eF;
    end
    globe_eF_mat               =       cell2mat(globe_data_eF);
    globe_QF_mat               =       cell2mat(globe_data_QF);
    globe_smeF_mat             =       cell2mat(globe_data_smeF);
    globe_QF_smeF_mat          =       cell2mat(globe_data_QF_smeF);
    % ---------------------------------------------------------------------
    % globe_ym_data_all.FCVI       =       globe_FCVI_mat;
    % globe_ym_data_all.NDVI       =       globe_NDVI_mat;
    % globe_ym_data_all.SIF        =       globe_SIF_mat;
    % globe_ym_data_all.PAR        =       globe_PAR_mat;
    % globe_ym_data_all.eF         =       globe_eF_mat;
    % ---------------------------------------------------------------------
    outnameEF                   =       strcat('globe_block_eF_', num2str(ym), '.mat');
    parsave(strcat(out_folder_land, outnameEF), globe_eF_mat);
    outnameQF                  =       strcat('globe_block_QF_', num2str(ym), '.mat');
    parsave(strcat(out_folder_land, outnameQF), globe_QF_mat);
    outnameSM_eF               =       strcat('globe_block_sm_eF_', num2str(ym), '.mat');
    parsave(strcat(out_folder_land, outnameSM_eF), globe_smeF_mat);
    outnameQF_sm               =       strcat('globe_block_QF_sm_eF_', num2str(ym), '.mat');
    parsave(strcat(out_folder_land, outnameQF_sm), globe_QF_smeF_mat);
%%
curr_day_idx_start  =       day_idx;
parfor day_id          =       1 : size(globe_eF_mat,2)
    globe_data          =       struct();
    globe_eF            =       nan(size(land_mask));
    globe_QF            =       nan(size(land_mask));
    globe_SMeF          =       nan(size(land_mask));
    globe_QF_SMeF       =       nan(size(land_mask));

    globe_eF_mat_daily  =       globe_eF_mat(:,day_id);
    globe_QF_mat_daily  =       globe_QF_mat(:,day_id);
    globe_SMeF_mat_daily=       globe_smeF_mat(:,day_id);
    globe_QF_SMeF_mat_daily=       globe_QF_smeF_mat(:,day_id);

    globe_eF(land_idx)      =       globe_eF_mat_daily;
    globe_QF(land_idx)      =       globe_QF_mat_daily;
    globe_SMeF(land_idx)    =       globe_SMeF_mat_daily;
    globe_QF_SMeF(land_idx)    =       globe_QF_SMeF_mat_daily;

    globe_data.eF           =       globe_eF;
    globe_data.QualityFlag  =       globe_QF;
    globe_data.smooth_eF    =       globe_SMeF;
    globe_data.QualityFlag_smooth_eF        =       globe_QF_SMeF;

    this_run_idx            =       curr_day_idx_start + day_id - 1;

    outname_globe               =       strcat('globe_block_', num2str(yearmonthday(this_run_idx)), '.mat');
    parsave(strcat(out_folder_globe, outname_globe), globe_data);
end
day_idx             =   day_idx + size(globe_eF_mat,2);

end


