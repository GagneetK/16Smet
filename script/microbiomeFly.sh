#####-------------------------- Obtain the data------------------------####

###Install qiime2 and activate the conda environment
conda activate qiime2

###Create a directory to work in and 
mkdir microbiomeFly
cd microbiomeFly

###Download the sequence data that will be used in this analysis



tar -xvzf data_Run1_raw.tar.gz

#####----------------------------------------------------------#####
#####----------------------------------------------------------#####

### Calcute read length and count
for file in data_Run1_raw/*; do zcat $file | awk '{if(NR%4==2) print length($1)}' | sort -n | uniq -c > $file.read_length.txt; done

mkdir initialreadlenght
mv data_Run1_raw/*.txt initialreadlenght/

conda activate qiime2
cd data_Run1_raw

#####----------------------------------------------------------#####
#####----------------------------------------------------------#####

###Generating manifest file
echo -e sample-id"\t"forward-absolute-filepath"\t"reverse-absolute-filepath >manifest.csv

for file in *R1*; do R2="${file/_R1/_R2}"; echo -e $file"\t"$PWD/$file"\t"$PWD/$R2 >>manifest.csv ; done

 mv manifest.csv ../
 cd ../

#####----------------------------------------------------------#####
#####----------------------------------------------------------#####


### Import the download sequences into SampleData[PairedEndSequencesWithQuality

qiime tools import --type 'SampleData[PairedEndSequencesWithQuality]' --input-path manifest.csv --output-path paired-end-demux.qza --input-format PairedEndFastqManifestPhred33V2

qiime demux summarize --i-data paired-end-demux.qza --o-visualization paired-end-demux.qzv

qiime tools view paired-end-demux.qzv (Move this file to your computer to visualize the results)

Look at the sequence quality and filter the samples out of the data-having less than 150 reads (if needed).
#####----------------------------------------------------------#####
#####----------------------------------------------------------#####

### Data filtering and denoising


### Qiime2 provides several quality control methods - DADA2, DEBLUR and basic quality-score-based filtering. We are using DADA2 pipeline.
### This quality control process additionally filter out any phiX reads (commonly present in marker gene Illumina sequence data) that are identified in the sequencing data, and will filter chimeric sequences.
### The dada2 denoise-paired method allows the user to remove low quality regions of the sequences using two parameters: --p-trim  and --p-trunc-len.

### Next, Look for the best match possible for merging the reads. 

qiime dada2 denoise-paired --i-demultiplexed-seqs paired-end-demux.qza --p-trunc-len-f 280 --p-trunc-len-r 270 --output-dir DADA2_denoising_output --p-n-threads 10 --verbose &>logdada2

qiime dada2 denoise-paired --i-demultiplexed-seqs paired-end-demux.qza --p-trunc-len-f 280 --p-trunc-len-r 260 --output-dir DADA2_denoising_output_280_260 --p-n-threads 10 --verbose &>logdada2_280_260

qiime tools inspect-metadata metadata.txt


### Generate summaries of feature table and denoising_stats

qiime feature-table summarize --i-table DADA2_denoising_output/table.qza --o-visualization DADA2_denoising_output/table.qzv --m-sample-metadata-file metadata.txt

qiime metadata tabulate --m-input-file   DADA2_denoising_output/denoising_stats.qza  --o-visualization DADA2_denoising_output/denoising_stats.qzv

###Other option: Deblur

#####------------------------------------------------------QUALITY STEP COMPLETE--------------------------------------------------------#####



####--------------------Feature Table and Feature Data summaries--------------------#####

## Lets, Start exploring the data.
### We used silva-138 classifier for this analysis:

qiime feature-classifier classify-sklearn --p-n-jobs 8 --i-classifier silva-138-ssu-nr99-341f-806r-classifier.qza  --i-reads DADA2_denoising_output/representative_sequences.qza --output-dir taxa

 
 ### Plot a barlot to visualize the data
 qiime taxa barplot --i-table DADA2_denoising_output/table.qza --i-taxonomy taxa/classification.qza --m-metadata-file metadata.txt --o-visualization taxa/taxa_barplot.qzv



















