out='siegfried2020-grl-fig1'

moa="${DATAHOME}/MODIS/MOA/moa750_2009_hp1_v01.1.tif"

# Scripps Grounding Line
gl="${DATAHOME}/gz/scripps/scripps_antarctica_polygons_v1.shp"

# New phase velocity map - this is a homemade vel. magnitude grid generated command line with:
# > vel_file = antarctic_ice_vel_phase_map_v01
# > gmt grdmath ${vel_file}.nc?VX 2 POW ${vel_file}.nc?VY 2 POW POW 0.5 = ${vel_file}-vmag.nc
vel="${DATAHOME}/velocity/measures-phase_v1/antarctic_ice_vel_phase_map_v01-vmag.nc"

# Siegfried & Fricker, 2018 outlines
lakefold='../../data/outlines/xy'

# sarin polygon
sarinout="${DATAHOME}/cryosat2/sarin_polygon_10k_outside.xy"
sarinin="${DATAHOME}/cryosat2/sarin_polygon_10k_inside.xy"

# Old MOA shapes that are good enough for continent-scale insets:
moa_coast="${DATAHOME}/gz/moa/moa_2009_coastline_v01.1.gmt"
moa_gl="${DATAHOME}/gz/moa/moa_2009_groundingline_v01.1.gmt"

### SET UP BASIC FIGURE DETAILS
# We're making this a specific height
figheight=115 # in mm

# Region in PS71 for main part of the figure
xl=-2100000
xh=510000
yl=-1500000
yh=1000000

figwidth=`gmt math -Q ${xh} ${xl} SUB ${yh} ${yl} SUB DIV ${figheight} MUL = `
ratio=`gmt math -Q ${yh} ${yl} SUB ${figheight} 1000 DIV DIV = `
reg=-R${xl}/${xh}/${yl}/${yh}
reg_km=-Rk`gmt math -Q $xl 1000 DIV =`/`gmt math -Q $xh 1000 DIV =`/`gmt math -Q $yl 1000 DIV =`/`gmt math -Q $yh 1000 DIV =`
map=-Jx1:${ratio}

xl_mis=-345000
xh_mis=-275000
yl_mis=-540000
yh_mis=-480000

xl_mac=-680000
xh_mac=-600000
yl_mac=-920000
yh_mac=-840000

xl_ag=-360000
xh_ag=-300000
yl_ag=260000
yh_ag=380000

gmt makecpt -T15000/17000/1 -Z -Cgray > moa.cpt
gmt makecpt -T1/1000/3+l -Cplasma --COLOR_FOREGROUND=240/249/33 --COLOR_BACKGROUND=13/8/135 > vel.cpt

gmt psbasemap $map $reg -B0 -Xc -Yc -K --MAP_FRAME_TYPE='inside' --PS_MEDIA=50ix50i > ${out}.ps

echo plotting imagery mosaic
gmt grdimage -R -J -O -K $moa -Cmoa.cpt >> ${out}.ps
echo plotting velocity overlay
gmt grdimage -R -J -O -K -Cvel.cpt $vel -t70 -Q >> ${out}.ps

gmt psxy $map $reg -O -K $gl -W0.5p,white >> $out.ps

# plot SARIn mode mask
gmt psxy $sarinout -R -J -O -K -W0.5p,red -L >> $out.ps
gmt psxy $sarinout -R -J -O -K -Gred -t85 -L >> $out.ps
gmt psclip -R -J -O -K $sarinin >> $out.ps
gmt grdimage -R -J -O -K $moa -Cmoa.cpt >> ${out}.ps
gmt grdimage -R -J -O -K $vel -Cvel.cpt -t70 -Q >> $out.ps
gmt psclip -R -J -O -K -C >> $out.ps
gmt psxy $sarinin -R -J -O -K -W0.5p,red -L >> $out.ps

gmt psbasemap -Js0/-90/-71/1:$ratio $reg_km  -Bxa90g90 -Bya10g10 -BNSWE -O -K --MAP_ANNOT_OFFSET_PRIMARY='-2p' --MAP_FRAME_TYPE='inside' --MAP_ANNOT_OBLIQUE=0 --FONT_ANNOT_PRIMARY='8p,grey' --MAP_GRID_PEN_PRIMARY='grey' --MAP_TICK_LENGTH_PRIMARY='-10p' --MAP_TICK_PEN_PRIMARY='thinner,grey' --FORMAT_GEO_MAP='dddF' --MAP_POLAR_CAP='90/90' >> $out.ps

gmt psxy -R -J -O -K -W1p,black -Ap << EOF >> ${out}.ps
0 -88
90 -88
180 -88
270 -88
360 -88
EOF
gmt pstext -R -J -O -K -F+f8p,Helvetica-Bold,black+jBL -D0.05c/0.01c << EOF >> $out.ps
0 -88 ICESat-2
0 -86 ICESat
EOF
gmt pstext -R -J -O -K -F+f8p,Helvetica-Bold,red+jTL -D0.05c/0.01c << EOF >> $out.ps
180 -88 CryoSat-2 SARIn
EOF

gmt psxy -R -J -O -K -W1p,black,4_4:0p -Ap << EOF >> ${out}.ps
0 -86
90 -86
180 -86
270 -86
360 -86
EOF

echo plotting lake outlines
for f in `ls $lakefold/*.xy`
do
    gmt psxy $f $map $reg -O -K -Wthick,blue -Gblue >> $out.ps
done

gmt psxy -R -J -O -K -W1p,black -Gyellow -t50 -L << EOF >> $out.ps
$xl_mis $yl_mis
$xh_mis $yl_mis
$xh_mis $yh_mis
$xl_mis $yh_mis
EOF
gmt pstext -R -J -O -K -F+f12p,Helvetica,white+jBL -D0.1c/0.1c << EOF >> $out.ps
$xh_mis $yh_mis MIS/WIS
$xh_mac $yh_mac MacIS
$xh_ag $yh_ag AG
EOF

gmt psxy -R -J -O -K -W1p,black -Gyellow -t50 -L << EOF >> $out.ps
$xl_mac $yl_mac
$xh_mac $yl_mac
$xh_mac $yh_mac
$xl_mac $yh_mac
EOF

gmt psxy -R -J -O -K  -W1p,black -Gyellow -t50 -L << EOF >> $out.ps
$xl_ag $yl_ag
$xh_ag $yl_ag
$xh_ag $yh_ag
$xl_ag $yh_ag
EOF


barwidth=`gmt math -Q ${figwidth} 10 DIV 0.25 MUL = `
echo $barwidth
gmt psscale -Cvel.cpt -R -J -O -K -DjBL+w${barwidth}c/0.2c+h+o0.5c/0.75c+ml+jBL --FONT_ANNOT_PRIMARY=10p,white --FONT_LABEL=10p,white --MAP_TICK_PEN_PRIMARY=1p,white --MAP_FRAME_PEN=1p,white --MAP_TICK_LENGTH_PRIMARY=3p --MAP_LABEL_OFFSET=5p --MAP_ANNOT_OFFSET_PRIMARY=6p -Bxa+l"ice velocity [m a@+-1@+]" -Q >> $out.ps

gmt psbasemap -R -J -B0 -O >> ${out}.ps

gmt psconvert -Tf -A -P $out.ps
rm $out.ps
open $out.pdf
rm moa.cpt vel.cpt
