# Ruffed-lemur-genomics
This repository holds the scripts used for the analysis of ruffed lemur population genomics.
Raw fastqs were trimmed (Lemur_trimmomatic), mapped to the reference genome (bwa_parallel), sorted and deduplicated (Sort_dedup_parallel). 
We called genotypes using GATK HaplotypeCaller (gatk_HC_parallel), then combined and genotyped individual gvcfs at the population level (GenotypeGVCFs_parallel) and filtered the vcf (filter_vcfs).
We ran PCAs and estimated relatedness in plink (plink_PCA), estimated Fst (Fst_windows), heterozygosity (pixy_parallel) and ROH (bcftools_roh).
We estimated recent Ne using GONE (Lemur_GONE.sh). We ran ABBA-BABA (ABBA_BABA_parallel.sh) and Dfoil tests (Dfoil_lemurs.sh), then reran Ne estimation using GONE2 excluding introgressed regions of the genome (Lemur_GONE2_nointrogression.sh).
