#!/usr/bin/env cwl-runner
class: CommandLineTool
cwlVersion: v1.0
id: OncotateSegments

requirements:
- class: ShellCommandRequirement
- class: InlineJavascriptRequirement
- class: DockerRequirement
  dockerPull: us.gcr.io/broad-gatk/gatk:4.1.6.0

inputs:
- id: called_file
  type: File
- id: additional_args
  type: string?
  default: ""
- id: oncotator_docker
  type: string?
- id: mem_gb
  type: int?
  default: 3
- id: disk_space_gb
  type: int?
- id: boot_disk_space_gb
  type: int?
- id: use_ssd
  type: boolean
  default: false
- id: cpu
  type: int?
- id: preemptible_attempts
  type: int?

outputs:
- id: oncotated_called_file
  label: oncotated_called_file
  type: File
  outputBinding:
    glob: $(inputs.called_file.nameroot).per_segment.oncotated.txt
    loadContents: false
- id: oncotated_called_gene_list_file
  label: oncotated_called_gene_list_file
  type: File
  outputBinding:
    glob: $(inputs.called_file.nameroot).gene_list.txt
    loadContents: false


baseCommand: []
arguments:
- position: 0
  shellQuote: false
  valueFrom: |-
    set -e

    # Get rid of the sequence dictionary at the top of the file
    egrep -v "^\@" $(inputs.called_file) > $(inputs.called_file.nameroot).seq_dict_removed.seg

    echo "Starting the simple_tsv..."

    /root/oncotator_venv/bin/oncotator --db-dir /root/onco_dbdir/ -c /root/tx_exact_uniprot_matches.AKT1_CRLF2_FGFR1.txt \
      -u file:///root/onco_cache/ -r -v $(inputs.called_file.nameroot).seq_dict_removed.seg $(inputs.called_file.nameroot).per_segment.oncotated.txt hg19 \
      -i SEG_FILE -o SIMPLE_TSV $(inputs.additional_args)

    echo "Starting the gene list..."

    /root/oncotator_venv/bin/oncotator --db-dir /root/onco_dbdir/ -c /root/tx_exact_uniprot_matches.AKT1_CRLF2_FGFR1.txt \
      -u file:///root/onco_cache/ -r -v $(inputs.called_file.nameroot).seq_dict_removed.seg $(inputs.called_file.nameroot).gene_list.txt hg19 \
      -i SEG_FILE -o GENE_LIST $(inputs.additional_args)
