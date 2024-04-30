#!/bin/bash

help()
{
    echo "------------------------------------------------------------------------------------------"
    echo "| Helper script to compile P4 programs assuming SDE and SDE_INSTALL env variables are set |"
    echo "|   @author: Alessandro Cornacchia                                                        |"
    echo "------------------------------------------------------------------------------------------"
    echo "Usage: p4-build [ OPTIONS | -h ] <prog.p4>"              
    echo ""
    echo "Available OPTIONS are:"
    echo ""
    echo "-o,  --build-directory    Path to the directory used to create CMake build artifacts"
    echo "                          Default: current directory"
    echo "-p,  --p4-name            Install program's name (does not have to be the same as the name of the user's P4 program)."
    echo "                          Default: P4 program name without .p4 extension"
    echo ""
    exit 2
}

# if no arguments provided show help
if [ "$#" -eq 0 ]; then
  help
fi

SHORT=o:,p:,h 
LONG=p4-path:,p4-name:,help
OPTS=$(getopt -a -n p4-build --options $SHORT --longoptions $LONG -- "$@")

# if getopt failed we assume wrong input
if [ "$?" != 0 ] ; then
  help
fi

eval set -- "$OPTS"

while :
do
  case "$1" in
    -o | --build-directory )
      DIR="$2"
      shift 2
      ;;
    -p | --p4-name )
      BUILD_OPTS="${BUILD_OPTS}-DP4_NAME=${2} "
      shift 2
      ;;
    -h | --help)
      help
      ;;
    --)
      shift;
      break
      ;;
    *)
      echo "Unexpected option: $1"
      help
      ;;
  esac
done

# at this ponint we process <prog.p4> string, error if not found
if [ "$#" == 0 ] ; then
  echo -e "Error: <prog.p4> not specified"
  echo ""
  help
fi

# get absolute path of prog.p4
P4_PATH=`realpath ${1}`

if [[ $? -ne 0 ]]; then
  echo -e "Error: ${1} not found"
  echo ""
  help
fi

BUILD_OPTS="${BUILD_OPTS}-DP4_PATH=${P4_PATH} "

# go into build directory
if [ -z $DIR ]
then
  DIR=./build
fi
mkdir -p $DIR
cd $DIR

# run cmake command
# neat: derive P4_NAME from its output while mantaining stderr/stdout
P4_NAME=$(cmake $SDE/p4studio ${BUILD_OPTS} |& tee /dev/tty |& grep P4_NAME)
P4_NAME=$(echo $P4_NAME | cut -d ' ' -f 2)

# make it
make $P4_NAME && make install