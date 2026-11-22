clc; clear; close all;

% Define paths
data_folder = fullfile('..', '..', '01_data', '02_processed_lv1_data', '04_SIF_R_PAR_eF_in_one');
save_folder = fullfile(data_folder, 'Timeseries');

if ~exist(save_folder, 'dir')
    mkdir(save_folder);
end

% Get list of input files
files       = dir(fullfile(data_folder, '**', '*.mat'));
numFiles    = length(files);  % 2131 days
numVars     = 11;
N           = 8371644;  % Total spatial pixels
chunk_size  = 50000;  % Pixels per block
num_chunks  = ceil(N / chunk_size);  % Total number of chunks (42)
clc
% === Step 1: Process each input file once === % about 24 hrs
for i = 1:numFiles  % Iterate through 2131 files
    file_path = fullfile(files(i).folder, files(i).name);
    S         = load(file_path);
    var_names = fieldnames(S.Tland);  % Get variable names
    
    % % Read full dataset from current file
    % % full_data = zeros(N, numVars, 'single');  % Temporary storage
    % % for v = 1:numVars
    %     full_data= struct2table(S.Tland);
    % % end
    % Read full dataset from current file
    full_data = zeros(N, numVars, 'single');  % Temporary storage
    for v = 1:numVars
        full_data(:, v) = S.Tland.(var_names{v})(:, 1);
    end

    % === Step 3: Distribute data into 84 output files ===
    parfor b = 1:num_chunks
        save_path = fullfile(save_folder, ['block_', num2str(b), '.mat']);
        M         = matfile(save_path, 'Writable', true);   
        start_idx = (b - 1) * chunk_size + 1;
        end_idx   = min(b * chunk_size, N);
        range     = start_idx:end_idx;        
        M.data((i-1)*length(range)+1:i*length(range), 1:numVars) = full_data(range, :);  % Save relevant portion
    end
    
end


disp('✅ Processing complete. Data saved efficiently!');
