basedir='../'
data_fold="${basedir}/data/cs2/baseline_d/"

cs2err=0.49436 # from Siegfried et al., 2014
demerr=0.163 # calculated with calc_dem_uncertainty (value for F12)

for name in `ls ${data_fold}`
do
    echo $name
    ./helper_functions/runLakeTimeSeries-is2dem.sh ${name} cs2err demerr
done

