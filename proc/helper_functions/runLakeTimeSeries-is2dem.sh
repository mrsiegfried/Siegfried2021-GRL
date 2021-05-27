    ### Written 27 Mar 2015 by MRS
### Takes the name of a lake and runs the CryoSat-2 data for it.
### USAGE: runOneLake.sh name

if [[ $# -ne 3 ]]; then
    echo ERROR: requires exactly one input
    echo USAGE: $0 lake_name demrez cs2err demerr
    exit 1
fi

name=$1
cs2err=$2
demerr=$3
err_sing_pt=`gmt math -Q $cs2err 2 POW $demerr 2 POW ADD 0.5 POW = `

block=10000
basedir='..'
outline="${basedir}/data/outlines/xy/${name}.xy"
fold="${basedir}/data/cs2/baseline_d/${name}"
thisoutfold="${basedir}/data/cs2/proc_out/${name}"
demgrd="${basedir}/data/is2/atl06.003/${name}_dem.nofilt.nc"

if [ ! -d $outfold/$name ]; then
  mkdir $outfold/$name
fi

if [ ! -f $outline ]; then
  echo cant find the outline
  exit 1
fi
echo found outline at $outline

if [ ! -f $demgrd ]; then
  echo cant find the IS2 DEM grid file
  exit 1
fi
echo found IS2 DEM grd at $demgrd
min_x=`gmt grdinfo -C -I1000/1000 $demgrd | awk '{print $2}'`
max_x=`gmt grdinfo -C -I1000/1000 $demgrd | awk '{print $3}'`
min_y=`gmt grdinfo -C -I1000/1000 $demgrd | awk '{print $4}'`
max_y=`gmt grdinfo -C -I1000/1000 $demgrd | awk '{print $5}'`


rawfile=$thisoutfold/"$name"_dem.cs2.dat
datafile=$thisoutfold/"$name"_elevs.dat

mkdir mydemdir${name}
cd mydemdir${name}

#### uncomment block to start from beginning
    ##setup the final data file
    echo '#num month (since 2010) | mean elev IN | std elev IN | num pts IN | mean elev OUT | std elev OUT | num pts OUT' > ../$datafile

echo correcting $name data
mkdir justaworkingdir${name}
cp ../$fold/*.txt justaworkingdir${name}/
cd justaworkingdir${name}


for yr in 10 11 12 13 14 15 16 17 18 19 20
do
    for mth in 1 2 3 4 5 6 7 8 9 10 11 12
    do
        if [[ $mth -lt 10 ]]; then
            yrmth="$yr"0"$mth"
        else
            yrmth="$yr""$mth"
        fi
        yrmth2=`gmt math -Q $yrmth 1 ADD = `
        yrmth3=`gmt math -Q $yrmth2 1 ADD = `
        
        if [[ `expr ${yrmth2:2:2}` -gt 12 ]]; then
            yrmth2=`gmt math -Q $yrmth2 12 SUB 100 ADD = `
        fi
        if [[ `expr ${yrmth3:2:2}` -gt 12 ]]; then
            yrmth3=`gmt math -Q $yrmth3 12 SUB 100 ADD = `
        fi
        
        if [[ $yrmth2 -gt 1007 && $yrmth2 -lt 2007 ]]; then
            file1=*"$yrmth".txt
            file2=*"$yrmth2".txt
            file3=*"$yrmth3".txt

            f="$name"20"$yrmth2"

            echo $yrmth2
            cat $file1 $file2 $file3 | gmt select $REG -o0,1,2,3,4,5 | gmt grdtrack -G../../$demgrd > $f.corr.unfilt

            echo working on $f.corr.unfilt
            echo ' ' > $f.corr

            for (( x=min_x; x<max_x; x=x+$block ))
            do
                for (( y=min_y; y<max_y; y=y+$block ))
                do
                    xh=`gmt math -Q $x $block ADD = `
                    yh=`gmt math -Q $y $block ADD = `
                    thisreg=-R$x/$xh/$y/$yh

                    echo $thisreg
                    gmt select $thisreg $f.corr.unfilt > thisfilerighthere
                    if [ `wc -l thisfilerighthere | awk '{print $1}'` -gt 5 ]; then
                        gmt math thisfilerighthere -C2 6 COL SUB = tmpdata2
                        threeSigFilt.sh -c tmpdata2 0.05 tmpdata3
                        cat tmpdata3 >> $f.corr
                        rm tmpdata2 tmpdata3 thisfilerighthere
                    fi
                done
            done

            rm $f.corr.unfilt

            # step 3: find data in and out of lake, take mean and std
            year=20"$yr"
            monthnum=`gmt math -Q $year 2010 SUB 12 MUL $mth ADD 0.5 ADD 12 DIV 2010 ADD = `

            gmt select -F../../$outline $f.corr > in
            gmt select -F../../$outline -If $f.corr > out
            nIN=`wc -l in | awk '{print $1}'`
            nOUT=`wc -l out | awk '{print $1}'`

            if [ $nIN -gt 20 -a $nOUT -gt 20 ]; then
                meanIN=`gmt math in -C2 MEAN -S -T -o2 = `
                meanOUT=`gmt math out -C2 MEAN -S -T -o2 = `
                medianIN=`gmt math in -C2 MEDIAN -S -T -o2 = `
                medianOUT=`gmt math out -C2 MEDIAN -S -T -o2 = `
                stdIN=`gmt math in -C2 STD -S -T -o2 = `
                stdOUT=`gmt math out -C2 STD -S -T -o2 = `
                
                in_lake_err=`gmt math -Q $err_sing_pt $nIN 0.5 POW DIV = `
                out_lake_err=`gmt math -Q $err_sing_pt $nOUT 0.5 POW DIV = `
                echo $monthnum,$meanIN,$stdIN,$in_lake_err,$nIN,$meanOUT,$stdOUT,$out_lake_err,$nOUT,$medianIN,$medianOUT >> ../../$datafile
            fi

            rm in out $file1


            if [ ! -d ../../$fold/corr ]; then
                mkdir ../../$fold/corr
            fi
            mv -v *.corr ../../$fold/corr/
        fi
    done
done
cd ..

rm -r justaworkingdir${name}

cd ..
rm -r mydemdir${name}
