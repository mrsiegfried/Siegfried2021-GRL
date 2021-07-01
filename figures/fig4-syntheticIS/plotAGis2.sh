#!/bin/bash
# M.R. Siegfried, siegfried@mines.edu

out='siegfried2021-grl-fig4'
quickplot=0 # set to 1 to plot this quickly for layout purposes


moa="${DATAHOME}/MODIS/MOA/moa125_2009_hp1_v1.1.nc"

# Scripps Grounding Line
gl="${DATAHOME}/gz/scripps/scripps_antarctica_polygons_v1.shp"

# New phase velocity map - this is a homemade vel. magnitude grid generated command line with:
# > vel_file = antarctic_ice_vel_phase_map_v01
# > gmt grdmath ${vel_file}.nc?VX 2 POW ${vel_file}.nc?VY 2 POW POW 0.5 = ${vel_file}-vmag.nc
vel="${DATAHOME}/velocity/measures-phase_v1/antarctic_ice_vel_phase_map_v01-vmag.nc"
vel_raw="${DATAHOME}/velocity/measures-phase_v1/antarctic_ice_vel_phase_map_v01.nc"

lake1='../../data/outlines/xy/Foundation_12.xy'
lake2='../../data/outlines/xy/Foundation_11.xy'
lake3='../../data/outlines/xy/Foundation_13.xy'
dz_is2_snap='../../data/is2/atl06.003/grids_ag/ag_09_201905.xyz'

isdata='../../data/is/isis2_t0096.dat'

figwidth=5
xoff=`gmt math -Q $figwidth 1.3 ADD = `
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

gmt psbasemap $map $reg -B0 -Xc -Yc -K --MAP_FRAME_TYPE='inside' --PS_MEDIA=50ix50i > ${out}.ps

echo plotting imagery mosaic
gmt grdimage -R -J -O -K $moa -Cmoa.cpt >> ${out}.ps
echo plotting velocity overlay
if [[ $quickplot -ne 1 ]]; then
    gmt grdimage -R -J -O -K -Cvel.cpt $vel -t70 -Q >> ${out}.ps

    gmt psxy -R -J -O -K -Sc0.05c $dz_is2_snap -Cdz.cpt >>$out.ps
fi

gmt psxy -R -J -O -K $lake1 -W2p,black,2_2:0p >> $out.ps
gmt psxy -R -J -O -K $lake2 -W2p,black,2_2:0p >> $out.ps
gmt psxy -R -J -O -K $lake3 -W2p,black,2_2:0p >> $out.ps

gmt psxy -R -J -O -K ${isdata} -i0,1 -W2p,black >> $out.ps

pt1_x=`gmt math ${isdata} -C0 LOWER -S -T -i0 = `
pt1_y=`gmt math ${isdata} -C0 LOWER -S -T -i1 = `
pt2_x=`gmt math ${isdata} -C0 UPPER -S -T -i0 = `
pt2_y=`gmt math ${isdata} -C0 UPPER -S -T -i1 = `

gmt pstext -R -J -O -K -F12p,Helvetica-Bold,black+jTL << EOF >> $out.ps
$pt1_x $pt1_y A
EOF
gmt pstext -R -J -O -K -F12p,Helvetica-Bold,black+jBL -D0c/0.05c << EOF >> $out.ps
$pt2_x $pt2_y A'
EOF

gmt psxy -R -J -O -K -W2p,white << EOF >> $out.ps
`gmt math -Q $xl 5000 ADD = ` `gmt math -Q $yl 5000 ADD = `
`gmt math -Q $xl 25000 ADD = ` `gmt math -Q $yl 5000 ADD = `
EOF

gmt pstext -R -J -O -K -F+f10p,Helvetica,white -D0/0.3c << EOF >> $out.ps
`gmt math -Q $xl 15000 ADD = ` `gmt math -Q $yl 5000 ADD = ` 20 km
EOF

#####
# plot ice flow vector
x_arrow=`gmt math -Q $xh $xh $xl SUB 0.02 MUL SUB = `
y_arrow=`gmt math -Q $yl $yh $yl SUB 0.02 MUL ADD = `
vx=`echo $x_arrow $y_arrow | gmt grdtrack -G${vel_raw}?VX | awk '{print $3}'`
vy=`echo $x_arrow $y_arrow | gmt grdtrack -G${vel_raw}?VY | awk '{print $3}'`
v_dir=`gmt math -Q $vy $vx ATAN2 180 MUL PI DIV = `
gmt psxy -R -J -O -K -Sv0.5c+eA -W2p,white << EOF >> $out.ps
$x_arrow $y_arrow $v_dir 1
EOF
#####

barwidth=`gmt math -Q ${figwidth} 0.4 MUL = `
gmt psscale -Cdz.cpt -R -J -O -K -Dn0.05/0.95+w${barwidth}c/0.2c+h+o0c/0.1c+jTL --FONT_ANNOT_PRIMARY=10p --FONT_LABEL=10p --MAP_ANNOT_OFFSET_PRIMARY=4p --MAP_TICK_PEN_PRIMARY=0.75p --MAP_TICK_LENGTH_PRIMARY=4p --MAP_LABEL_OFFSET=2p -Bxa1f0.5+l"dh [m]" --MAP_FRAME_PEN=0.75p  >> $out.ps

gmt pstext -R -J -O -K -F+f12p,Helvetica-Bold,black+jMC << EOF >> $out.ps
-335000 284000 F11
-318000 324000 F12
-327000 362000 F13
EOF
gmt pstext -R -J -O -K -F+f12p,Helvetica-Bold,black+jTL -D0.07c/-0.07c << EOF >> $out.ps
${xl} ${yh} a.
EOF


######## plot panel B
data='/Volumes/CREVASSE/working/2019_derby_academy/code/t0096_fig/t0096_anomalies.dat'

gmt makecpt -T2000/2020 -Cmatter -I > year.cpt

gmt psbasemap -R0/40/-5/3 -JX5c/5c -O -K -BSWne -Bxaf+l"along-track distance [km]" -Byaf+l"height anomaly [m]" -X${xoff}c -Y1.1c --FONT_ANNOT_PRIMARY=10p --FONT_LABEL=12p --MAP_FRAME_PEN=0.75p --MAP_LABEL_OFFSET=4p >> ${out}.ps

gmt psxy -R -J -O -K -Wthin,black << EOF >> ${out}.ps
0 0
40 0
EOF

gmt psxy -R -J -O -K ${isdata} -i2,3,4 -Sc0.08c -G+z -Cyear.cpt >> $out.ps

#gmt math ${data} -C0 5 SUB = | psxy -R -J -O -K -Sc0.1c -Cyear.cpt >> ${out}.ps
gmt pstext -R -J -O -K -F+f12p,Helvetica-Bold,black+jTL -D0.07c/-0.07c << EOF >> $out.ps
0 3 b.
EOF

gmt psscale -Cyear.cpt -Dx3.06c/0.6c+w1.5c/0.15c+h+ml -Bxa20f5+l"year" -O -K --FONT_LABEL=10p --FONT_ANNOT_PRIMARY=+10p --MAP_LABEL_OFFSET=4p --MAP_FRAME_PEN=0.75p >> $out.ps

gmt psxy -R -J -O << EOF >> $out.ps
0 0
EOF
gmt psconvert -Tf -A -P $out.ps
gmt psconvert -Tg -A -P $out.ps
open $out.png
rm moa.cpt vel.cpt dz.cpt $out.ps year.cpt

