# Pipeline somático: Exercício 1

# Tempo de Processamento

| Infraestrutura | CPU  | Memória (GB) | Storage (GB) | Etapa             | Tempo           |
| -------------- | ---- | ------------ | ------------ | ----------------- | --------------- |
| gitpod         | 16   | 64           | ?DD 30       | FASTQ -> SAM      | 55-61min (chr9) |
|                |      |              |              | SAM -> BAM        | 13-18min        |
|                |      |              |              | BAM -> SORT_BAM   | ~6-12min        |
|                |      |              |              | SORT_BAM -> RMDUP | ~12 min         |
| servidor local | 16   | 32           | SSD 30       | todas as etapas   | ~2h (hg19)      |


# Shotgun e Amplicon

<img width="1438" alt="Screen Shot 2022-10-28 at 22 55 11" src="https://user-images.githubusercontent.com/8321336/198762626-8a788ca0-d5f9-495b-a96b-7ae807ba071b.png">


# Workflow

1. **O arquivo no NCBI da amostra WP312 (tumor)**

   1. Projeto SRA: https://www.ncbi.nlm.nih.gov/Traces/study/?acc=SRP190048&o=bases_l%3Aa

   2. ID: [SRR8856724](https://trace.ncbi.nlm.nih.gov/Traces/sra?run=SRR8856724)

   3. Precisa instalar o sratoolkit **(dentro do gitpod)**

      1. ```bash
         # instalar utilizando o brew install (gitpod)
         brew install sratoolkit
         
         # parallel fastq-dump
         # https://github.com/rvalieris/parallel-fastq-dump
         pip install parallel-fastq-dump
      
         # rodar validate
         echo "Aexyo" | vdb-config -i

         # caso o vdb-config não funcione
 	 wget -c https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/3.0.0/sratoolkit.3.0.0-ubuntu64.tar.gz
   	 tar -zxvf sratoolkit.3.0.0-ubuntu64.tar.gz
         echo "Aexyo" | sratoolkit.3.0.0-ubuntu64/bin/vdb-config
         ```

      2. ```bash
         # fastq-dump: comando que faz o download do arquivo utilizando o SRR ID da amostra
         # --sra-id: SRR 
         # --threads 4: paraleliza em 4 partes o download
         # --gzip: fastq compactados
         # --split-files: ele vai separar os arquivos fastq em 1 e 2 (paired)
         time parallel-fastq-dump --sra-id SRR8856724 --threads 4 --outdir ./ --split-files --gzip
         ```

      3. Google Colab sratoolkit (modo alternativo)

```bash
# download do binário ubuntu 64bits
%%bash
wget -c https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/3.0.0/sratoolkit.3.0.0-ubuntu64.tar.gz
          
# -z unzip
# -x extract
# -v verbose
# -f force?
tar -zxvf sratoolkit.3.0.0-ubuntu64.tar.gz
          
# validate
./sratoolkit.3.0.0-ubuntu64/bin/vdb-config
          
# adicionando o diretorio dos programas no path
export PATH=$PATH:/content/sratoolkit.3.0.0-ubuntu64/bin/
	  
# downlaod parallel
parallel-fastq-dump --sra-id SRR8856724 --threads 6 --outdir ./ --split-files --gzip --tmpdir /content/
```




2. **AS Referências do Genoma hg38 (FASTA, VCFs)**

   1. Os arquivos de Referência: **Panel of Normal (PoN), Gnomad AF e Exac common:**

      1.  https://console.cloud.google.com/storage/browser/gatk-best-practices/somatic-hg38?project=broad-dsde-outreach

      ```bash
      wget -c https://storage.googleapis.com/gatk-best-practices/somatic-hg38/af-only-gnomad.hg38.vcf.gz
      ```

      ```bash
      wget -c https://storage.googleapis.com/gatk-best-practices/somatic-hg38/af-only-gnomad.hg38.vcf.gz.tbi
      ```

      ```bash
      wget -c https://storage.googleapis.com/gatk-best-practices/somatic-hg38/1000g_pon.hg38.vcf.gz
      ```

      ```bash
      wget -c https://storage.googleapis.com/gatk-best-practices/somatic-hg38/1000g_pon.hg38.vcf.gz.tbi
      ```

      ```bash
      wget -c https://storage.googleapis.com/gatk-best-practices/somatic-hg38/small_exac_common_3.hg38.vcf.gz
      ```

      ```bash
      wget -c https://storage.googleapis.com/gatk-best-practices/somatic-hg38/small_exac_common_3.hg38.vcf.gz.tbi
      ```

      

   2. Arquivo no formato FASTA do genoma humano hg38

      1. Diretório Download UCSC hg38: https://hgdownload.soe.ucsc.edu/goldenPath/hg38/chromosomes/

         1. chr9.fa.gz: https://hgdownload.soe.ucsc.edu/goldenPath/hg38/chromosomes/chr9.fa.gz

            ```bash
            wget -c https://hgdownload.soe.ucsc.edu/goldenPath/hg38/chromosomes/chr9.fa.gz
            ```



3. **BWA para mapeamento dos arquivos FASTQ (gitpod)**

   1. Instalando o BWA no gitpod

   ```bash
   brew install bwa 
   ```

   2. Google Colab

   Abri um CODE

   ```bash
   !sudo apt-get install bwa
   ```

4. **BWA index do arquivo chr9.fa.gz**

   ```bash
   # descompacta o arquivo gz
   gunzip chr9.fa.gz
   
   # bwa index para indexar o arquivo .fa (~5min)
   bwa index chr9.fa
   ```

5. **Samtools faidx**

   1. Install Gitpod

   ```bash
   brew install samtools 
   ```

   2. Install Google Colab

   ```bash
   !sudo apt-get install samtools
   ```

   3. Samtools faidx chr9.fa

   ```bash
   samtools faidx chr9.fa
   ```

   

6. **BWA-mem** para fazer o alinhamento (FASTQ -> BAM)

```bash
NOME=WP312; Biblioteca=Nextera; Plataforma=illumina;

bwa mem -t 10 -M -R "@RG\tID:$NOME\tSM:$NOME\tLB:$Biblioteca\tPL:$Plataforma" \
chr9.fa \
SRR8856724_1.fastq.gz \
SRR8856724_2.fastq.gz > WP312.sam
```

**samtools: fixmate, sort e index (~min)**

```bash
# -@ numero de cores utilizados
time samtools fixmate -@10 WP312.sam WP312.bam
```

```bash
# ordenando o arquivo fixmate
time samtools sort -O bam -@6 -m2G -o WP312_sorted.bam WP312.bam
```

```bash
# indexando o arquivo BAM ordenado (sort)
time samtools index WP312_sorted.bam
```

```bash
# abordagem de target sequencing utilizamos o rmdup para remover duplicata de PCR
time samtools rmdup WP312_sorted.bam WP312_sorted_rmdup.bam
```

```bash
# indexando o arquivo BAM rmdup
time samtools index WP312_sorted_rmdup.bam 
```



**Alternativa: combinar com pipes: bwa + samtools view e sort**

```bash
bwa mem -t 10 -M -R "@RG\tID:$NOME\tSM:$NOME\tLB:$Biblioteca\tPL:$Plataforma" chr9.fa SRR8856724_1.fastq.gz SRR8856724_2.fastq.gz | samtools view -F4 -Sbu -@2 - | samtools sort -m4G -@2 -o WP312_sorted.bam
```

**NOTA: se utilizar a opção alternativa, não esquecer de rodar o samtools para as etapas: rmdup e index (do rmdup).**



6. **Cobertura - make BED files**



**Instalação do bedtools**

Gitpod

```bash
brew install bedtools
```

Google Colab

```bash
!sudo apt-get install bedtools
```



**Gerando BED do arquivo BAM**

```bash
bedtools bamtobed -i WP312_sorted_rmdup.bam > WP312_sorted_rmdup.bed
```

```bash
bedtools merge -i WP312_sorted_rmdup.bed > WP312_sorted_rmdup_merged.bed
```

```bash
bedtools sort -i WP312_sorted_rmdup_merged.bed > WP312_sorted_rmdup_merged_sorted.bed
```



**Cobertura Média**

```bash
bedtools coverage -a WP312_sorted_rmdup_merged_sorted.bed \
-b WP312_sorted_rmdup.bam -mean \
> WP312_coverageBed.bed
```



**Filtro por total de reads >=20**

```bash
cat WP312_coverageBed.bed | \
awk -F "\t" '{if($4>=20){print}}' \
> WP312_coverageBed20x.bed
```



7. **GATK4 instalação** (MuTect2 com PoN)

   

**Download**

```
wget -c https://github.com/broadinstitute/gatk/releases/download/4.2.2.0/gatk-4.2.2.0.zip
```

**Descompactar**

```bash
unzip gatk-4.2.2.0.zip 
```

**Gerar arquivo .dict**

```bash
./gatk-4.2.2.0/gatk CreateSequenceDictionary -R chr9.fa -O chr9.dict
```

**Gerar interval_list do chr9**

```bash
./gatk-4.2.2.0/gatk ScatterIntervalsByNs -R chr9.fa -O chr9.interval_list -OT ACGT
```

**Converter Bed para Interval_list**

```bash
./gatk-4.2.2.0/gatk BedToIntervalList -I WP312_coverageBed20x.bed \
-O WP312_coverageBed20x.interval_list -SD chr9.dict
```



**GATK4 - CalculateContamination**

```bash
./gatk-4.2.2.0/gatk GetPileupSummaries \
	-I WP312_sorted_rmdup.bam  \
	-V af-only-gnomad.hg38.vcf.gz \
	-L WP312_coverageBed20x.interval_list \
	-O WP312.table
```

```bash
./gatk-4.2.2.0/gatk CalculateContamination \
-I WP312.table \
-O WP312.contamination.table
```



**GATK4 - MuTect2** Call

```bash
./gatk-4.2.2.0/gatk Mutect2 \
  -R chr9.fa \
  -I WP312_sorted_rmdup.bam \
  --germline-resource af-only-gnomad.hg38.vcf.gz  \
  --panel-of-normals 1000g_pon.hg38.vcf.gz \
  -L WP312_coverageBed20x.interval_list \
  -O WP312.somatic.pon.vcf.gz
```



**GATK4 - MuTect2** FilterMutectCalls

```bash
./gatk-4.2.2.0/gatk FilterMutectCalls \
	-R chr9.fa \
	-V WP312.somatic.pon.vcf.gz \
	--contamination-table WP312.contamination.table \
	-O WP312.filtered.pon.vcf.gz
```


# somaticoEP1 - LiftOverVCF


Download dos arquivos VCFs da versão hg19 da análise antiga do Projeto LMA Brasil:

>  https://drive.google.com/drive/folders/1m2qmd0ca2Nwb7qcK58ER0zC8-1_9uAiE?usp=sharing

```bash
WP312.filtered.vcf.gz
WP312.filtered.vcf.gz.tbi
```



## Download liftOver 

* MacOS: https://hgdownload.cse.ucsc.edu/admin/exe/macOSX.x86_64/liftOver

```bash
wget -c https://hgdownload.cse.ucsc.edu/admin/exe/macOSX.x86_64/liftOver
```

* Linux x86_64: https://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64/liftOver

```bash
wget -c https://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64/liftOver
```



Alterar a permissão de execução do arquivo `liftOver`

```bash
chmod +x liftOver
```

Para testar execute: 

```bash
./liftOver
```

```bash
liftOver - Move annotations from one assembly to another
usage:
   liftOver oldFile map.chain newFile unMapped
oldFile and newFile are in bed format by default, but can be in GFF and
maybe eventually others with the appropriate flags below.
The map.chain file has the old genome as the target and the new genome
as the query.

***********************************************************************
WARNING: liftOver was only designed to work between different
         assemblies of the same organism. It may not do what you want
         if you are lifting between different organisms. If there has
         been a rearrangement in one of the species, the size of the
         region being mapped may change dramatically after mapping.
***********************************************************************

options:
   -minMatch=0.N Minimum ratio of bases that must remap. Default 0.95
   -gff  File is in gff/gtf format.  Note that the gff lines are converted
         separately.  It would be good to have a separate check after this
         that the lines that make up a gene model still make a plausible gene
         after liftOver
   -genePred - File is in genePred format
   -sample - File is in sample format
   -bedPlus=N - File is bed N+ format (i.e. first N fields conform to bed format)
   -positions - File is in browser "position" format
   -hasBin - File has bin value (used only with -bedPlus)
   -tab - Separate by tabs rather than space (used only with -bedPlus)
   -pslT - File is in psl format, map target side only
   -ends=N - Lift the first and last N bases of each record and combine the
             result. This is useful for lifting large regions like BAC end pairs.
   -minBlocks=0.N Minimum ratio of alignment blocks or exons that must map
                  (default 1.00)
   -fudgeThick    (bed 12 or 12+ only) If thickStart/thickEnd is not mapped,
                  use the closest mapped base.  Recommended if using 
                  -minBlocks.
   -multiple               Allow multiple output regions
   -noSerial               In -multiple mode, do not put a serial number in the 5th BED column
   -minChainT, -minChainQ  Minimum chain size in target/query, when mapping
                           to multiple output regions (default 0, 0)
   -minSizeT               deprecated synonym for -minChainT (ENCODE compat.)
   -minSizeQ               Min matching region size in query with -multiple.
   -chainTable             Used with -multiple, format is db.tablename,
                               to extend chains from net (preserves dups)
   -errorHelp              Explain error messages
```



## Downlaod chain files

Converter as posição do hg19 para hg38 `hg19ToHg38.over.chain.gz`

```bash
wget -c https://hgdownload.soe.ucsc.edu/goldenPath/hg19/liftOver/hg19ToHg38.over.chain.gz
```

```bash
gunzip hg19ToHg38.over.chain.gz 
```



---

**NOTA**: Nos arquivos VCFs antigos do projeto LMA Brasil, a descrição do nome da referência não tem `chr` apenas o número ou letra do cromossomo humano, isso pode causar conflito na hora do GATK verificar se a sua referência é igual a referência do arquivo VCF.

1. Vamos adicionar o caracter `chr` no arquivo VCF antigo e salvar um novo.

```bash
# pegando apenas o cabeçalho
zgrep "\#" WP312.filtered.vcf.gz > header.txt
```

```bash
zgrep -v "\#" WP312.filtered.vcf.gz | awk '{print("chr"$0)}' > variants.txt
```

```bash
cat header.txt variants.txt > WP312.filtered.chr.vcf
```

2. Fazer download do arquivo completo do genoma hg38.fa

```bash
# Arquivos com todos os cromossomos
# https://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/
wget -c https://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/hg38.fa.gz
```

gunzip
```bash
gunzip hg38.fa.gz
```

3. Gear o .dict para o hg38.fa.

```bash
./gatk-4.2.2.0/gatk CreateSequenceDictionary -R hg38.fa -O hg38.dict
```

4. Rodar o LiftOverVCF do GATK.

```bash
# lembre que o VCF tem que ser o com chr
./gatk-4.2.2.0/gatk LiftoverVcf \
-I WP312.filtered.chr.vcf \
-O liftOver_WP312_hg19Tohg38.vcf.gz \
--CHAIN hg19ToHg38.over.chain \
--REJECT liftOver_Reject_WP312_hg19Tohg38.vcf \
-R hg38.fa
```

---



## vcftools (vcf-compare)

Vamos pegar os dois VCFs que estão na mesma versão do hg38 e comparar o número de variantes e a % de match entre os arquivos.

> Nota: a comparação vai ser apenas com base nas Referências que derem match (tem que estar no dois arquivos vcf).



**Gitpod install**

```bash
brew install vcftools
```

**Colab install**

```bash
!sudo apt-get install vctfools
```



---

**Nota:** Para utilizadr o `vcf-compare`precisamos que os arquivos VCFs estejam `bgzip` e com o index do`tabix`

---



Fiz o download do arquivo `WP312.filtered.pon.vcf.gz` que está o compartilhamento do Google Drive e coloquei no Gtipod dentro de um diretório chamado` hg38-vcf-EP1`

```bash
mkdir hg38-vcf-EP1
mv WP312.filtered.pon.vcf.gz WP312.filtered.pon.vcf.gz.tbi hg38-vcf-EP1/
```



**Rodar o vcf-compare**


- vcf-compare file1.vcf file2.vcf ... fileN.vcf
- liftOver_WP312_hg19Tohg38.vcf.gz: arquivo que convertemos do hg19 para hg38
- hg38-vcf-EP1/WP312.filtered.pon.vcf.gz: Arquivo da aula EP01 (primeira parte)


```bash
vcf-compare liftOver_WP312_hg19Tohg38.vcf.gz hg38-vcf-EP1/WP312.filtered.pon.vcf.gz
```



**Resultado vcf-compare**

```bash
#VN 'Venn-Diagram Numbers'. Use `grep ^VN | cut -f 2-` to extract this part.
#VN The columns are: 
#VN        1  .. number of sites unique to this particular combination of files
#VN        2- .. combination of files and space-separated number, a fraction of sites in the file
VN      166     hg38-vcf-EP1/WP312.filtered.pon.vcf.gz (0.2%)   liftOver_WP312_hg19Tohg38.vcf.gz (1.0%)
VN      16971   liftOver_WP312_hg19Tohg38.vcf.gz (99.0%)
VN      78215   hg38-vcf-EP1/WP312.filtered.pon.vcf.gz (99.8%)

#SN Summary Numbers. Use `grep ^SN | cut -f 2-` to extract this part.
SN      Number of REF matches:  165
SN      Number of ALT matches:  163
SN      Number of REF mismatches:       1
SN      Number of ALT mismatches:       2
SN      Number of samples in GT comparison:     0

# Number of sites lost due to grouping (e.g. duplicate sites): lost, %lost, read, reported, file
SN      Number of lost sites:   2       0.0%    17139   17137   liftOver_WP312_hg19Tohg38.vcf.gz
```



## Referências

- Documentação SRA-ToolKit: https://github.com/ncbi/sra-tools/wiki/01.-Downloading-SRA-Toolkit
- fast-dump: https://trace.ncbi.nlm.nih.gov/Traces/sra/sra.cgi?view=toolkit_doc&f=fastq-dump
- fastq-dump parallel: https://github.com/rvalieris/parallel-fastq-dump
- LMA Brasil - VCFs hg19 - https://drive.google.com/drive/folders/1m2qmd0ca2Nwb7qcK58ER0zC8-1_9uAiE?usp=sharing
- UCSC liftOver -  https://hgdownload.cse.ucsc.edu/admin/exe/
- liftOver Doc - https://genome.ucsc.edu/goldenPath/help/hgTracksHelp.html#Liftover
- hg38ToHg19 (hg38ToHg19.over.chain.gz) - http://hgdownload.soe.ucsc.edu/goldenPath/hg38/liftOver/
- hg19ToHg38 (hg19ToHg38.over.chain.gz) - https://hgdownload.soe.ucsc.edu/goldenPath/hg19/liftOver
- Vcftools - https://vcftools.github.io/index.html
