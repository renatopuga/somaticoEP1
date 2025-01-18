# instalar utilizando o brew install (gitpod)
brew install sratoolkit

# parallel fastq-dump
# https://github.com/rvalieris/parallel-fastq-dump
pip install parallel-fastq-dump

# rodar validate
# aperte a tecla X para sair
# vdb-config
echo "Aexyo" | vdb-config -i

# fastq-dump: comando que faz o download do arquivo utilizando o SRR ID da amostra
# -I: --readids da amostra
# --split-files: ele vai separar os arquivos fastq em 1 e 2 (paired)
time parallel-fastq-dump --sra-id SRR8856724 --threads 4 --outdir ./ --split-files --gzip

# AS Referências do Genoma hg38 (FASTA, VCFs)
# Os arquivos de Referência: Panel of Normal (PoN), Gnomad AF e Exac common:
# https://console.cloud.google.com/storage/browser/gatk-best-practices/somatic-hg38?project=broad-dsde-outreach
wget -c https://storage.googleapis.com/gatk-best-practices/somatic-hg38/af-only-gnomad.hg38.vcf.gz

wget -c https://storage.googleapis.com/gatk-best-practices/somatic-hg38/af-only-gnomad.hg38.vcf.gz.tbi

wget -c https://storage.googleapis.com/gatk-best-practices/somatic-hg38/1000g_pon.hg38.vcf.gz

wget -c https://storage.googleapis.com/gatk-best-practices/somatic-hg38/1000g_pon.hg38.vcf.gz.tbi

# Arquivo no formato FASTA do genoma humano hg38
# Diretório Download UCSC hg38: https://hgdownload.soe.ucsc.edu/goldenPath/hg38/chromosomes/
# chr9.fa.gz: https://hgdownload.soe.ucsc.edu/goldenPath/hg38/chromosomes/chr9.fa.gz
wget -c https://hgdownload.soe.ucsc.edu/goldenPath/hg38/chromosomes/chr9.fa.gz

# BWA para mapeamento dos arquivos FASTQ (gitpod)
# Instalando o BWA no gitpod
brew install bwa 

# descompacta o arquivo gz
gunzip chr9.fa.gz

# bwa index para indexar o arquivo .fa (~5min)
bwa index chr9.fa

# Samtools faidx
brew install samtools 
samtools faidx chr9.fa

# BWA-mem para fazer o alinhamento (FASTQ -> BAM)

NOME=WP312; Biblioteca=Nextera; Plataforma=illumina;
bwa mem -t 13 -M -R "@RG\tID:$NOME\tSM:$NOME\tLB:$Biblioteca\tPL:$Plataforma" \
chr9.fa \
SRR8856724_1.fastq.gz \
SRR8856724_2.fastq.gz > WP312.sam

# delete dados intermediarios
rm -f SRR8856724_1.fastq.gz SRR8856724_2.fastq.gz

# samtools: fixmate, sort e index (~min)

# -@ numero de cores utilizados
time samtools fixmate -@10 WP312.sam WP312.bam

# delete dados intermediarios
rm -f WP312.sam

# ordenando o arquivo fixmate
time samtools sort -O bam -@6 -m2G -o WP312_sorted.bam WP312.bam

# delete dados intermediarios
rm -f WP312.bam

# indexando o arquivo BAM ordenado (sort)
time samtools index WP312_sorted.bam

# abordagem de target sequencing utilizamos o rmdup para remover duplicata de PCR
time samtools rmdup WP312_sorted.bam WP312_sorted_rmdup.bam

# delete dados intermediarios
rm -f WP312_sorted.bam

# indexando o arquivo BAM rmdup
time samtools index WP312_sorted_rmdup.bam 

# Cobertura - make BED files
# Instalação do bedtools
brew install bedtools

# Gerando BED do arquivo BAM
bedtools bamtobed -i WP312_sorted_rmdup.bam > WP312_sorted_rmdup.bed
bedtools merge -i WP312_sorted_rmdup.bed > WP312_sorted_rmdup_merged.bed
bedtools sort -i WP312_sorted_rmdup_merged.bed > WP312_sorted_rmdup_merged_sorted.bed

# Cobertura Média
bedtools coverage -a WP312_sorted_rmdup_merged_sorted.bed \
-b WP312_sorted_rmdup.bam -mean > WP312_coverageBed.bed

# Filtro por total de reads >=20
cat WP312_coverageBed.bed | awk -F "\t" '{if($4>20){print}}' > WP312_coverageBed20x.bed

# GATK4 instalação (MuTect2 com PoN)
# Download
wget -c https://github.com/broadinstitute/gatk/releases/download/4.2.2.0/gatk-4.2.2.0.zip

# Descompactar
unzip gatk-4.2.2.0.zip 

# Gerar arquivo .dict
./gatk-4.2.2.0/gatk CreateSequenceDictionary -R chr9.fa -O chr9.dict

# Gerar interval_list do chr9
./gatk-4.2.2.0/gatk ScatterIntervalsByNs -R chr9.fa -O chr9.interval_list -OT ACGT

# Converter Bed para Interval_list
./gatk-4.2.2.0/gatk BedToIntervalList -I WP312_coverageBed20x.bed \ 
-O WP312_coverageBed20x.interval_list -SD chr9.dict

# GATK4 - CalculateContamination
./gatk-4.2.2.0/gatk GetPileupSummaries \
	-I WP312_sorted_rmdup.bam  \
	-V af-only-gnomad.hg38.vcf.gz \
	-L chr9.interval_list \
	-O WP312.table
./gatk-4.2.2.0/gatk CalculateContamination \ 
-I WP312.table \
-O WP312.contamination.table

# GATK4 - MuTect2 Call
./gatk-4.2.2.0/gatk Mutect2 \
  -R chr9.fa \
  -I WP312_sorted_rmdup.bam \
  --germline-resource af-only-gnomad.hg38.vcf.gz  \
  --panel-of-normals 1000g_pon.hg38.vcf.gz \
  -L WP312_coverageBed20x.interval_list \
  -O WP312.somatic.pon.vcf.gz

# GATK4 - MuTect2 FilterMutectCalls
./gatk-4.2.2.0/gatk FilterMutectCalls \
	-R chr9.fa \
	-V WP312.somatic.pon.vcf.gz \
	--contamination-table WP312.contamination.table \
	-O WP312.filtered.pon.vcf.gz
