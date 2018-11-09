#!/bin/bash

exe=$1
conf=$2

while(true)
do
    c=`ps -x | grep $conf | grep -v grep | wc -l`
    if [ $c -lt 1 ]; then
        nohup $exe $conf &
    fi

    sleep 10
done
