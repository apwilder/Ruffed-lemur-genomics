lemurMapping() {
FASTQ=$1
SM=$2
PREFIX=$3
FQDIR=/home/centos/USS/lemurs/TrimmedFastq
OUTDIR=/home/centos/USS/lemurs/ABBA_BABA

bwa mem -t 6 -M -R "@RG\tID:${SM}\tSM:${SM}\tLB:${FASTQ}\tPL:Illumina\t" \
/home/centos/USS/lemurs/RefGenomes/GCF_020740605.2_mLemCat1.pri_genomic.fna ${FQDIR}/${FASTQ}_AdptTrim_P1.fastq.gz \
${FQDIR}/${FASTQ}_AdptTrim_P2.fastq.gz | \
samtools view -@ 6 -bS -F 4 -o ${OUTDIR}/${PREFIX}_${FASTQ}_mLemCat1.bam -
}

#export the function
export -f lemurMapping

#Launch in parallel. Each job takes at least 6 CPU, but I'd plan on each job using 8 since the function pipes into samtools.
#j=the maximum number of jobs to run simultaneously
#colsep= the input file has input variable separated by tabs
#test_in.txt is a tab-delimited file, one line per sample listing the fastq basename, sample name I want in the bam header, and prefix for the output file

parallel --colsep '\t' lemurMapping :::: FastqList_rerun.txt >& remap_missing.log
#parallel --colsep '\t' -j 4 lemurMapping :::: <(cut -f 1,2,6 /home/centos/USS/lemurs/SampleLists/AllVarecia_SampleTable_unmappedFeb.txt)

###Sort####
conda activate sambamba
cd ~/USS/lemurs/ABBA_BABA

lemurSort() {
BAM=$1

sambamba sort --tmpdir=tmp -t 6 -m 20G $BAM
}

#export the function
export -f lemurSort

parallel --tmpdir tmp lemurSort :::: bamlist_rerun.txt >& parsort.out

###Dedup###
lemurDedup() {
BAM=$1
SAMPLE=`echo $BAM | sed 's/.bam//g'`

sambamba markdup -r -t 6 --sort-buffer-size=20084 --tmpdir=tmp --overflow-list-size 1000000 \
${SAMPLE}.sorted.bam ${SAMPLE}_dedup.bam >& ${SAMPLE}_dedup.nohup
}

#export the function
export -f lemurDedup

parallel --tmpdir tmp --colsep '\t' lemurDedup :::: bamlist_rerun.txt \
>& pardedup2.out

ls *_mLemCat1_dedup.bam > lemur_ABBA_bamlist.txt

####GATK####
conda activate gatk4
gatk CreateSequenceDictionary -R /home/centos/USS/lemurs/RefGenomes/GCF_020740605.2_mLemCat1.pri_genomic.fna

gatkjob() {

BAM=$1
INT=$2

ID=`basename ${BAM} | sed 's/_mLemCat1_dedup.bam//g'`

gatk --java-options "-Xmx5g" HaplotypeCaller \
-R /home/centos/USS/lemurs/RefGenomes/GCF_020740605.2_mLemCat1.pri_genomic.fna \
-I ${BAM} \
-O /home/centos/USS/lemurs/ABBA_BABA/${ID}_mLemCat1_${INT}.g.vcf.gz \
--output-mode EMIT_ALL_CONFIDENT_SITES -ERC GVCF \
--tmp-dir /home/centos/USS/lemurs/ABBA_BABA/tmp -L ${INT} \
>& /home/centos/USS/lemurs/ABBA_BABA/gatknohups/${ID}_${INT}_gvcf.out 

}

export -f gatkjob

parallel --tmpdir tmp gatkjob :::: lemur_ABBA_bamlist.txt \
:::: <(awk '{print $1}' /home/centos/USS/lemurs/RefGenomes/GCF_020740605.2_mLemCat1.pri_genomic.fna.fai) >& pargatk.out

#######CombineGVCFs####################################################################################
conda activate gatk4

gatk_cg() {

SCAF=$1

ls *${SCAF}.g.vcf.gz > ${SCAF}.list

gatk CombineGVCFs --variant ${SCAF}.list \
-R /home/centos/USS/lemurs/RefGenomes/GCF_020740605.2_mLemCat1.pri_genomic.fna \
-O ${SCAF}.gvcf.gz

}

export -f gatk_cg

parallel --tmpdir tmp gatk_cg :::: <(awk '{print $1}' \
/home/centos/USS/lemurs/RefGenomes/GCF_020740605.2_mLemCat1.pri_genomic.fna.fai) \
>& pargatk_gc.out


##########GenotypeGVCFs#######################################################################################
conda activate gatk4

gatk_gg() {

SCAF=$1

gatk --java-options "-Xmx4g" GenotypeGVCFs \
-R /home/centos/USS/lemurs/RefGenomes/GCF_020740605.2_mLemCat1.pri_genomic.fna \
--tmp-dir /home/centos/USS/lemurs/ABBA_BABA/tmp \
-V ${SCAF}.gvcf.gz -O ${SCAF}.vcf.gz
#--include-non-variant-sites \

}

export -f gatk_gg

parallel -j 20 --tmpdir tmp gatk_gg \
:::: <(awk '{print $1}' \
/home/centos/USS/lemurs/RefGenomes/GCF_020740605.2_mLemCat1.pri_genomic.fna.fai) \
 >& pargatk_gg.out


################Filter and ABBA-BABA############################
conda activate baseclone

abba_baba() {
SCAF=$1

bcftools query -f'%CHROM %POS %QUAL %DP\n' ${SCAF}.vcf.gz > ${SCAF}.QUAL_DP.txt #-i'QUAL>20 && DP>10' 
bcftools view -i'QUAL>30 && INFO/DP<308 && INFO/DP>50' ${SCAF}.vcf.gz | bgzip > ${SCAF}_filt.vcf.gz


~/USS/lemurs/ABBA_BABA/Dsuite/Build/Dsuite Dtrios -c -t lemur_tree.txt \
-o ${SCAF}_Dtrios ${SCAF}_filt.vcf.gz lemur_sets.txt

}

export -f abba_baba

parallel -j 28 --tmpdir tmp abba_baba \
:::: <(awk '{print $1}' \
/home/centos/USS/lemurs/RefGenomes/GCF_020740605.2_mLemCat1.pri_genomic.fna.fai) \
 >& abba_baba.out



conda activate baseclone

abba_baba() {
SCAF=$1

~/USS/lemurs/ABBA_BABA/Dsuite/Build/Dsuite Dinvestigate -n ${SCAF} \
${SCAF}_filt.vcf.gz lemur_sets.txt test_trios.txt
}

export -f abba_baba

parallel -j 28 --tmpdir tmp abba_baba \
:::: <(awk '{print $1}' \
/home/centos/USS/lemurs/RefGenomes/GCF_020740605.2_mLemCat1.pri_genomic.fna.fai) \
 >& abba_baba.out
