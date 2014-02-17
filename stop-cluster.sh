#!/bin/bash

source install/common.sh

check_usage $# 1 "Usage: $0 <VERSION>"
echo "stop-cluster is deprecated. Please use 'cluster.sh' instead"

./cluster.sh stop -v $1
