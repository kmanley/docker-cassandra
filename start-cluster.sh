#!/bin/bash

source install/common.sh

check_usage $# 2 "Usage: $0 <VERSION> <NUMBER OF NODES>"
echo "start-cluster is deprecated. Please use 'cluster.sh' instead"

./cluster.sh start -v $1 -n $2
