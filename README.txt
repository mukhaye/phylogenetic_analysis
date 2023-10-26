# NGS Data Analysis Pipeline

This Nextflow pipeline performs a series of analyses on NGS data, including downloading sequences from NCBI and creating local database, performing BLAST, sequence alignment, determining phylogenetic signal and phylogenetic noise and generating a phylogenetic tree.

## Usage
1. Install the necessary software (BLAST, Nextalign, IQ-TREE).
2. Clone the repository.
3. Edit the `params` section in the Nextflow script to specify your input files and parameters.
4. Run the pipeline with `nextflow run ngs_pipeline.nf`.

## Dependencies
- BLAST
- Nextalign
- IQ-TREE
