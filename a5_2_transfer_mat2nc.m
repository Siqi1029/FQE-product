% Edited by Siqi Shi
% *************************************************************************
% *		Authors: Siqi Shi (s.shi@utwente.nl)
% *		ITC
% *		University of Twente
% *		28-Jan-2026
% *************************************************************************

clc;
clear; close all;
% clf;

%% =========================== Input data =================================
% input_path          =   '../03_QA_added/globe_daily_mat/';
% file_list           =   dir(strcat(file_folder,'*.mat'));
% file_length         =   length(file_list);
%
% out_folder_globe    =   '../03_QA_added/globe_daily_nc/';
% if ~exist(out_folder_globe, 'dir')
%     mkdir(out_folder_globe)
% end

input_path          =   '../../A_data_publicaton/eF_product/';
file_list           =   dir(strcat(input_path,'*.mat'));
file_length         =   length(file_list);

out_folder_globe    =   '../../A_data_publicaton/globe_daily_nc/';
if ~exist(out_folder_globe, 'dir')
    mkdir(out_folder_globe)
end
%% 2. Define Global Coordinates (0.05 degree resolution)
% 3600 rows (lat), 7200 cols (lon)
res     =   0.05;
lat     =   90 - res/2 : -res : -90 + res/2;       % 3600 elements
lon     =   -180 + res/2 : res : 180 - res/2;      % 7200 elements
n_lat   =   length(lat);
n_lon   =   length(lon);
%% ========================================================================
parfor i = 1 : file_length
    file_name               =       file_list(i).name;
    fprintf('Processing file %d of %d: %s\n', i, file_length, file_name);
    data                    =       load(strcat(input_path, file_name));
    data                    =       data.data;
    eF                      =       data.eF;
    eF                      =       eF .* pi;
    QualityFlag             =       data.QualityFlag;
    eF_smooth               =       data.smooth_eF;
    eF_smooth               =       eF_smooth .* pi;
    QualityFlag_smooth_eF       =       data.QualityFlag_smooth_eF;

    [~, name_core, ~]       =       fileparts(file_name);
    split_parts             =       strsplit(name_core, '_');
    date_str                =       split_parts{end};
    out_name                =       strcat('Globe_eF_', date_str, '.nc');
    out_full_path           =       fullfile(out_folder_globe, out_name);

    %% --- Create NetCDF Schema ---
    % Define Dimensions
    nccreate(out_full_path, 'lat', 'Dimensions', {'lat', n_lat}, 'Datatype', 'single');
    nccreate(out_full_path, 'lon', 'Dimensions', {'lon', n_lon}, 'Datatype', 'single');

    nccreate(out_full_path, 'eF', ...
        'Dimensions', {'lat', n_lat, 'lon', n_lon}, ...
        'Datatype', 'single', ...
        'DeflateLevel', 5, ...
        'FillValue', -9999);

    % 2. Define Variable: smooth_eF (if exists)
    nccreate(out_full_path, 'smooth_eF', ...
        'Dimensions', {'lat', n_lat, 'lon', n_lon}, ...
        'Datatype', 'single', ...
        'DeflateLevel', 5, ...
        'FillValue', -9999);

    % 3. Define Variable: Quality Flag
    nccreate(out_full_path, 'QualityFlag', ...
        'Dimensions', {'lat', n_lat, 'lon', n_lon}, ...
        'Datatype', 'int8', ...
        'DeflateLevel', 5);

    % 4. Define Variable: Quality Flag smooth eF
    nccreate(out_full_path, 'QualityFlag_smooth_eF', ...
        'Dimensions', {'lat', n_lat, 'lon', n_lon}, ...
        'Datatype', 'int8', ...
        'DeflateLevel', 5);
    %% --- Write Data to NetCDF ---
    % Write Coordinates
    ncwrite(out_full_path, 'lat', lat(:));
    ncwrite(out_full_path, 'lon', lon(:));

    % Write eF (Handle NaNs)
    eF_temp                 =   single(eF);           % Convert to single precision
    eF_temp(isnan(eF_temp)) =   -9999; % Replace NaNs with FillValue
    ncwrite(out_full_path, 'eF', eF_temp);
    % clear eF_temp; % Free memory

    sm_temp                 =   single(eF_smooth);
    sm_temp(isnan(sm_temp)) =   -9999;
    ncwrite(out_full_path, 'smooth_eF', sm_temp);
    % clear sm_temp;

    QF_temp                 =   int8(QualityFlag);
    ncwrite(out_full_path, 'QualityFlag', QF_temp);
    % clear QF_temp;

    QF_smeF_temp            =   int8(QualityFlag_smooth_eF);
    ncwrite(out_full_path, 'QualityFlag_smooth_eF', QF_smeF_temp);
    % clear QF_smeF_temp;

    %% --- Write Metadata (Attributes) ---
    % Coordinate attributes
    ncwriteatt(out_full_path, 'lat', 'units', 'degrees_north');
    ncwriteatt(out_full_path, 'lat', 'standard_name', 'latitude');
    ncwriteatt(out_full_path, 'lon', 'units', 'degrees_east');
    ncwriteatt(out_full_path, 'lon', 'standard_name', 'longitude');
    
    % Variable attributes
    ncwriteatt(out_full_path, 'eF', 'long_name', 'Vegetation fluorescence emission efficiency');
    ncwriteatt(out_full_path, 'eF', 'units', '1/nm');
    ncwriteatt(out_full_path, 'eF', 'missing_value', -9999);
    ncwriteatt(out_full_path, 'smooth_eF', 'long_name', 'Smoothed vegetation fluorescence emission efficiency');
    ncwriteatt(out_full_path, 'smooth_eF', 'units', '1/nm');
    ncwriteatt(out_full_path, 'smooth_eF', 'missing_value', -9999);

    ncwriteatt(out_full_path, 'QualityFlag', 'long_name', 'Quality Flag');
    ncwriteatt(out_full_path, 'QualityFlag', 'flag_values', int8([0 1 2]));
    ncwriteatt(out_full_path, 'QualityFlag', 'flag_meanings', ...
                'invalid_or_missing_data cloudy_or_low_quality good_quality');


    ncwriteatt(out_full_path, 'QualityFlag_smooth_eF', 'long_name', 'Quality flag for smoothed vegetation fluorescence emission efficiency');
    ncwriteatt(out_full_path, 'QualityFlag_smooth_eF', 'flag_values', int8([0 1 2]));

    ncwriteatt(out_full_path, 'QualityFlag_smooth_eF', 'flag_meanings', ...
                'invalid_or_missing_data cloudy_or_low_quality good_quality');
    % Global attributes (Optional)
    ncwriteatt(out_full_path, '/', 'Creation_Date', char(datetime('today')));

    fprintf('Saved successfully: %s\n', out_name);
end

