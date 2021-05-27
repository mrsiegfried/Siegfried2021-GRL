function subset_is2_lakes(outline_fold,tracklist_fold,buffer_size,subset_fold)
% subsets icesat2 data to a region surrounding each lake from
% Siegfried & Fricker 2018
% M.R. Siegfried, 12 September 2020
% siegfried@mines.edu

    lake_outlines=dir([outline_fold '/*.xy']);
    
    for i=4:length(lake_outlines)
        thisfile=[lake_outlines(i).folder '/' lake_outlines(i).name];
        outline=load(thisfile);
        outline_poly=polyshape(outline(:,1:2));
        poly=polybuffer(outline_poly,buffer_size);

        [~,lake_name,~]=fileparts(thisfile);

        tracklist=[tracklist_fold '/' lake_name '.mat'];
        d=load(tracklist);
        fn=fieldnames(d);
        atl06_files=d.(fn{1});

        savefile=[subset_fold '/' lake_name '.mat'];
        subset_atl06(atl06_files,poly,savefile);
    end

end

function subset_atl06(filelist,pgon,dest)
    data=struct();
    [~,ln,~]=fileparts(dest);
    
    for f=1:length(filelist)
        thisfile=filelist{f};
        [~,fname,~]=fileparts(thisfile);
        if mod(f,10)==0
            disp([ln ': ' fname ' (' num2str(f) ' of ' num2str(length(filelist)) ')'])
        end
        
        parts=strsplit(fname,'_');
        thisdate=parts{2}(1:8);
        thistrack=parts{3}(1:4);
        thiscycle=parts{3}(5:6);
        thisregion=parts{3}(7:8);
        thisrelease=[parts{4}(1:3) '_' parts{5}(1:2)];
        
        thisdata=read_is2_h5_lite(thisfile, true);
        
        for bn = {'gt1l','gt1r','gt2l','gt2r','gt3l','gt3r'}
            beam_name=bn{1};
            if isfield(thisdata,beam_name)
                xl=min(pgon.Vertices(:,1));
                xh=max(pgon.Vertices(:,1));
                yl=min(pgon.Vertices(:,2));
                yh=max(pgon.Vertices(:,2));
                in_coarse=logical(thisdata.(beam_name).x >= xl & ...
                    thisdata.(beam_name).x <= xh & ...
                    thisdata.(beam_name).y >= yl & ...
                    thisdata.(beam_name).y <= yh);
                if sum(in_coarse) > 0
                    fn=fieldnames(thisdata.(beam_name));
                    len=length(thisdata.(beam_name).x);
                    for j=1:length(fn)
                        thisfielddata=thisdata.(beam_name).(fn{j});
                        if length(thisfielddata) == len
                            thisdata.(beam_name).(fn{j})=thisfielddata(in_coarse);
                        else
                            thisdata.(beam_name).(fn{j})=thisfielddata;
                        end
                    end

                    idx_in = isinterior(pgon,thisdata.(beam_name).x,thisdata.(beam_name).y);
                    if sum(idx_in) > 0
                        %disp([num2str(sum(idx_in)) ' pts in ' thisfile ' beam ' beam_name])
                        fn=fieldnames(thisdata.(beam_name));
                        len=length(thisdata.(beam_name).x);
                        for j=1:length(fn)
                            thisfielddata=thisdata.(beam_name).(fn{j});
                            if length(thisfielddata) == len
                                data.(['t' thistrack]).(['d' thisdate]).(beam_name).(fn{j})=thisfielddata(idx_in);
                            else
                                data.(['t' thistrack]).(['d' thisdate]).(beam_name).(fn{j})=thisfielddata;
                            end
                        end
                        data.(['t' thistrack]).(['d' thisdate]).cycle = thiscycle;
                        data.(['t' thistrack]).(['d' thisdate]).region = thisregion;
                        data.(['t' thistrack]).(['d' thisdate]).release = thisrelease;
                        data.(['t' thistrack]).(['d' thisdate]).original_file = thisfile;
                    end
                end
            end
        end
    end
    
    [~,ln,~]=fileparts(dest);
    eval([ln '=data;']);
    save(dest,ln);
           
    disp([dest ' saved'])
end
