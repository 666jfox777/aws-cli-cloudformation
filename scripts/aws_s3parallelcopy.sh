#!/bin/bash
################################################################################
#
#  Usage:  ./aws_s3parallelcopy.sh -s s3://bucket/path/ -d /output/ -t 30 -p env
#
################################################################################

# Help Menu
usage ()
{
  cat <<EOM
--------------------------------------------------------------------------------
Usage: $0 -h
    -s      Source location. E.g.: s3://bucket/path/
    -d      Output location. E.g.: /tmp/s3job/
    -t      Number of threads. E.g.: 8
    -p      AWS profile to use. Optional.
--------------------------------------------------------------------------------
EOM
}

# Process all the arguments
while getopts ":h?s:d:t:p:" opt; do
    case $opt in
        s)
          source=$OPTARG
          echo "Source location has been set to: $OPTARG" >&2
          ;;
        d)
          destination=$OPTARG
          echo "Destination location has been set to: $OPTARG" >&2
          ;;
        t)
          threads=$OPTARG
          echo "Number of threads has been set to: $OPTARG" >&2
          ;;
        p)
          profile=$OPTARG
          echo "Profile has been set to: $OPTARG" >&2
          ;;
        h|\?)
          usage
          exit 0
          ;;
        :)
          echo "Option -$OPTARG requires an argument." >&2
          usage
          exit 1
          ;;
    esac
done

# Validate required parameters
if [[ -z "$source" || -z "$destination" ]]; then
    usage
    exit 1
fi

# Depending on whether we are using a profile or not.
if [[ -z "$profile" ]]; then
    profile=""
else
    profile="--profile $profile"
fi

# Set a default number of threads.
threads=${threads:-$(bc -l <<< "`grep -c ^processor /proc/cpuinfo`-1")}


list=`aws s3 ls "$source" $profile | awk '{ print $4 }'`


for file in $list
do
  if (( `jobs -p | wc -l` > $threads )); then
    wait $(jobs -p)
  fi
  aws s3 cp "${source}${file}" $destination --quiet $profile &
done


wait $(jobs -p)


echo "Downloads complete!"

