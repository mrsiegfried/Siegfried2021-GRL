
function save_is2_track_list(src_fold,trackmap_fold,poly,savefile)
% save_is2_track_list
% M.R. Siegfried, 15 Sept 2020
% saves a list of tracks that are within a polygon

files=dir([trackmap_fold '/*.mat']);
[~,fname,~]=fileparts(savefile);

tmp=struct();
for f=1:length(files)
    d=load([files(f).folder '/' files(f).name]);
    fn=fieldnames(d);
    data=d.(fn{1});
    
    yr=files(f).name(5:8);
    mth=files(f).name(9:10);
    day=files(f).name(11:12);
    thisdate=[yr '.' mth '.' day];
    
    % first subset based on min/max of polygon to reduce # of points
    xl=min(poly.Vertices(:,1));
    xh=max(poly.Vertices(:,1));
    yl=min(poly.Vertices(:,2));
    yh=max(poly.Vertices(:,2));
    in=logical(data(:,1) >= xl & data(:,1) <= xh & ...
        data(:,2) >= yl & data(:,2) <= yh);
    
    if sum(in) > 0
        x=data(in,1);
        y=data(in,2);
        tracknum=data(in,3);
        idx=isinterior(poly,x,y);
        tracks=unique(tracknum(idx));
        
        if sum(tracks) > 0
            disp([fname ': found ' num2str(length(tracks)) ' track on ' thisdate]);
            for t=1:length(tracks)
                thistrack=sprintf('%04d',tracks(t));
                ymd=[yr mth day];
                thisfilelist10=dir([src_fold '/' thisdate ...
                    '/ATL06_' thisdate(1:4) thisdate(6:7) thisdate(9:10) '*_' ...
                    thistrack '*10_003_0*.h5']);
                thisfilelist11=dir([src_fold '/' thisdate ...
                    '/ATL06_' thisdate(1:4) thisdate(6:7) thisdate(9:10) '*_' ...
                    thistrack '*11_003_0*.h5']);
                thisfilelist12=dir([src_fold '/' thisdate ...
                    '/ATL06_' thisdate(1:4) thisdate(6:7) thisdate(9:10) '*_' ...
                    thistrack '*12_003_0*.h5']);
                names=[{thisfilelist10.folder}' {thisfilelist10.name}';...
                    {thisfilelist11.folder}' {thisfilelist11.name}';...
                    {thisfilelist12.folder}' {thisfilelist12.name}'];
                sz=size(names);
                tmp.(['d' ymd])=cell(sz(1),1);
                for j=1:sz(1)
                    tmp.(['d' ymd])(j)= {[names{j,1},'/',names{j,2}]};
                end
                %outstr=[ymd ', ' sprintf('%04d',tracks(t))];
                %fprintf(fid,'%s\n',outstr);
            end
        end     
    end
    fn=fieldnames(tmp);
    total=0;
    for k=1:length(fn)
        sz=size(tmp.(fn{k}));
        total=total+sz(1);
    end
    %disp([num2str(total) ' total files for ' fname])
    
    idx=1;
    o=cell(total,1);
    for i=1:length(fn)
        sz=size(tmp.(fn{i}));
        o(idx:idx+sz-1)=tmp.(fn{i});
        idx=idx+sz;
    end
end
eval([fname '=o;']);
save(savefile,fname);
disp([savefile ' saved!'])

    
