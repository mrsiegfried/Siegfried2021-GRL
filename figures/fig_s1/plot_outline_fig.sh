#!/bin/bash
# M.R. Siegfried, siegfried@mines.edu

out='siegfried2021-figs1'
quickplot=0 # set to 1 to plot this quickly for layout purposes


figwidth=7
moa="${DATAHOME}/MODIS/MOA/moa125_2009_hp1_v1.1.nc"

# New phase velocity map - this is a homemade vel. magnitude grid generated command line with:
# > vel_file = antarctic_ice_vel_phase_map_v01
# > gmt grdmath ${vel_file}.nc?VX 2 POW ${vel_file}.nc?VY 2 POW POW 0.5 = ${vel_file}-vmag.nc
vel="${DATAHOME}/velocity/measures-phase_v1/antarctic_ice_vel_phase_map_v01-vmag.nc"
vel_raw="${DATAHOME}/velocity/measures-phase_v1/antarctic_ice_vel_phase_map_v01.nc"

lake2='../../data/outlines/xy/SubglacialLakeConway.xy'
dz_l2_is1='/Users/siegfried/Documents/manuscripts/accepted/2018_siegfried_lakesextended/v1/data/icesat/slc/slc.dat'
dz_l2_is2='../../data/is2/atl06.003/SubglacialLakeConway_is2_dz.dat'
dz_l2_cs2='../../data/cs2/proc_out/SubglacialLakeConway/SubglacialLakeConway_elevs.dat'

dz_is2_snap1='../../data/is2/atl06.003/grids_miswis/miswis_06_201902.xyz'
dz_is2_snap2='../../data/is2/atl06.003/grids_miswis/miswis_13_201909.xyz'

newout1='../../../code_old/slc_bound-2_2019.txt'
newout2='../../../code_old/slc_bound-9_2019.txt'


xl=-345000
xh=-290000
yl=-540000
yh=-500000

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
    
    gmt psxy -R -J -O -K -Sc0.05c $dz_is2_snap1 -Cdz.cpt >>$out.ps
fi

gmt psxy -R -J -O -K $lake2 -W2p,black,2_2:0p >> $out.ps
gmt psxy -R -J -O -K $newout1 -W2p,red >> $out.ps

gmt psxy -R -J -O -K -W2p,white << EOF >> $out.ps
`gmt math -Q $xl 2500 ADD = ` `gmt math -Q $yl 2500 ADD = `
`gmt math -Q $xl 12500 ADD = ` `gmt math -Q $yl 2500 ADD = `
EOF

gmt pstext -R -J -O -K -F+f10p,Helvetica,white -D0/0.25c << EOF >> $out.ps
`gmt math -Q $xl 7500 ADD = ` `gmt math -Q $yl 2500 ADD = ` 10 km
EOF

barwidth=`gmt math -Q ${figwidth} 0.3 MUL = `
gmt psscale -Cdz.cpt -R -J -O -K -Dn0.05/0.98+w${barwidth}c/0.2c+h+o0c/0.1c+jTL --FONT_ANNOT_PRIMARY=10p --FONT_LABEL=10p --MAP_ANNOT_OFFSET_PRIMARY=4p --MAP_TICK_PEN_PRIMARY=1p --MAP_TICK_LENGTH_PRIMARY=4p --MAP_LABEL_OFFSET=2p -Bxa1f0.5+l"dh [m]" >> $out.ps

#####
# plot ice flow vector
x_arrow=`gmt math -Q $xh $xh $xl SUB 0.15 MUL SUB = `
y_arrow=`gmt math -Q $yl $yh $yl SUB 0.1 MUL ADD = `
vx=`echo $x_arrow $y_arrow | gmt grdtrack -G${vel_raw}?VX | awk '{print $3}'`
vy=`echo $x_arrow $y_arrow | gmt grdtrack -G${vel_raw}?VY | awk '{print $3}'`
v_dir=`gmt math -Q $vy $vx ATAN2 180 MUL PI DIV = `
gmt psxy -R -J -O -K -Sv0.5c+eA -W2p,white << EOF >> $out.ps
$x_arrow $y_arrow $v_dir 1
EOF
#####

gmt pstext -R -J -O -K -F+f12p,Helvetica-Bold,black+jBL -D0.1c/0.2c -N << EOF >> $out.ps
${xl} ${yh} a.
EOF

gmt psbasemap -R -J -O -K -B0 >> $out.ps

###### panel b
gmt psbasemap $map $reg -B0 -X7.2c -O -K --MAP_FRAME_TYPE='inside' >> ${out}.ps

echo plotting imagery mosaic
gmt grdimage -R -J -O -K $moa -Cmoa.cpt >> ${out}.ps
echo plotting velocity overlay
if [[ $quickplot -ne 1 ]]; then
    gmt grdimage -R -J -O -K -Cvel.cpt $vel -t70 -Q >> ${out}.ps
    
    gmt psxy -R -J -O -K -Sc0.05c $dz_is2_snap2 -Cdz.cpt >>$out.ps
fi

gmt psxy -R -J -O -K $lake2 -W2p,black,2_2:0p >> $out.ps
gmt psxy -R -J -O -K $newout2 -W2p,red >> $out.ps

gmt psxy -R -J -O -K -W2p,white << EOF >> $out.ps
`gmt math -Q $xl 2500 ADD = ` `gmt math -Q $yl 2500 ADD = `
`gmt math -Q $xl 12500 ADD = ` `gmt math -Q $yl 2500 ADD = `
EOF

gmt pstext -R -J -O -K -F+f10p,Helvetica,white -D0/0.25c << EOF >> $out.ps
`gmt math -Q $xl 7500 ADD = ` `gmt math -Q $yl 2500 ADD = ` 10 km
EOF

barwidth=`gmt math -Q ${figwidth} 0.3 MUL = `
gmt psscale -Cdz.cpt -R -J -O -K -Dn0.05/0.98+w${barwidth}c/0.2c+h+o0c/0.1c+jTL --FONT_ANNOT_PRIMARY=10p --FONT_LABEL=10p --MAP_ANNOT_OFFSET_PRIMARY=4p --MAP_TICK_PEN_PRIMARY=1p --MAP_TICK_LENGTH_PRIMARY=4p --MAP_LABEL_OFFSET=2p -Bxa1f0.5+l"dh [m]" >> $out.ps

#####
# plot ice flow vector
x_arrow=`gmt math -Q $xh $xh $xl SUB 0.15 MUL SUB = `
y_arrow=`gmt math -Q $yl $yh $yl SUB 0.1 MUL ADD = `
vx=`echo $x_arrow $y_arrow | gmt grdtrack -G${vel_raw}?VX | awk '{print $3}'`
vy=`echo $x_arrow $y_arrow | gmt grdtrack -G${vel_raw}?VY | awk '{print $3}'`
v_dir=`gmt math -Q $vy $vx ATAN2 180 MUL PI DIV = `
gmt psxy -R -J -O -K -Sv0.5c+eA -W2p,white << EOF >> $out.ps
$x_arrow $y_arrow $v_dir 1
EOF
#####

gmt pstext -R -J -O -K -F+f12p,Helvetica-Bold,black+jBL -D0.1c/0.2c -N << EOF >> $out.ps
${xl} ${yh} b.
EOF

gmt psbasemap -R -J -O -B0 >> $out.ps


gmt psconvert -Tf -A -P $out.ps
gmt psconvert -Tf -A -P $out.ps
gmt psconvert -Tg -A -P $out.ps
open $out.pdf
rm moa.cpt vel.cpt dz.cpt $out.ps
