#!/bin/bash

module unload intel-mkl/2019
module load intel-mkl/2019-gcc8
module load netcdf-hdf5-all/4.7_hdf5-1.10-gcc8-impi
module load r/4.0.2-gcc8-mkl

#TODO go into the directory as mentioned in the header commands
STILT_model=/gpfs/scratch/pr48ze/ga62kuy2/STILT_HAM
met_file=/dss/dsstumfs01/pn69ki/pn69ki-dss-0004/STILT/Hamburg/arl

cd $STILT_model
cd r

limit=10

year=2021
month=9
day=$(seq 7 9)

#TODO prepare the running script for creating the .rds file, run_stilt.r and merge_fp.r

for line in $day

do

	yy=$year

	echo "year=$yy"

	mm=$month

	echo "month=$mm"	

	if  [ "$mm" -lt "$limit" ]; then

	    mm_m=$(printf "%01d"$(echo $mm))

	else

	    mm_m=$(echo $mm)
	fi

  dd=$line
	echo "day=$dd"  

	if  [ "$dd" -lt "$limit" ]; then

	    dd_day=$(printf "%01d"$(echo $dd))

	else

	    dd_day=$(echo $dd)

	fi

  echo "STILT simulation for year $yy month $mm_m day $dd_day"

	date=$yy$mm_m$dd_day

	sed -e "s/$(echo $yy)-01-01/$(echo $yy)-$mm_m-$dd_day/g" -e "s/$(echo $yy)0101/$date/g" template_script/receptor_list_template_HAM.r >  receptor_list_$date.r

  Rscript receptor_list_$date.r

	FILE=$STILT_model/r/HAM_$(echo $date)_receptors_ERA5.rds

	if [ -f "$FILE" ];then

		sed -e "s/20210101/$date/g"  template_script/run_stilt_htus_HAM.r >  run_stilt_htus_HAM_$date.r

    Rscript run_stilt_htus_HAM_$date.r > script$date.Rout

		sed -e "s/20210101/$date/g" template_script/merge_fp_template.r >  merge_fp_$date.r

	else
		
		echo "there is no fp on" $date
 
	fi

  sleep 300

done

