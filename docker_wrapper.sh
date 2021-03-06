#!/bin/bash

# read in flagged arguments
while getopts ":i:o:p:" arg; do
  case $arg in
    i) # specify input folder
      data_dir=${OPTARG}
      ;;
    o) # specifcy output folder
      output_dir=${OPTARG}
      ;;
    p) # specify project name
      project=${OPTARG}
      ;;
  esac
done

# run docker container with arguments
docker run -it \
  -v $data_dir:/data \
  -v $output_dir:/results \
  aboghoss/clue-mts "data" "results" "$project"
