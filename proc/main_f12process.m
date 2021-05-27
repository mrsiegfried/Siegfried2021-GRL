gmt='/usr/local/bin/gmt';
% do a plane fit algo to get dz using icesat + icesat2 for track 0096
outline=load('../data/outlines/xy/Foundation_12.xy');
o_poly=polyshape(outline(:,1:2));
poly=polybuffer(o_poly,10000);

% dump data into new structure not separated by campaign
files=dir('../data/is/*0096.91day.mat');
thisfile=[files(1).folder '/' files(1).name];
tmpdata=load(thisfile);
fn=fieldnames(tmpdata);
thisdata=tmpdata.(fn{1}); clear tmpdata
    
camps=fieldnames(thisdata);

% calculate how many datapoints are on the track so we can dump it all
% into a new structure not separated by campaign
totallen=0;
for c=1:length(camps)
    thiscamp=camps{c};
    if strcmp(thiscamp(1),'L')
        totallen=totallen+length(thisdata.(camps{c}).x);
    end
end

% now dump the data into a new structure
datadump=struct();
sz=size(thisdata.(camps{1}).x);
goodlen=sz(1);
flds=fieldnames(thisdata.(camps{1}));
for i=1:length(flds)
    thisfield=flds{i};
    thissz=size(thisdata.(camps{1}).(thisfield));
    if goodlen==thissz(1)
        datadump.(thisfield)=nan(totallen,1);
    end
end
datadump.campnum=nan(totallen,1); % keep track of campaign number so we can reseparate

firsti=0;
dumpfields=fieldnames(datadump);
for c=1:length(camps)
	thiscamp=camps{c};
    if strcmp(thiscamp(1),'L')
        thislen=length(thisdata.(camps{c}).x);
        for df=1:length(dumpfields)
            thisfield=dumpfields{df};
            if ~strcmp(thisfield,'campnum')
                datadump.(thisfield)(firsti+1:firsti+thislen)=thisdata.(camps{c}).(thisfield);
            else
                datadump.(thisfield)(firsti+1:firsti+thislen)=thisdata.(camps{c}).x*0+c;
            end
        end
        firsti=firsti+thislen;
    end
end

idx=poly.isinterior(datadump.x,datadump.y);
flds=fieldnames(datadump);
for f=1:length(flds)
    datadump.(flds{f})=datadump.(flds{f})(idx);
end

%% intepolate the ICESat-2 DEM using the L2A location on the reference track
il2a=logical(datadump.campnum==1 & poly.isinterior(datadump.x,datadump.y));
l2aref=[datadump.x_proj(il2a) datadump.y_proj(il2a)];
dlmwrite('is_reftrack.xy',l2aref,'precision','%10.10f','delimiter',',')
dem='../data/is2/atl06.003/Foundation_12_dem.nofilt.nc';
system([gmt ' grdtrack -G' dem ' is_reftrack.xy > is2_t0096.xyz']);
zhat_is2=load('is2_t0096.xyz');

%% combine into a single structure
xyzt=struct();
xyzt.x=[datadump.x;zhat_is2(:,1)];
xyzt.y=[datadump.y;zhat_is2(:,2)];
xyzt.z=[datadump.elev;zhat_is2(:,3)];
xyzt.t=[datadump.time_fracyr;zhat_is2(:,1)*0+2019.67960135];
xyzt.atrack=[datadump.along_reftrack_km;datadump.along_reftrack_km(il2a)];
xyzt.campnum=[datadump.campnum;zhat_is2(:,1)*0+max(datadump.campnum)+1];


%% plot this just to make sure things look good
figure; hold on
times=nan(max(xyzt.campnum),1);
for i=1:max(xyzt.campnum)
    icamp=xyzt.campnum==i;
    times(i)=mean(xyzt.t(icamp));
    scatter(xyzt.atrack(icamp),xyzt.z(icamp),25,xyzt.t(icamp),'filled')
end

%%
%%% and now go through and calc dh/dt over defined intervals
wind=1; % along-track window of 1 km
skip=.25; % move 250 m along track for each estimate
min_at=0;
max_at=ceil(max(datadump.along_reftrack_km));

ats=min_at:skip:max_at-1;

% inititalize the output structure
dhdt=struct();
dhdt.alongtrack=nan(length(ats),1);
dhdt.x=nan(length(ats),1);
dhdt.y=nan(length(ats),1);
dhdt.dhdt=nan(length(ats),1);
dhdt.dhdt_rms=nan(length(ats),1);
dhdt.dhdt_std=nan(length(ats),1);
dhdt.h_median=nan(length(ats),1);
dhdt.h_mean=nan(length(ats),1);
dhdt.dz=nan(length(ats),max(xyzt.campnum));
    
    
%figure;hold on
for i=1:length(ats)
    this_at=ats(i)+wind/2;
    in_wind=logical(xyzt.atrack>=ats(i) & xyzt.atrack<=ats(i)+wind);

    if sum(in_wind) > 13 % need atleast 13 points to say its fitable (i.e., more than 2 full campaigns of coverage)
            % determine x,y for the center of the window
            
            
            p_x=polyfit(xyzt.atrack(in_wind),xyzt.x(in_wind),1);
            p_y=polyfit(xyzt.atrack(in_wind),xyzt.y(in_wind),1);
            dhdt.x(i)=polyval(p_x,this_at);
            dhdt.y(i)=polyval(p_y,this_at);

            %%%%% solve for dhdt using the equation
            %%%%% h(x,y,t)=a0+a1*[x-mean(x)]+a2*[y-mean(y)]+a3*[time_fracyr-2000]

            B=xyzt.z(in_wind);
%             A=[ones(size(xyzt.atrack(in_wind))) ...
%                 xyzt.x(in_wind)-mean(xyzt.x(in_wind)) ...
%                 xyzt.y(in_wind)-mean(xyzt.y(in_wind)) ...
%                 xyzt.t(in_wind)-2000];
            A=[ones(size(xyzt.atrack(in_wind))) ...
                xyzt.x(in_wind)-polyval(p_x,this_at) ...
                xyzt.y(in_wind)-polyval(p_y,this_at) ...
                xyzt.t(in_wind)-2000];

            %ang=atan2(max(l2aref(:,2))-min(l2aref(:,2)),max(l2aref(:,1))-min(l2aref(:,1)));
            %R=[cos(ang) -sin(ang); sin(ang) cos(ang)];
            %rot=[xyzt.x(in_wind)-polyval(p_x,this_at) xyzt.y(in_wind)-polyval(p_y,this_at)]*R;
            
            %A=[ones(size(xyzt.atrack(in_wind))) rot(:,1) rot(:,2)];
            
            
            X=A\B;
            B_hat=A*X;

            % save a bunch of stuff
            dhdt.alongtrack(i)=this_at;
            dhdt.z(i)=X(1);
            dhdt.dx(i)=X(2);
            dhdt.dy(i)=X(3);
            dhdt.dhdt(i)=X(4);
            dhdt.dhdt_rms(i)=rms(B-B_hat);
            dhdt.dhdt_std(i)=std(B-B_hat);
            dhdt.h_median(i)=median(xyzt.z(in_wind));
            dhdt.h_mean(i)=mean(xyzt.z(in_wind));
            
            thissubset=subsetStructure(xyzt,in_wind,length(xyzt.x));
            for j=1:max(xyzt.campnum)
                i_camp=thissubset.campnum==j;
                dhdt.dz(i,j)=nanmean(B(i_camp)-B_hat(i_camp));
            end
            %fastscatter(xyzt.atrack(in_wind),B-B_hat,xyzt.t(in_wind))
    end
end

%% plot the results
figure; hold on
sz=size(dhdt.dz);
outdata=[];
% reset dhdt to x=6 to x=46 along track
idx=logical(dhdt.alongtrack>=6 & dhdt.alongtrack<=46);

for i=1:sz(2)
    outdata=[outdata;dhdt.x(idx), dhdt.y(idx), ...
        dhdt.dz(idx,i)*0+dhdt.alongtrack(idx)-min(dhdt.alongtrack(idx)),...
        dhdt.dz(idx,i),dhdt.dz(idx,i)*0+times(i)];
    %scatter(dhdt.dz(i,:)*0+dhdt.alongtrack(i),dhdt.dz(i,:),20,times','filled')
end
scatter(outdata(:,3),outdata(:,4),20,outdata(:,5),'filled')

%% and save the results
dlmwrite('../data/is/isis2_t0096.dat',outdata,'precision','%10.10f','delimiter',',')


