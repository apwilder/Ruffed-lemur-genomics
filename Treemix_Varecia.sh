################Treemix##############################
nohup bcftools view -S WildVarecia_4treemix.samples ../GATK/AllVarecia_SUPERautoz.filtsnps.vcf.gz \
-O z -o WildVarecia_4treemix_SUPERautoz.filtsnps.vcf.gz &

nohup ./vcf2treemix.sh WildVarecia_4treemix_SUPERautoz.filtsnps.vcf.gz \
WildVarecia_4treemix.clust &

#python2 plink2treemix.py $file".frq.strat.gz" $file".treemix.frq.gz"

i=0
FILE=WildVarecia_4treemix_SUPERautoz.filtsnps
for i in {0..6}
do
nohup treemix -i $FILE.treemix.frq.gz -m $i -o $FILE.$i -bootstrap -k 1000 > treemix_${i}_log &
done
