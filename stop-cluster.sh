#!/bin/bash

echo "stop-cluster is deprecated. Please use 'cluster.sh' instead"

source install/common.sh
check_usage $# 1 "Usage: $0 <VERSION>"

./cluster.sh stop -v $1
