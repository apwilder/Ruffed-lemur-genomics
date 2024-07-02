#!/bin/bash

vcftools --gzvcf ../GATK/AllVarecia_SUPERautoz.filtsnps.vcf.gz \
--weir-fst-pop ../SampleLists/Vava_Wild_samples.txt \
--weir-fst-pop ../SampleLists/Varu_Wild_samples.txt \
--fst-window-size 500000 --fst-window-step 50000 \
--out Wild_Vava_Varu_Fst_500w_50s
