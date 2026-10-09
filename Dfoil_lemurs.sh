cd ~/USS/lemurs/ABBA_BABA/vcfs2/

dfoil_par() {

SCAF=$1
CHR=$1

ls *${SCAF}.g.vcf.gz > ${SCAF}.list

for FL in `cat ${SCAF}.list`; do
if [[ ! -e ${FL}.tbi ]]; then
gatk IndexFeatureFile -I $FL
fi
done

gatk CombineGVCFs --variant ${SCAF}.list \
-R ~/USS/lemurs/RefGenomes/GCF_020740605.2_mLemCat1.pri_genomic.fna \
-O ${SCAF}.gvcf.gz

bcftools view -i 'INFO/DP<900 & INFO/DP>100' -O z -o ${SCAF}_2.gvcf.gz ${SCAF}.gvcf.gz

tabix -f ${SCAF}_2.gvcf.gz

gatk --java-options "-Xmx4g" GenotypeGVCFs \
-R ~/USS/lemurs/RefGenomes/GCF_020740605.2_mLemCat1.pri_genomic.fna \
--tmp-dir ~/USS/lemurs/ABBA_BABA/vcfs2/tmp --max-alternate-alleles 1 \
-V ${SCAF}_2.gvcf.gz -O ${SCAF}.vcf.gz

bcftools view --include 'AN=10' -O z -o ${CHR}_filt.vcf.gz \
-m2 -M2 -v snps ${CHR}.vcf.gz

tabix -f ${CHR}_filt.vcf.gz

}

export -f dfoil_par

parallel -j 4 --tmpdir ../vcfs/tmp dfoil_par \
:::: <(awk '$2>10000000 {print $1}' \
~/USS/lemurs/RefGenomes/GCF_020740605.2_mLemCat1.pri_genomic.fna.fai) \
 >& par_dfoil.out


for VCF in `ls ../vcfs2/*_filt.vcf.gz`; do
CHR=`basename $VCF | sed 's/_filt.vcf.gz//g'`

python vcf2DFOIL.py <(bcftools view -s bl_29151,bl_29145,15051,bl_100-556,Lcatta $VCF) \
10000000 ${CHR}_vcf_dfoil.in

python ~/USS/lemurs/ABBA_BABA/Dfoil/dfoil/dfoil.py --infile ${CHR}_vcf_dfoil.in --out ${CHR}_vcf_dfoil.out

python ~/USS/lemurs/ABBA_BABA/Dfoil/dfoil/dfoil_analyze.py ${CHR}_vcf_dfoil.out > ${CHR}_dfoil.out

done



