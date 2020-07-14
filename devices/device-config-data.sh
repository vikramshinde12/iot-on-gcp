#!/bin/bash

NUM_OF_DEVICES=$1

pip install google-cloud-firestore
export GOOGLE_APPLICATION_CREDENTIALS=./terraform-key.json
python ../devices/create_temp_alert_store.py $NUM_OF_DEVICES
