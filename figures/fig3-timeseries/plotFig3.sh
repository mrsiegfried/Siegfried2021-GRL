out='siegfried2020-grl-fig3'
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

gmt pstext -R -J -O -K -F+f12p,Helvetica-Bold,black+jBL -D0.1c/0.2c -N << EOF >> $out.ps
${xl} ${yh} a.
EOF
gmt pstext -R -J -O -K -F+f+jMC << EOF >> $out.ps
-327000 -514000 12p,Helvetica-Bold,red SLC
-295000 -488000 12p,Helvetica-Bold,black SLM
-313000 -505000 12p,Helvetica-Bold,blue LSLC
-287000 -496000 12p,Helvetica-Bold,blue LSLM
EOF

gmt psbasemap -R -J -O -K -B0 >> $out.ps

###### plot MIS/WIS time series

yr_in=2003
yr_out=2021
hl=-5
hh=5

# make file for error envelope
thisone=$dz_l1_cs2
gmt math $thisone -C3 2 POW 7 COL 2 POW ADD 0.5 POW 2 MUL -C1 5 COL SUB 3 COL ADD -o0,1 = cs2_env_high
gmt math $thisone -C3 2 POW 7 COL 2 POW ADD 0.5 POW 2 MUL -C1 5 COL SUB 3 COL SUB -o0,1 = | tail -r > cs2_env_low
cat cs2_env_high cs2_env_low > cs2_err_env_l1
rm cs2_env_high cs2_env_low

thisone=$dz_l2_cs2
gmt math $thisone -C3 2 POW 7 COL 2 POW ADD 0.5 POW 2 MUL -C1 5 COL SUB 3 COL ADD -o0,1 = cs2_env_high
gmt math $thisone -C3 2 POW 7 COL 2 POW ADD 0.5 POW 2 MUL -C1 5 COL SUB 3 COL SUB -o0,1 = | tail -r > cs2_env_low
cat cs2_env_high cs2_env_low > cs2_err_env_l2
rm cs2_env_high cs2_env_low


gmt psbasemap -O -K -R${yr_in}/${yr_out}/${hl}/${hh} -JX${figwidth}c/${ts_height}c -Y-${offset}c -Bxa5f1+l"year" -Bya2f1+l"h@-anom@- [m]" -BSWne --FONT_ANNOT_PRIMARY=10p --FONT_LABEL=10p --MAP_LABEL_OFFSET=4p >> $out.ps


gmt math $dz_l2_is1 -C1 2 COL SUB 1 ADD = | gmt psxy -R -J -O -K -i0,1 -W1.5p,lightred >> $out.ps
gmt math cs2_err_env_l2 -C1 1 ADD = | gmt psxy -R -J -O -K -Glightred -t50 >> $out.ps
gmt math $dz_l2_cs2 -C1 5 COL SUB 1 ADD = | gmt psxy -R -J -O -K -i0,1 -W1.5p,lightred >> $out.ps
gmt math $dz_l2_is2 -C1 2 COL SUB 1 ADD = | gmt psxy -R -J -O -K -i0,1 -W1.5p,red >> $out.ps

gmt math $dz_l1_is1 -C1 2 COL SUB = | gmt psxy -R -J -O -K -i0,1 -W1.5p,gray >> $out.ps
gmt math cs2_err_env_l1 -C1 0 ADD = | gmt psxy -R -J -O -K -Ggray -t50 >> $out.ps
gmt math $dz_l1_cs2 -C1 5 COL SUB = | gmt psxy -R -J -O -K -i0,1 -W1.5p,gray >> $out.ps
gmt math $dz_l1_is2 -C1 2 COL SUB = | gmt psxy -R -J -O -K -i0,1 -W1.5p,black >> $out.ps

gmt pstext -R -J -O -K -F+f12p,Helvetica-Bold,black+jTL -D0.1c/-0.1c << EOF >> $out.ps
${yr_in} ${hh} c.
EOF

########################
####### PLOT MACIS STUFF
########################

lake1='../../data/outlines/xy/Mac1.xy'
dz_l1_is1='/Users/siegfried/Documents/manuscripts/accepted/2018_siegfried_lakesextended/v1/data/icesat/mac1/mac1.dat'
dz_l1_is2='../../data/is2/atl06.003/Mac1_is2_dz.dat'
dz_l1_cs2='../../data/cs2/proc_out/Mac1/Mac1_elevs.dat'

lake2='../../data/outlines/xy/Mac2.xy'
dz_l2_is1='/Users/siegfried/Documents/manuscripts/accepted/2018_siegfried_lakesextended/v1/data/icesat/mac2/mac2.dat'
dz_l2_is2='../../data/is2/atl06.003/Mac2_is2_dz.dat'
dz_l2_cs2='../../data/cs2/proc_out/Mac2/Mac2_elevs.dat'

lake3='../../data/outlines/xy/Mac3.xy'
dz_l3_is1='/Users/siegfried/Documents/manuscripts/accepted/2018_siegfried_lakesextended/v1/data/icesat/mac3/mac3.dat'
dz_l3_is2='../../data/is2/atl06.003/Mac3_is2_dz.dat'
dz_l3_cs2='../../data/cs2/proc_out/Mac3/Mac3_elevs.dat'

dz_is2_snap='../../data/is2/atl06.003/grids_mac/mac_18_202002.xyz'

# make file for error envelope
thisone=$dz_l1_cs2
gmt math $thisone -C3 2 POW 7 COL 2 POW ADD 0.5 POW 2 MUL -C1 5 COL SUB 3 COL ADD -o0,1 = cs2_env_high
gmt math $thisone -C3 2 POW 7 COL 2 POW ADD 0.5 POW 2 MUL -C1 5 COL SUB 3 COL SUB -o0,1 = | tail -r > cs2_env_low
cat cs2_env_high cs2_env_low > cs2_err_env_l1
rm cs2_env_high cs2_env_low

### no removing out of lake for Mac 2 per Siegfried & Fricker, 2018
thisone=$dz_l2_cs2
gmt math $thisone -C3 2 POW 0.5 POW 2 MUL -C1 3 COL ADD -o0,1,6 = cs2_env_high
gmt math $thisone -C3 2 POW 0.5 POW 2 MUL -C1 3 COL SUB -o0,1,6 = | tail -r > cs2_env_low
cat cs2_env_high cs2_env_low > cs2_err_env_l2
rm cs2_env_high cs2_env_low

thisone=$dz_l3_cs2
gmt math $thisone -C3 2 POW 7 COL 2 POW ADD 0.5 POW 2 MUL -C1 5 COL SUB 3 COL ADD -o0,1,6 = cs2_env_high
gmt math $thisone -C3 2 POW 7 COL 2 POW ADD 0.5 POW 2 MUL -C1 5 COL SUB 3 COL SUB -o0,1,6 = | tail -r > cs2_env_low
cat cs2_env_high cs2_env_low > cs2_err_env_l3
rm cs2_env_high cs2_env_low


#### plot panel d (time series)
yr_in=2003
yr_out=2021
hl=-4
hh=8

gmt psbasemap -O -K -R${yr_in}/${yr_out}/${hl}/${hh} -JX${figwidth}c/${ts_height}c -X`gmt math -Q $figwidth 0.5 ADD = `c -Bxa5f1+l"year" -Bya4f2+l"h@-anom@- [m]" -BSEwn --FONT_ANNOT_PRIMARY=10p --FONT_LABEL=10p --MAP_LABEL_OFFSET=4p >> $out.ps

gmt math $dz_l3_is1 -C1 2 COL SUB -1 ADD = | gmt psxy -R -J -O -K -i0,1 -W1.5p,lightred >> $out.ps
gmt math cs2_err_env_l3 -C1 -1 ADD = | gmt psxy -R -J -O -K -Glightred -t50 >> $out.ps
gmt math $dz_l3_cs2 -C1 5 COL SUB -1 ADD = | gmt psxy -R -J -O -K -i0,1 -W1.5p,lightred >> $out.ps
gmt math $dz_l3_is2 -C1 2 COL SUB -1 ADD = | gmt psxy -R -J -O -K -i0,1 -W1.5p,red >> $out.ps

gmt math $dz_l2_is1 -C1 1 ADD = | gmt psxy -R -J -O -K -i0,1 -W1.5p,lightblue,2_2:0p >> $out.ps
gmt math cs2_err_env_l2 -C1 1 ADD = | gmt psxy -R -J -O -K -Glightblue -t50 >> $out.ps
gmt math $dz_l2_cs2 -C1 1 ADD = | gmt psxy -R -J -O -K -i0,1 -W1.5p,lightblue,2_2:0p >> $out.ps
gmt math $dz_l2_is2 -C1 1 ADD = | gmt psxy -R -J -O -K -i0,1 -W1.5p,blue,2_2:0p >> $out.ps

gmt math $dz_l1_is1 -C1 2 COL SUB 2.5 ADD = | gmt psxy -R -J -O -K -i0,1 -W1.5p,gray >> $out.ps
gmt math cs2_err_env_l1 -C1 2.5 ADD = | gmt psxy -R -J -O -K -Ggray -t50 >> $out.ps
gmt math $dz_l1_cs2 -C1 5 COL SUB 2.5 ADD = | gmt psxy -R -J -O -K -i0,1 -W1.5p,gray >> $out.ps
gmt math $dz_l1_is2 -C1 2 COL SUB 2.5 ADD = | gmt psxy -R -J -O -K -i0,1 -W1.5p,black >> $out.ps
gmt pstext -R -J -O -K -F+f12p,Helvetica-Bold,black+jTL -D0.1c/-0.1c << EOF >> $out.ps
${yr_in} ${hh} d.
EOF

#### plot MACIS map
xl=-680000
xh=-600000
yl=-920000
yh=-840000

ratio=`gmt math -Q ${xh} ${xl} SUB ${figwidth} 100 DIV DIV = `
reg=-R${xl}/${xh}/${yl}/${yh}
map=-Jx1:${ratio}

gmt psbasemap $map $reg -B0 -O -K --MAP_FRAME_TYPE='inside' -Y${mac_offset}c >> ${out}.ps

echo plotting imagery mosaic
gmt grdimage -R -J -O -K $moa -Cmoa.cpt >> ${out}.ps
echo plotting velocity overlay
if [[ $quickplot -ne 1 ]]; then
    gmt grdimage -R -J -O -K -Cvel.cpt $vel -t70 -Q >> ${out}.ps

    gmt psxy -R -J -O -K -Sc0.05c $dz_is2_snap -Cdz.cpt >>$out.ps
fi

gmt psxy -R -J -O -K $lake1 -W2p,black,2_2:0p >> $out.ps
gmt psxy -R -J -O -K $lake2 -W2p,blue,2_2:0p >> $out.ps
gmt psxy -R -J -O -K $lake3 -W2p,red,2_2:0p >> $out.ps

gmt psxy -R -J -O -K -W2p,white << EOF >> $out.ps
`gmt math -Q $xl 2500 ADD = ` `gmt math -Q $yl 2500 ADD = `
`gmt math -Q $xl 12500 ADD = ` `gmt math -Q $yl 2500 ADD = `
EOF

gmt pstext -R -J -O -K -F+f10p,Helvetica,white -D0/0.25c << EOF >> $out.ps
`gmt math -Q $xl 7500 ADD = ` `gmt math -Q $yl 2500 ADD = ` 10 km
EOF

barwidth=`gmt math -Q ${figwidth} 0.4 MUL = `
gmt psscale -Cdz.cpt -R -J -O -K -Dn0.55/0.98+w${barwidth}c/0.2c+h+o0c/0.1c+jTL --FONT_ANNOT_PRIMARY=10p --FONT_LABEL=10p --MAP_ANNOT_OFFSET_PRIMARY=4p --MAP_TICK_PEN_PRIMARY=1p --MAP_TICK_LENGTH_PRIMARY=4p --MAP_LABEL_OFFSET=2p -Bxa1f0.5+l"dh [m]" >> $out.ps
gmt pstext -R -J -O -K -F+f12p,Helvetica-Bold,black+jBL -D0.1c/-0.4c -N << EOF >> $out.ps
${xl} ${yh} b.
EOF
gmt pstext -R -J -O -K -F+f+jMC << EOF >> $out.ps
-655000 -855000 12p,Helvetica-Bold,red Mac3
-642000 -890000 12p,Helvetica-Bold,blue Mac2
-610000 -900000 12p,Helvetica-Bold,black Mac1
EOF


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

# arrow to new anomaly as requested by reviewer
gmt psxy -R -J -O -K -Sv0.4c+eA -W1.5p,blue << EOF >> $out.ps
-646000 -918000 90 1
EOF

### finish things up
gmt psbasemap -R -J -O -B0 >> $out.ps
gmt psconvert -Tf -A -P $out.ps
gmt psconvert -Tg -A -P $out.ps
open $out.pdf
rm moa.cpt vel.cpt dz.cpt $out.ps cs2_err_env_l1 cs2_err_env_l2 cs2_err_env_l3

