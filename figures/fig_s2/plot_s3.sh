out='siegfried2020-grl-figs2'
quickplot=0 # set to 1 to plot this quickly for layout purposes

figwidth=7
ts_height=4
offset=`gmt math -Q $ts_height 0.75 ADD = `
mac_offset=`gmt math -Q ${ts_height} 0.25 ADD = `

moa="${DATAHOME}/MODIS/MOA/moa125_2009_hp1_v1.1.nc"

# Scripps Grounding Line
gl="${DATAHOME}/gz/scripps/scripps_antarctica_polygons_v1.shp"

# New phase velocity map - this is a homemade vel. magnitude grid generated command line with:
# > vel_file = antarctic_ice_vel_phase_map_v01
# > gmt grdmath ${vel_file}.nc?VX 2 POW ${vel_file}.nc?VY 2 POW POW 0.5 = ${vel_file}-vmag.nc
vel="${DATAHOME}/velocity/measures-phase_v1/antarctic_ice_vel_phase_map_v01-vmag.nc"
vel_raw="${DATAHOME}/velocity/measures-phase_v1/antarctic_ice_vel_phase_map_v01.nc"

lake1='../../data/outlines/xy/SubglacialLakeMercer.xy'
dz_l1_is1='/Users/siegfried/Documents/manuscripts/accepted/2018_siegfried_lakesextended/v1/data/icesat/slm/slm.dat'
dz_l1_is2='../../data/is2/atl06.003/SubglacialLakeMercer_is2_dz.dat'
dz_l1_cs2='../../data/cs2/proc_out/SubglacialLakeMercer/SubglacialLakeMercer_elevs.dat'

lake2='../../data/outlines/xy/SubglacialLakeConway.xy'
dz_l2_is1='/Users/siegfried/Documents/manuscripts/accepted/2018_siegfried_lakesextended/v1/data/icesat/slc/slc.dat'
dz_l2_is2='../../data/is2/atl06.003/SubglacialLakeConway_is2_dz.dat'
dz_l2_cs2='../../data/cs2/proc_out/SubglacialLakeConway/SubglacialLakeConway_elevs.dat'

dz_is2_snap='../../data/is2/atl06.003/grids_miswis/miswis_09_201905.xyz'

is1slm=../../data/is/slm_L2a.dat
is1slc=../../data/is/slc_L2a.dat

xl=-345000
xh=-275000
yl=-540000
yh=-480000

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

gmt psxy -R -J -O -K $is1slm -Sc1p -Gblack >> $out.ps
gmt psxy -R -J -O -K $is1slc -Sc1p -Gblack >> $out.ps

gmt psxy -R -J -O -K $lake1 -W2p,black,2_2:0p >> $out.ps
gmt psxy -R -J -O -K $lake2 -W2p,red,2_2:0p >> $out.ps

gmt psxy -R -J -O -K -W2p,white << EOF >> $out.ps
`gmt math -Q $xl 2500 ADD = ` `gmt math -Q $yl 2500 ADD = `
`gmt math -Q $xl 12500 ADD = ` `gmt math -Q $yl 2500 ADD = `
EOF

gmt pstext -R -J -O -K -F+f10p,Helvetica,white -D0/0.25c << EOF >> $out.ps
`gmt math -Q $xl 7500 ADD = ` `gmt math -Q $yl 2500 ADD = ` 10 km
EOF

barwidth=`gmt math -Q ${figwidth} 0.4 MUL = `
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

gmt pstext -R -J -O -K -F+f+jMC << EOF >> $out.ps
-327000 -514000 12p,Helvetica-Bold,red SLC
-295000 -488000 12p,Helvetica-Bold,black SLM
-313000 -505000 12p,Helvetica-Bold,blue LSLC
-287000 -496000 12p,Helvetica-Bold,blue LSLM
EOF

### finish things up
gmt psbasemap -R -J -O -B0 >> $out.ps
gmt psconvert -Tf -A -P $out.ps
gmt psconvert -Tg -A -P $out.ps
open $out.pdf
rm moa.cpt vel.cpt dz.cpt $out.ps

