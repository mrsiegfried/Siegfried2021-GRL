function run_make_filelists(atl06_fold,trackmap_fold,lake_fold,buffersize,save_fold)

% Start processing by looping through all lake outlines
lakes=dir([lake_fold '/*.xy']);

parpool(12);
parfor i=1:length(lakes)
    thisfile=[lakes(i).folder '/' lakes(i).name];
    [~,lake_name,~]=fileparts(thisfile);
    thisoutline=load(thisfile);
    
    disp(['working on ' lake_name]);
    
    thispoly=polybuffer(thisoutline(:,1:2),'points',buffersize);
    savefile=[save_fold '/' lake_name '.mat'];
    save_is2_track_list(atl06_fold,trackmap_fold,thispoly,savefile);
end
delete(gcp('nocreate'));

end
