is1=../../data/is/Mac1_L2a.dat
is2=../../data/is2/atl06.003/Mac1.is2.xyzt
cs21=../../data/cs2/baseline_d/Mac1/Mac1_cs2_SINL2_201910.txt
cs22=../../data/cs2/baseline_d/Mac1/Mac1_cs2_SINL2_201911.txt
cs23=../../data/cs2/baseline_d/Mac1/Mac1_cs2_SINL2_201912.txt
outline=../../data/outlines/xy/Mac1.xy
moa="${DATAHOME}/MODIS/MOA/moa125_2009_hp1_v1.1.nc"
vel="${DATAHOME}/velocity/measures-phase_v1/antarctic_ice_vel_phase_map_v01.nc"


out=siegfried2020-fig2

xl=-645000
xh=-600000
yl=-920000
yh=-875000

wid=5.5
sep=`gmt math -Q ${wid} 0.1 ADD = `
ratio=`gmt math -Q ${xh} ${xl} SUB ${wid} 100 DIV DIV = `
reg=-R${xl}/${xh}/${yl}/${yh}
map=-Jx1:${ratio}

x_arrow=`gmt math -Q $xh $xh $xl SUB 0.19 MUL SUB = `
y_arrow=`gmt math -Q $yl $yh $yl SUB 0.1 MUL ADD = `
vx=`echo $x_arrow $y_arrow | gmt grdtrack -G${vel}?VX | awk '{print $3}'`
vy=`echo $x_arrow $y_arrow | gmt grdtrack -G${vel}?VY | awk '{print $3}'`
v_dir=`gmt math -Q $vy $vx ATAN2 180 MUL PI DIV = `

gmt makecpt -T120/220/1 -Cviridis > z.cpt
gmt makecpt -T15000/17000/1 -Z -Cgray > moa.cpt


gmt grdimage $reg $map $moa -Cmoa.cpt -B0 -Xc -Yc -K --MAP_FRAME_TYPE='inside' --PS_MEDIA=50ix50i > $out.ps
gmt psxy -R -J -O -K $outline -W2p,black >> $out.ps
gmt psxy -R -J -O -K $is1 -Sc0.07c -Cz.cpt -i0,1,2 >> $out.ps

gmt psxy -R -J -O -K -Sv0.5c+eA -W2p,white << EOF >> $out.ps
$x_arrow $y_arrow $v_dir 1
EOF

gmt psxy -R -J -O -K -W2p,white << EOF >> $out.ps
`gmt math -Q $xl 2500 ADD = ` `gmt math -Q $yl 2500 ADD = `
`gmt math -Q $xl 12500 ADD = ` `gmt math -Q $yl 2500 ADD = `
EOF

gmt pstext -R -J -O -K -F+f10p,Helvetica,white+jBC -D0/0.1c << EOF >> $out.ps
`gmt math -Q $xl 7500 ADD = ` `gmt math -Q $yl 2500 ADD = ` 10 km
EOF
gmt pstext -R -J -O -K -F+f12p,Helvetica-Bold,black+jTL -D0.1c/-0.1c << EOF >> $out.ps
${xl} ${yh} a. ICESat (9/03-11/03)
EOF

###### panel b cryosat-2
cat $cs21 $cs22 $cs23 > tmpdata

gmt grdimage -R -J -O -K $moa -Cmoa.cpt -B0 --MAP_FRAME_TYPE='inside' -X${sep}c >> $out.ps
gmt psxy -R -J -O -K $outline -W2p,black >> $out.ps
gmt psxy -R -J -O -K -Sv0.5c+eA -W2p,white << EOF >> $out.ps
$x_arrow $y_arrow $v_dir 1
EOF

gmt psxy -R -J -O -K tmpdata -Sc0.07c -Cz.cpt -i0,1,2 >> $out.ps

gmt psxy -R -J -O -K -W2p,white << EOF >> $out.ps
`gmt math -Q $xl 2500 ADD = ` `gmt math -Q $yl 2500 ADD = `
`gmt math -Q $xl 12500 ADD = ` `gmt math -Q $yl 2500 ADD = `
EOF

gmt pstext -R -J -O -K -F+f10p,Helvetica,white+jBC -D0/0.1c << EOF >> $out.ps
`gmt math -Q $xl 7500 ADD = ` `gmt math -Q $yl 2500 ADD = ` 10 km
EOF

gmt pstext -R -J -O -K -F+f12p,Helvetica-Bold,black+jTL -D0.1c/-0.1c << EOF >> $out.ps
${xl} ${yh} b. CryoSat-2 (10/19-12/19)
EOF


###### panel c icesat-2
yr_in=`gmt math -Q 2019 9 12 DIV ADD = `
yr_out=`gmt math -Q 2019 12 12 DIV ADD = `

gmt grdimage -R -J -O -K $moa -Cmoa.cpt -B0 --MAP_FRAME_TYPE='inside' -X${sep}c >> $out.ps
gmt psxy -R -J -O -K $outline -W2p,black >> $out.ps
gmt psxy -R -J -O -K -Sv0.5c+eA -W2p,white << EOF >> $out.ps
$x_arrow $y_arrow $v_dir 1
EOF

gmt select $is2 -Z${yr_in}/${yr_out}+c3 | gmt psxy -R -J -O -K -Sc0.05c -Cz.cpt -i0,1,2 >> $out.ps

gmt psxy -R -J -O -K -W2p,white << EOF >> $out.ps
`gmt math -Q $xl 2500 ADD = ` `gmt math -Q $yl 2500 ADD = `
`gmt math -Q $xl 12500 ADD = ` `gmt math -Q $yl 2500 ADD = `
EOF

gmt pstext -R -J -O -K -F+f10p,Helvetica,white+jBC -D0/0.1c << EOF >> $out.ps
`gmt math -Q $xl 7500 ADD = ` `gmt math -Q $yl 2500 ADD = ` 10 km
EOF
gmt pstext -R -J -O -K -F+f12p,Helvetica-Bold,black+jTL -D0.1c/-0.1c << EOF >> $out.ps
${xl} ${yh} c. ICESat-2 (10/19-12/19)
EOF

barwidth=`gmt math -Q ${wid} 2 MUL = `
echo $barwidth
gmt psscale -Cz.cpt -R -J -O -Dn-0.5/0+w${barwidth}c/0.2c+h+o0c/0.1c+jTC --FONT_ANNOT_PRIMARY=10p --FONT_LABEL=10p --MAP_ANNOT_OFFSET_PRIMARY=4p --MAP_TICK_PEN_PRIMARY=1p --MAP_TICK_LENGTH_PRIMARY=4p --MAP_LABEL_OFFSET=2p -Bxa20f10+l"elevation [m]" >> $out.ps

gmt psconvert -Tf -A -P $out.ps
gmt psconvert -Tg -A -P $out.ps
open $out.pdf
rm z.cpt moa.cpt $out.ps tmpdata
