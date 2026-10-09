#!/bin/bash

#create list of chrs to pass to vcftools when making plink input file (only need to do once)
#cut -f 1 ~/USS/lemurs/ABBA_BABA/Dfoil3/no_ig_reg_vrubra.txt \
#| uniq | awk '{print $0"\t"$0}' > no_ig_reg_vrubra.chrom-map.txt

POP=$1 #Varu_Andranobe, Vava_Ranomafana

OUTFILE=${POP}_${i}.filtsnps_500k
OUTDIR=~/USS/lemurs/gone_reps_noig

cd ${OUTDIR}

#subset global vcf
bcftools view -S <(awk -v pop=$POP '$3==pop {print $1}' ~/USS/lemurs/Treemix/WildVarecia_4treemix.clust) \
-o ${POP}_SUPERautoz_noig.filtsnps1.vcf.gz -O z --threads 12 \
-R ~/USS/lemurs/ABBA_BABA/Dfoil3/no_ig_reg_vrubra.txt ~/USS/lemurs/AllVarecia_SUPERautoz.filtsnps.vcf.gz

#select filter out multiallelic and non-snps
bcftools view -m2 -M2 --types snps -O z \
-o ${POP}_SUPERautoz_noig.filtsnps.vcf.gz --threads 12 \
${POP}_SUPERautoz_noig.filtsnps1.vcf.gz

rm ${POP}_SUPERautoz_noig.filtsnps1.vcf.gz

bcftools sort -o ${POP}_SUPERautoz_noig_sort.filtsnps.vcf.gz \
-O z ${POP}_SUPERautoz_noig.filtsnps.vcf.gz

#make plink file from vcf
vcftools --gzvcf ${POP}_SUPERautoz_noig_sort.filtsnps.vcf.gz \
--chrom-map no_ig_reg_vrubra.chrom-map.txt \
--out ${POP}_SUPERautoz_noig.filtsnps --plink >& vcf2plink.nohup

plink -file ${POP}_SUPERautoz_noig.filtsnps --geno 0 \
--recode --allow-extra-chr --maf 0.05 --thin-count 500000 \
--out ${POP}_SUPERautoz_noig.filtsnps_500k --double-id \
--chr SUPER_1 SUPER_2 SUPER_3 SUPER_4 SUPER_5 SUPER_6 SUPER_7 \
SUPER_8 SUPER_9 SUPER_10 SUPER_11 SUPER_12 SUPER_13 SUPER_14 \
SUPER_15 SUPER_16 
#SUPER_17 SUPER_18 SUPER_19 SUPER_20 SUPER_21 SUPER_22 
#need to exclude SUPER_17 SUPER_19 SUPER_20 because they're too small now (<20MB, at least with introgression exclusion)

for i in `seq 2 50`; do

plink -file ${POP}_SUPERautoz_noig.filtsnps_500k \
--recode --allow-extra-chr --thin-count 20000 \
--out ${POP}_SUPERautoz_noig.filtsnps_20k_${i} --double-id \
--chr SUPER_1 SUPER_2 SUPER_3 SUPER_4 SUPER_5 SUPER_6 SUPER_7 \
SUPER_8 SUPER_9 SUPER_10 SUPER_11 SUPER_12 SUPER_13 SUPER_14 \
SUPER_15 SUPER_16 
#--keep <(awk '{print $1"\t"$1}' ../SampleLists/Varu_Andranobe_2019_unrelated.txt) \

#gone doesn't randomly thin
~/USS/aryn/Programs/GONE2/gone2 -t 12 -r 1 -x \
-o ${POP}_SUPERautoz_noig_${i} \
${POP}_SUPERautoz_noig.filtsnps_20k_${i}.ped

done

for i in `seq 1 50`; do

~/USS/aryn/Programs/GONE2/gone2 -t 12 -r 1 \
-o ${POP}_SUPERautoz_noig_${i} \
${POP}_SUPERautoz_noig.filtsnps_20k_${i}.ped

done


