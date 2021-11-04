#!/bin/bash

print_help () {
  printf "Usage ./split [options]\nOptions include:\n"
  printf -- "\t-b, --build_path \t Build path (required) \n"
  printf -- "\t-o, --out \t Output for project level folders (required) \n"
  printf -- "\t-v, --verbose \t\t Verbose flag, print additional output \n"
  printf -- "\t-h, --help \t\t Print this help text\n"
}

#optional
if test $# -lt 1; then
  print_help
  exit 1
fi

while test $# -gt 0; do
  case "$1" in
    -h|--help)
      print_help
      exit 0
      ;;
    -b| --build_path)
      shift
      BUILD_PATH=$1
      ;;
    -p| --pert)
      shift
      PERT=$1
      ;;
    -pr| --project)
      shift
      PROJECT=$1
      ;;
    -pp| --pert_plate)
      shift
      PERT_PLATE=$1
      ;;
    -o|--out)
      shift
      BUILD_DIR=$1
      ;;
    -v| --verbose)
      shift
      VERBOSE=true
      ;;
    *)
      printf "Unknown parameter: %s \n" "$1"
      shift
      ;;
  esac
  shift
done

if [ ! -d $BUILD_DIR ]
then
  mkdir -p $BUILD_DIR/$PROJECT/$PERT_PLATE/$PERT
fi

# ##Run Collate
# if [[ -z $BUILD_PATHS || -z $BUILD_DIR ]]
# then
#   printf "Required arguments missing\n"
#   exit -1
# fi

args=(
  -b "$BUILD_PATH"
  -o "$BUILD_DIR"
)

if [[ ! -z $VERBOSE ]]
then
  args+=(-v)
fi

if [[ ! -z $PROJECT || ! -z $PERT_PLATE || ! -z $PERT ]]
then
  args+=(
    -p "$PERT"
    -pr "$PROJECT"
    -pp "$PERT_PLATE"
  )
fi

#setup environment
source activate merino

cd /cmap/merino/
python setup.py develop

#return to /
cd /

python /clue/bin/split.py "${args[@]}"

exit_code=$?
conda deactivate
exit $exit_code
