function calc_is2_anomalies(lake_fold,is2subset_fold,is2err,demerr)

err_sing_shot=sqrt(is2err.^2+demerr.^2);

% loop through each lake
lakes=dir([lake_fold '/*.xy']);
ts=2018+9.5/12:1/12:2020+5.5/12;

for i=1:length(lakes)
    thisfile=[lakes(i).folder '/' lakes(i).name];
    outline=load(thisfile);
    outline_poly=polyshape(outline(:,1:2));
    
    [~,lakename,~]=fileparts(lakes(i).name);
    disp(['calculating time series for ' lakename])
    is2datafile=[is2subset_fold '/' lakename '.is2.xyztz'];
    is2data=load(is2datafile);
    
    h_lake=nan(length(ts),6);
    for idx=1:length(ts)
        d=ts(idx);
        disp(['......' num2str(d)]);
        i_data=logical(is2data(:,4)>=d-1.5/12 & is2data(:,4)<d+1.5/12);
        datasub=[is2data(i_data,1),is2data(i_data,2),...
            is2data(i_data,3)-is2data(i_data,end)];
        
        in_lake=outline_poly.isinterior(datasub(:,1),datasub(:,2));
        n_inlake=sum(in_lake);
        n_outlake=sum(~in_lake);
        
        err_inlake=err_sing_shot/n_inlake;
        err_outlake=err_sing_shot/n_outlake;
        h_err=sqrt(err_inlake.^2+err_outlake.^2);
        
        h_lake(idx,1)=d;
        h_lake(idx,2)=mean(datasub(in_lake,3));
        h_lake(idx,3)=mean(datasub(~in_lake,3));
        h_lake(idx,4)=h_err;
        h_lake(idx,5)=n_inlake;
        h_lake(idx,6)=n_outlake;
    end
    dlmwrite([is2subset_fold '/' lakename '_is2_dz.dat'],h_lake,...
        'precision','%10.10f','delimiter',',')
end

% 
% % now save the grids by region
% 
% % mis/wis first
% regname='miswis';
% xyz1=load([is2subset_fold '/SubglacialLakeMercer.is2.xyztz']);
% xyz2=load([is2subset_fold '/SubglacialLakeConway.is2.xyztz']);
% for idx=1:length(ts)
%     filename=[is2subset_fold '/grids_' regname '/' ...
%         regname '_' sprintf('%02d',idx) '_' num2str(floor(ts(idx))) ...
%         sprintf('%02i',uint8((ts(idx)-floor(ts(idx)))*12-0.5)) ...
%         '.xyz'];
%     disp(filename)
%     d=ts(idx);
%     ic1=logical(xyz1(:,4)>=d-1.5/12 & xyz1(:,4)<d+1.5/12);
%     ic2=logical(xyz2(:,4)>=d-1.5/12 & xyz2(:,4)<d+1.5/12);
% 
%     datasub1=[xyz1(ic1,1) xyz1(ic1,2) xyz1(ic1,3)-xyz1(ic1,end)];
%     datasub2=[xyz2(ic2,1) xyz2(ic2,2) xyz2(ic2,3)-xyz2(ic2,end)];
%     dlmwrite(filename,unique([datasub1;datasub2],'rows'),'precision','%10.10f','delimiter',' ')
% end
% 
% %mac second
% regname='mac';
% xyz1=load([is2subset_fold '/Mac1.is2.xyztz']);
% xyz2=load([is2subset_fold '/Mac2.is2.xyztz']);
% xyz3=load([is2subset_fold '/Mac3.is2.xyztz']);
% for idx=1:length(ts)
%     filename=[is2subset_fold '/grids_' regname '/' ...
%         regname '_' sprintf('%02d',idx) '_' num2str(floor(ts(idx))) ...
%         sprintf('%02i',uint8((ts(idx)-floor(ts(idx)))*12-0.5)) ...
%         '.xyz'];
%     disp(filename)
%     d=ts(idx);
%     ic1=logical(xyz1(:,4)>=d-1.5/12 & xyz1(:,4)<d+1.5/12);
%     ic2=logical(xyz2(:,4)>=d-1.5/12 & xyz2(:,4)<d+1.5/12);
%     ic3=logical(xyz3(:,4)>=d-1.5/12 & xyz3(:,4)<d+1.5/12);
% 
%     datasub1=[xyz1(ic1,1) xyz1(ic1,2) xyz1(ic1,3)-xyz1(ic1,end)];
%     datasub2=[xyz2(ic2,1) xyz2(ic2,2) xyz2(ic2,3)-xyz2(ic2,end)];
%     datasub3=[xyz3(ic3,1) xyz3(ic3,2) xyz3(ic3,3)-xyz3(ic3,end)];
%     dlmwrite(filename,unique([datasub1;datasub2;datasub3],'rows'),'precision','%10.10f','delimiter',' ')
% end
% 
% % academy third
% regname='ag';
% xyz1=load([is2subset_fold '/Foundation_11.is2.xyztz']);
% xyz2=load([is2subset_fold '/Foundation_12.is2.xyztz']);
% xyz3=load([is2subset_fold '/Foundation_13.is2.xyztz']);
% for idx=1:length(ts)
%     filename=[is2subset_fold '/grids_' regname '/' ...
%         regname '_' sprintf('%02d',idx) '_' num2str(floor(ts(idx))) ...
%         sprintf('%02i',uint8((ts(idx)-floor(ts(idx)))*12-0.5)) ...
%         '.xyz'];
%     disp(filename)
%     d=ts(idx);
%     ic1=logical(xyz1(:,4)>=d-1.5/12 & xyz1(:,4)<d+1.5/12);
%     ic2=logical(xyz2(:,4)>=d-1.5/12 & xyz2(:,4)<d+1.5/12);
%     ic3=logical(xyz3(:,4)>=d-1.5/12 & xyz3(:,4)<d+1.5/12);
% 
%     datasub1=[xyz1(ic1,1) xyz1(ic1,2) xyz1(ic1,3)-xyz1(ic1,end)];
%     datasub2=[xyz2(ic2,1) xyz2(ic2,2) xyz2(ic2,3)-xyz2(ic2,end)];
%     datasub3=[xyz3(ic3,1) xyz3(ic3,2) xyz3(ic3,3)-xyz3(ic3,end)];
%     dlmwrite(filename,unique([datasub1;datasub2;datasub3],'rows'),'precision','%10.10f','delimiter',' ')
% end

end

