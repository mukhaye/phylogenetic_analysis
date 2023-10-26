#!/usr/bin/env nextflow

// Define workflow inputs
params.NCBIdb = file('path_to_your_Full-Refs-NCBI.fasta') //these are the sequences Retrieved from Batch Entrez tool at: https://www.ncbi.nlm.nih.gov/sites/batchentrez 
params.queryFasta = file('path_to_your_queryseq.fasta') // this is your sequence of interest from NGS
params.reference = file('path_to_your_reference.fasta') //this is the reference genome sequence of your microbe
params.genemap = file('path_to_your_genemap.gff') //this contains the coding region location information and its also downloaded from the NCBI
params.aligned = file('path_to_your_aligned_sequence.fasta')

//defining process for creating a proper database
process createdatabase {
    input:
    path NCBIdb
    output:
    path 'DENV-Whole'
    
    script:
    """
   //creating a local database from the downloaded sequences
   makeblastdb -in ${params.NCBIdb} -title "DENV-Whole" -dbtype nucl -parse_seqids > DENV-Whole 
    """
}

 // defining process to run the BLAST using blastn
process nblast {
    input:
    path NCBIdb
    path queryFasta
    output:
    path 'global_DENV2.txt'
    
    script:
    """ 
    //running the BLAST command against the new database
    blastn -db ${params.NCBIdb} -query ${queryFasta} -num_alignments 1 -out global_DENV2.txt

    // providing BLAST with sequence IDs by creating a list of just IDs 
    blastn -db ${params.NCBIdb} -query ${queryFasta}  -num_descriptions 1 -outfmt '6 sseqid' -out global_DENV2_IDs.txt
 
    //Removing duplicates
    sort -u global_DENV2_IDs.txt > New.txt 
 
    //cross-referencing the database using the list of IDs and retrieve a FASTA (“%f”) file with the target sequences
    blastdbcmd -db ${params.NCBIdb} -entry_batch New.txt -outfmt %f -out global-DENV2.fasta 
    """
}

//defining the process for sequence alignment using nextalign software
process nextAlignment {
    input:
    path blastResult
    
    output:
    path 'output'
    
    script:
    """
    nextalign run \
    --input-ref=${params.reference} \
    --genemap=${params.genemap} \
    --output-all=output/ \
    ${params.aligned}
    """
}

// defining the likelihood mapping of sequence data using IQ-TREE

process phylosignal {
    input:
    path aligned
    
    script:
    """
    //IQ-TREE will determine the best evolutionary model
    //IQ-TREE will write a plot of the data to an .eps (and .svg) file in the original folder

    iqtree -nt AUTO -s ${params.aligned} -lmap 100 -n 0

    //Maximum Likelihood tree reconstruction in IQ-TREE using both the SH-aLRT and the Bootstrap (bb) branch support
    iqtree -nt AUTO -s ${params.aligned} -alrt 1000 -bb 1000
    """
}

// Define workflow outputs
workflow {
    database = createdatabase (params.NCBIdb)
    blastOutput = nblast (database,params.queryFasta)
    alignedSeqFile = nextAlignment(blastOutput)
    signalmap = phylosignal (alignedSeqFile )
    phylogeneticTree = phylosignal(alignedSeqFile)
}