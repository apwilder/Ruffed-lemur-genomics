#!/bin/bash

SAMPLES=$1 #/home/centos/USS/lemurs/SampleLists/Varu_Andranobe_1970.txt
INFILE=$2 #AllVarecia_SUPERautoz
INDIR=$3 #/home/centos/USS/lemurs/plink
OUTFILE=$4 #Andranobe_1970_SUPERautoz100K
OUTDIR=$5 #/home/centos/USS/lemurs/GONE/Lemurs

cd $INDIR

plink --keep <(awk '{print $1"\t"$1}' ${SAMPLES}) --maf 0.05 \
--recode --allow-extra-chr --thin-count 100000 \
--file $INFILE --out /home/centos/USS/lemurs/GONE/Linux/${OUTFILE} --double-id --threads 8

cd /home/centos/USS/lemurs/GONE/Linux

sed -i 's/SUPER_//g' ${OUTFILE}.map
awk 'sum+=1 {print $1"\t"sum"\t"$3"\t"$4}' ${OUTFILE}.map > ${OUTFILE}.map2
mv ${OUTFILE}.map2 ${OUTFILE}.map

#run script from GONE program
bash script_GONE.sh ${OUTFILE}

mv *${OUTFILE}* ${OUTDIR}/
