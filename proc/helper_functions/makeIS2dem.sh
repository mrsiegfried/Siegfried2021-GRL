if [[ $# -ne 2 ]]; then
    echo ERROR: requires exactly two inputs
    echo USAGE: $0 subsetfolder demresolution
    exit 1
fi

fold=$1
demrez=$2

for file in `ls ${fold}/*.xyzt`
do
    stem=`basename $file .is2.xyzt`
    demgrd=${fold}/${stem}_dem.nofilt.nc # file to save
    echo gridding $stem data
    REG=`gmt info -I1000/1000 $file`
    gmt blockmean $file $REG -I$demrez -i0,1,2 > mean.xyz
    gmt surface $REG -I$demrez mean.xyz -G$demgrd -T0.7 -V
    rm mean.xyz
    
    gmt grdtrack -G$demgrd $file > $fold/$stem.is2.xyztz
    
done
