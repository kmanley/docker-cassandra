#!/bin/bash

BRIDGE=br1

usage() {
    echo "Usage: $0 -n <NUM_NODES> -v <VERSION>" 1>&2; exit 1;
}

topology=()
while getopts ":n:v:t:" o; do
    case "${o}" in
        n)
            nodes=${OPTARG}
            ;;
        v)
            version=${OPTARG}
            ;;
        t)
            topology+=(${OPTARG})
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${nodes}" ] || [ -z "${version}" ]; then
    usage
fi

# check topology
topologyParameters=()
numDCs=${#topology[@]}
if [ $numDCs != 0 ]; then
    # topology passed in
    totalCount=0
    for (( i=0; i<${numDCs}; i++ ));
    do
        curDC=${topology[$i]}
        read dcName dcCount <<<$(IFS=":"; echo $curDC)
        totalCount=$((${totalCount}+${dcCount}))

        # keep topology parameter to pass as input to start-cassandra
        for (( j=0; j<${dcCount}; j++ )); do
            topologyParameters+=("-d ${dcName}")
        done
    done
    if [ $totalCount != $nodes ]; then
        echo "Total node count according to topology: $totalCount"
        echo "Total node count passed in parameter: $nodes"
        exit 1
    fi
fi

# Start nodes!
for id in $(seq 1 ${nodes}); do

    # echo "Starting node $id"

    # start container
    if [[ $id == 1 ]]; then
        ports="-p 9160:9160 -p 9042:9042"
        seed=""
    else
        ports=""
        seed="-s cass1"
    fi

    cmd="./start-node.sh -i $id -v $version $ports $seed ${topologyParameters[$(($id-1))]}"
    echo $cmd
    $cmd
done

