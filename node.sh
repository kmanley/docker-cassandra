#!/bin/bash

BRIDGE=br1

usage() {
    echo "Usage: $0 -i <ID> -v <VERSION> [-s <SEED> -b <BRIDGE> -d <DC> -p <PORTMAPPING>]" 1>&2; exit 1;
}

ports=""
while getopts "i:s:v:d:p:" o; do
    case "${o}" in
        i)
            id=${OPTARG}
            ;;
        s)
            seeds="-s ${OPTARG}"
            ;;
        v)
            version=${OPTARG}
            ;;
        d)
            topology="-d ${OPTARG}"
            ;;
        p)
            ports+="-p ${OPTARG} "
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${id}" ] || [ -z "${version}" ]; then
    usage
fi

hostname="cass$id"
ip=192.168.100.$id

if [ -z "${seeds}" ]; then
    seeds="-s $ip"
fi

# start
cid=$(sudo docker run -d -dns 127.0.0.1 -h $hostname $ports -t cassandra:$version /usr/bin/start-cassandra -n $ip $topology $seeds)

# Add network interface
sleep 1
sudo pipework $BRIDGE $cid $ip/24
