#!/bin/bash
echo "script start: download and initial sequencing read quality control"
date
######commands start##########
cd /shared/home/yongtracer/medbioinfo_folder/tracer/MedBioinfo/analyses/
# extract accession number by left join sample_annot with sample2bioinformatician for myself
sqlite3 -noheader -csv /shared/home/yongtracer/medbioinfo_folder/pascal/central_database/sample_collab.db "SELECT run_accession FROM sample_annot LEFT JOIN sample2bioinformatician ON sample_annot.patient_code = sample2bioinformatician.patient_code WHERE username = 'yongtracer'; " > /shared/home/yongtracer/medbioinfo_folder/tracer/MedBioinfo/analyses/yongtracer_run_accessions.txt
mkdir ../data/sra_fastq
module load sra-tools

# Download FASTQ data according to extracted accession number
cat yongtracer_run_accessions.txt | srun --cpus-per-task=1 --time=00:3000 xargs fastq-dump --split-e --gzip --readids --outdir ../data/sra_fastq/ --disable-multithreading

# Quality contral with fastQC
mkdir /shared/home/yongtracer/medbioinfo_folder/tracer/MedBioinfo/analyses/fastqc
module load fastqc
srun --cpus-per-task=2 --time=00:10:00 xargs -I{} -a yongtracer_run_accessions.txt fastqc --outdir ./fastqc/ --threads 2 --noextract ../data/sra_fastq/{}_1.fastq.gz ../data/sra_fastq/{}_2.fastq.gz

# Moving files from remote server to local disk
scp yongtracer@core.cluster.france-bioinformatique.fr:/shared/projects/2314_medbioinfo/tracer/MedBioinfo/analyses/fastqc/*.html ~/Downloads

# Merging paired end reads
module load flash2
mkdir /shared/projects/2314_medbioinfo/tracer/MedBioinfo/data/merged_pairs
srun --cpus-per-task=2 xargs I{} -a yongtracer_run_accessions.txt flash2 --threads=2 -z --output-directory=../data/merged_pairs/ --output-prefix={}.flash /shared/projects/2314_medbioinfo/tracer/MedBioinfo/data/sra_fastq/{}_1.fastq.gz /shared/projects/2314_medbioinfo/tracer/MedBioinfo/data/sra_fastq/{}_2.fastq.gz 2>&1 | tee -a yongtracer_flash2.log

# Check PhiX contamination
mkdir /shared/projects/2314_medbioinfo/tracer/MedBioinfo/data/reference_seqs
## install ncbi edirect tool kit
sh -c "$(wget -q ftp://ftp.ncbi.nlm.nih.gov/entrez/entrezdirect/install-edirect.sh -O -)"
efetch -db nuccore -id NC_001422 -format fasta > ../data/reference_seqs/PhiX_NC_001422.fna                                                   
module load bowtie2
## first make  a bowtie2 indexed database from the reference sequences
mkdir ../data/bowtie2_DBs
module load bowtie2
srun bowtie2-build -f ../data/reference_seqs/PhiX_NC_001422.fna ../data/bowtie2_DBs/PhiX_bowtie2_DB
mkdir bowtie
srun --cpus-per-task=8 bowtie2 -x ../data/bowtie2_DBs/PhiX_bowtie2_DB -U ../data/merged_pairs/ERR*.extendedFrags.fastq.gz \
 -S bowtie/yongtracer_merged2PhiX.sam --threads 8 --no-unal 2>&1 | tee bowtie/yongtracer_bowtie_merged2PhiX.log 

## Now try the same thing for SARS-COVID2
efetch -db nuccore -id NC_045512 -format fasta > ../data/reference_seqs/PhiX_NC_045512.fna
srun bowtie2-build -f ../data/reference_seqs/PhiX_NC_045512.fna ../data/bowtie2_DBs/SC2_bowtie2_DB
srun --cpus-per-task=8 bowtie2 -x ../data/bowtie2_DBs/SC2_bowtie2_DB -U ../data/merged_pairs/ERR*.extendedFrags.fastq.gz \
 -S bowtie/yongtracer_merged2SC2.sam --threads 8 --no-unal 2>&1 | tee bowtie/yongtracer_bowtie_merged2SC2.log

# Combine quality control results
module load multiqc
srun multiqc --force --title "yongtracer sample sub-set" ../data/merged_pairs/ ./fastqc/ ./yongtracer_flash2.log ./bowtie/



#####commands end###########
date
echo "script end."

