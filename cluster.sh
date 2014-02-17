#!/bin/bash

source install/common.sh
BRIDGE=br1

usage() {
    echo "Usage: $0 [start|status|stop] -v <VERSION> [OPTIONS]" 1>&2
    echo "OPTIONS:" 1>&2
    echo -e "\t -n <NUM_NODES> [-t us-east:3 -t us-west:3]" 1>&2;
    exit 1;
}

cluster_start() {
    topology=()
    while getopts ":n:v:t:" o; do
        case "${o}" in
            n)
                nodes=${OPTARG} ;;
            v)
                version=${OPTARG} ;;
            t)
                topology+=(${OPTARG}) ;;
            *)
                usage ;;
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
}

cluster_status() {
    while getopts "v:" o; do
        case "${o}" in
            v)
                version=${OPTARG} ;;
            *)
                usage ;;
        esac
    done
    shift $((OPTIND-1))
    
    if [ -z "${version}" ]; then
        usage
    fi

    ./client.sh $version nodetool -h cass1 status
}

cluster_stop() {
    while getopts "v:" o; do
        case "${o}" in
            v)
                version=${OPTARG} ;;
            *)
                usage ;;
        esac
    done
    shift $((OPTIND-1))
    
    if [ -z "${version}" ]; then
        usage
    fi
    image=cassandra:$version
    test_image $version

    if sudo docker ps | grep $image >/dev/null; then
        cids=$(sudo docker ps | grep $image | awk '{ print $1 }')
        echo $cids | xargs echo "Killing and removing containers"
        sudo docker kill $cids > /dev/null
        sudo docker rm $cids   > /dev/null
    fi
}

action=$1
shift
case "$action" in 
    start)
        cluster_start $@ ;;
    status)
        cluster_status $@ ;;
    stop)
        cluster_stop $@ ;;
    *)
        usage ;;
esac

