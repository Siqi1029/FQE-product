% *************************************************************************
% *     Function: Read and store SIF, Reflectance, and PAR data into one file
% *     Author:   Peiqi Yang (p.yang@njnu.edu.cn)
% *     Date:     26/Dec/2024
% *     School of Geography, Nanjing Normal University
% *************************************************************************

clc; clear; close all;

land_mask_file = '..\..\01_data\01_raw_lv0_data\04_supporting_data\01_land_ocean\MCD12C1_ocean_land_0_1.mat';
X_land_mask    =  load(land_mask_file,'water_land');
land_mask      =  X_land_mask.water_land;

%% 01 - Define Input Directories
dir_SIF_lv1 = dir(fullfile('..', '..', '01_data', '02_processed_lv1_data', '01_TROPOMI_SIF', 'TROPOMI_SIF_gridded_nc_0.05dg', 'daily'));
dir_ref_lv1 = dir(fullfile('..', '..', '01_data', '01_raw_lv0_data', '02_MYD09CMG_Refl_daily'));
dir_PAR_lv1 = dir(fullfile('..', '..', '01_data', '02_processed_lv1_data', '03_MODIS_PAR', 'MODIS_PAR_1330_0.05dg'));

%% 02 - Define Output Directory
outdir = fullfile('..', '..', '01_data', '02_processed_lv1_data', '04_SIF_R_PAR_in_one');

%% 03 - Process Year by Year
dir_SIF_lv1(ismember({dir_SIF_lv1.name}, {'.', '..'})) = [];  % Remove system directories

for year_id = 1:length(dir_SIF_lv1)
    year_folder = fullfile(dir_SIF_lv1(year_id).folder, dir_SIF_lv1(year_id).name);
    outdir_sub  = fullfile(outdir, dir_SIF_lv1(year_id).name);

    if ~exist(outdir_sub, 'dir')
        mkdir(outdir_sub);
    end

    % Get all .nc files (SIF data) for this year
    SIF_file_list = dir(fullfile(year_folder, '*.nc'));

    tic;
    for month_id = 1:length(SIF_file_list)
        %% 04 - Read SIF Data (NetCDF format)
        SIF_fullpath = fullfile(SIF_file_list(month_id).folder, SIF_file_list(month_id).name);
        TROPOMI_SIF = single(ncread(SIF_fullpath, 'SIF_743'));
        TROPOMI_SIF = int16(flip(permute(TROPOMI_SIF, [3, 2, 1]), 1) * 1000);

        parts = split(SIF_file_list(month_id).name, '_');
        datePart = regexp(parts{end}, '\d{6}', 'match', 'once');
        year_str = datePart(1:4);
        month_str = datePart(5:6);
        %% 06 - Read Reflectance Data (HDF format)
        ref_file_list = dir(fullfile(dir_ref_lv1(1).folder, year_str, month_str, '*.hdf'));

        for day_id = 1:length(ref_file_list)
            day_str            =   num2str(day_id, '%02d');
            date_vector        =   datetime(str2double(year_str), str2double(month_str), day_id);
            doy                =   day(date_vector, 'dayofyear');
            doy_str            =   num2str(doy, '%03d');

            %% 05 - Read PAR Data (MAT format)
            PAR_fullpath = fullfile(dir_PAR_lv1(1).folder, year_str, ['iPAR_overpass_local_',year_str,month_str,day_str,'_',doy_str,'.mat']);
            if exist(PAR_fullpath, 'file')
                temp_PAR = load(PAR_fullpath);
                MODIS_PAR = getfield(temp_PAR, string(fieldnames(temp_PAR)));
            else
                warning('Missing PAR file: %s', PAR_fullpath);
                continue;
            end

            ref_fullpath = fullfile(ref_file_list(day_id).folder, ref_file_list(day_id).name);

            % Initialize the storage structure
            % T = zeros(size(TROPOMI_SIF, 1), size(TROPOMI_SIF, 2), 7, 'int16');
            SIF = TROPOMI_SIF(:,:,day_id);

            try
                Rblue = hdfread(ref_fullpath, 'Coarse Resolution Surface Reflectance Band 3'); % Rblue
                Rgreen = hdfread(ref_fullpath, 'Coarse Resolution Surface Reflectance Band 4'); % Rgreen
                Rred = hdfread(ref_fullpath, 'Coarse Resolution Surface Reflectance Band 1'); % Rred
                Rnir = hdfread(ref_fullpath, 'Coarse Resolution Surface Reflectance Band 2'); % Rnir
                RQA = hdfread(ref_fullpath, 'Coarse Resolution QA'); % QA
            catch
                warning('Error reading HDF file: %s', ref_fullpath);
                continue;
            end
            Tland          =    struct();
            Tland.Rblue    =    Rblue(land_mask ==1);       % 1e4 [0,1e4]
            Tland.Rgreen   =    Rgreen(land_mask ==1);      % 1e4
            Tland.Rred     =    Rred(land_mask ==1);        % 1e4
            Tland.Rnir     =    Rnir(land_mask ==1);
            Tland.RQA      =    RQA(land_mask ==1);

            %% 07 - Calculate eF, FCVI, and NDVI
            FCVI = (double(Tland.Rnir) - double(mean([Tland.Rblue,Tland.Rgreen,Tland.Rred],2, "omitnan"))) / 10000; % [0,1]
            NDVI = (double(Tland.Rnir) - double(Tland.Rred)) ./ (double(Tland.Rnir) + double(Tland.Rred)); % [0,1]
            Tland.FCVI      =   FCVI;
            Tland.NDVI      =   NDVI;

            Tland.SIF       =   double(SIF(land_mask ==1)) / 1000;  % mW/m²/sr/nm [0,3]
            Tland.PAR       =   double(MODIS_PAR);                  % W/m² [0,500]
            Tland.eF        =   Tland.SIF ./ Tland.PAR ./ Tland.FCVI;       % 1e-3 nm^-1 [0,1e-3] %or 1e-6 nm^-1

            % Tland.eF        =   int16(Tland.eF * 1e6);
            % Tland.FCVI      =   int16(Tland.FCVI * 10000);
            % Tland.NDVI      =   int16(Tland.NDVI * 10000);
            
            %% 08 - Ensure Date Matching
            date_vector = datetime(str2double(year_str), str2double(month_str), day_id);
            doy = day(date_vector, 'dayofyear');
            if ~contains(ref_file_list(day_id).name, num2str(doy), 'IgnoreCase', true)
                warning('Date mismatch: %s', ref_fullpath);
                continue;
            end

            %% 09 - Save Processed Data
            out_filename = fullfile(outdir_sub, ['eF_', year_str, month_str, day_str, '_', doy_str, '.mat']);
            save(out_filename, 'Tland', '-v7.3'); % Use '-v7.3' for large files
        end
    end
    toc;
end
