#!/bin/bash

PROJECT=$1
REGION=$2
REGISTRY=$3
NUM_OF_DEVICES=$4

cd demo-device
counter=1
while [ $counter -le $NUM_OF_DEVICES ]; do
    sudo gcloud iot devices create device$counter --project=$PROJECT --region=$REGION --registry=$REGISTRY --public-key path=rsa_cert.pem,type=rs256
    counter=$(( counter+1 ))
done