demrez='100';
REG='-R-353000/-311000/303000/353000';

data=load('../data/is2/atl06.003/Foundation_12.is2.xyzt');

tracks=unique(data(:,6));
dz=[];

for t=1:length(tracks)
    thistrack=tracks(t);
    i_dem=logical(data(:,6)~=thistrack);
    i_val=logical(data(:,6)==thistrack);
    
    disp(['writing data for track ' num2str(t) ' of ' num2str(length(tracks))])
    data_dem=data(i_dem,:);
    data_val=data(i_val,:);
    
    dlmwrite('tmp_dem',data_dem(:,1:3),'precision','%10.10f','delimiter',',')
    dlmwrite('tmp_val',data_val(:,1:3),'precision','%10.10f','delimiter',',')
    
    system(['gmt blockmean tmp_dem ' REG ' -I' demrez ' -i0,1,2 > mean.xyz']);
    system(['gmt surface ' REG ' -I' demrez ' mean.xyz -Gtmp.nc -T0.7 -V'])
    system('gmt grdtrack -Gtmp.nc tmp_val > load_me');
    
    valdata=load('load_me');
    system('rm tmp_val tmp_dem mean.xyz load_me tmp.nc gmt.history');
    dz=[dz;valdata(:,3)-valdata(:,4) valdata(:,1)*0+thistrack];
end
    
disp('dem generation has...')
disp(['bias: ' num2str(mean(dz(:,1)))])
disp(['std:  ' num2str(std(dz(:,1)))]);