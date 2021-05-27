function dump_all_is2_lake_data(datadir)


lakes=dir([datadir '/*.mat']);

for l=1:length(lakes)
    thislake=lakes(l).name;
    [~,lakename,~]=fileparts(thislake);
    disp(['working on ' lakename]);
    d=load([datadir '/' thislake]);
    fn=fieldnames(d);
    data=d.(fn{1});
    
    xyz=dumpIS2data(data,[]);
    
    outfile=[datadir '/' lakename '.is2.xyzt'];
    dlmwrite(outfile,xyz,'delimiter',' ','precision','%10.10f');
    
end

end
function out=dumpIS2data(is2data,badtracks)

    xyz=[];
    tracks=fieldnames(is2data);
    for t=1:length(tracks)
        disp(['...on track ' num2str(t) ' of ' num2str(length(tracks))])
        thistrack=tracks{t};
        if ~ismember(thistrack,badtracks)
            days=fieldnames(is2data.(thistrack));
            for d=1:length(days)
                thisday=days{d};
                beams=fieldnames(is2data.(thistrack).(thisday));
                for b=1:length(beams)
                    thisbeam=beams{b};
                    if strcmp(thisbeam(1:2),'gt')
                        thisdata=is2data.(thistrack).(thisday).(thisbeam);
                        if length(thisdata.x)>1
                            xyz=[xyz;double(thisdata.x) ...
                                double(thisdata.y) ...
                                double(thisdata.h_li) ...
                                double(thisdata.time_fracyr) ...
                                double(thisdata.h_li)*0+str2double(is2data.(thistrack).(thisday).cycle) ...
                                double(thisdata.h_li)*0+str2double(thistrack(2:end))];
                        end
                    end
                end
            end
        end
    end
    out=xyz;


end
