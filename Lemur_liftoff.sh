liftoff -g GCF_020740605.2_mLemCat1.pri_genomic.gff.gz -o Varecia_rubra_liftoff.gff \
Varecia_rubra.fa GCF_020740605.2_mLemCat1.pri_genomic.fna >& liftoff.nohup

liftofftools synteny -r GCF_020740605.2_mLemCat1.pri_genomic.fna -t Varecia_rubra.fa \
-rg GCF_020740605.2_mLemCat1.pri_genomic.gff.gz -tg Varecia_rubra_liftoff.gff >& liftofftools.nohup
