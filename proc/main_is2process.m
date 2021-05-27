%%% Code to pre-process ICESat-2 data f
%%% for Siegfried & Fricker, in review, GRL

% add helper_functions folder to your path
addpath('helper_functions')

%%%% set all the directory information
% Folder where ATL06 dataset is mirrored
atl06_fold='/Volumes/moulin/data/altimetry/icesat2/ATL06.003';
% folder of x,y,track points for each day of ICESat-2
% This is generated with `run_trackmap_antarctica.m`
trackmap_fold='~/Documents/data/ICESat2/trackmap/antarctica';
% lake outline folder
lake_fold='../data/outlines/xy';
% Location we will save subglacial lake ATL06 file lists
filelist_fold='../data/is2/filelists';
% Locationo we will save ATL06 subsets for each lake
is2subset_fold='../data/is2/atl06.003';

%%%% set all the global variables
% Distance around lake to calculate off-lake correction
buffersize=10000; % in m
demrez=100; % ad hoc DEM resolution in meters
is2err=0.09; % from Brunt et al., 2019
demerr=0.163; % calculated with calc_dem_uncertainty (value for F12)

%%% Time to process
%% (1) Save file lists for the tracks that cover each lake
run_make_filelists(atl06_fold,trackmap_fold,lake_fold,...
    buffersize,filelist_fold)

%% (2) Go through each file list and subset ICESat-2 data
%%%    to the lake outline +/- buffer
subset_is2_lakes(lake_fold,filelist_fold,...
    buffersize,is2subset_fold)

%% (3) Dump the data to an ascii text file
dump_all_is2_lake_data(is2subset_fold);

%% (4) make a DEM with GMT and interpolate to each ICESat-2 point
system(['helper_functions/makeIS2dem.sh ' is2subset_fold ' ' num2str(demrez)])

%% (5) calculate the lake anomaly and save grids
calc_is2_anomalies(lake_fold,is2subset_fold,is2err,demerr)
