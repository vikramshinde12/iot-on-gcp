#!/bin/bash

PROJECT=$1
REGION=$2
REGISTRY=$3
NUM_OF_DEVICES=$4

cd demo-device
counter=1
while [ $counter -le $NUM_OF_DEVICES ]; do
    docker run -d -e private_key_file=cred/rsa_private.pem -v $PWD:/cred \
    -e device_id=device$counter \
    -e registry_id=$REGISTRY \
    -e cloud_region=$REGION \
    -e project_id=$PROJECT \
    vikramshinde/python-iot-sensor

     counter=$(( counter+1 ))
done