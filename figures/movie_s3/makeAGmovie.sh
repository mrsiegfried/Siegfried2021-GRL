

outstem='png/siegfried2020-grl-ag'

moa="${DATAHOME}/MODIS/MOA/moa125_2009_hp1_v1.1.nc"
gl="${DATAHOME}/gz/scripps/scripps_antarctica_polygons_v1.shp"
vel="${DATAHOME}/velocity/measures-phase_v1/antarctic_ice_vel_phase_map_v01-vmag.nc"

lake1='../../data/outlines/xy/Foundation_11.xy'
lake2='../../data/outlines/xy/Foundation_12.xy'
lake3='../../data/outlines/xy/Foundation_13.xy'
xyzfold='../../data/is2/atl06.003/grids_ag'

figwidth=8
xl=-380000
xh=-290000
yl=270000
yh=383000

ratio=`gmt math -Q ${xh} ${xl} SUB ${figwidth} 100 DIV DIV = `
reg=-R${xl}/${xh}/${yl}/${yh}
map=-Jx1:${ratio}

gmt makecpt -T15000/17000/1 -Z -Cgray > moa.cpt
gmt makecpt -T1/1000/3 -Cplasma --COLOR_FOREGROUND=240/249/33 --COLOR_BACKGROUND=13/8/135 > vel.cpt
gmt makecpt -T-1/1/0.1 -Cvik.cpt > dz.cpt


for f in `ls ${xyzfold}/*.xyz`
do
    name=`basename $f`
    idx=${name:3:2}
    mth=${name:10:2}
    yr=${name:6:4}
    out=${outstem}_${idx}
    
    datestr="${mth}/${yr}"
    echo $datestr $out
    
    mth=`gmt math -Q ${mth} 1 ADD = `
    if [[ mth -eq 13 ]]; then
        mth=1
        yr=`gmt math -Q $yr 1 ADD = `
    fi
    
    gmt psbasemap $map $reg -B0 -Xc -Yc -K --MAP_FRAME_TYPE='inside' --PS_MEDIA=50ix50i > ${out}.ps
    gmt grdimage -R -J -O -K $moa -Cmoa.cpt >> ${out}.ps
    gmt grdimage -R -J -O -K -Cvel.cpt $vel -t70 -Q >> ${out}.ps
    gmt psxy -R -J -O -K -Sc0.05c ${f} -Cdz.cpt >> $out.ps
    
    gmt psxy -R -J -O -K $lake1 -W2p,black,2_2:0p >> $out.ps
    gmt psxy -R -J -O -K $lake2 -W2p,black,2_2:0p >> $out.ps
    gmt psxy -R -J -O -K $lake3 -W2p,black,2_2:0p >> $out.ps
    
    gmt psxy -R -J -O -K -W2p,white << EOF >> $out.ps
    `gmt math -Q $xl 2500 ADD = ` `gmt math -Q $yl 2500 ADD = `
    `gmt math -Q $xl 12500 ADD = ` `gmt math -Q $yl 2500 ADD = `
EOF

    gmt pstext -R -J -O -K -F+f10p,Helvetica,white -D0/0.25c << EOF >> $out.ps
    `gmt math -Q $xl 7500 ADD = ` `gmt math -Q $yl 2500 ADD = ` 10 km
EOF
    gmt pstext -R -J -O -K -F+f12p,Helvetica,white+jBR -D-0.25c/0.25c << EOF >> $out.ps
    ${xh} ${yl} ${datestr}
EOF

    barwidth=`gmt math -Q ${figwidth} 0.4 MUL = `
    gmt psscale -Cdz.cpt -R -J -O -Dn0.05/0.98+w${barwidth}c/0.2c+h+o0c/0.1c+jTL --FONT_ANNOT_PRIMARY=10p --FONT_LABEL=10p --MAP_ANNOT_OFFSET_PRIMARY=4p --MAP_TICK_PEN_PRIMARY=1p --MAP_TICK_LENGTH_PRIMARY=4p --MAP_LABEL_OFFSET=2p -Bxa1f0.5+l"dh [m]" >> $out.ps
    
    gmt psconvert -Tg -A -P $out.ps
    rm $out.ps
done

cd png
ffmpeg -framerate 2 -pattern_type glob -i "*.png" movies_s3.mp4
cd ..
mv png/movies_s3.mp4 ./

rm moa.cpt vel.cpt dz.cpt



