FROM python:3.7

MAINTAINER Vikram Shinde "vik.shinde@gmail.com"

COPY requirements.txt /requirements.txt

WORKDIR /

ENV device_id="device3"
ENV project_id="demo"
ENV cloud_region="us-central1"
ENV registry_id="cloudiot-registry"
ENV private_key_file="./rsa_private.pem"

RUN pip3 install -r requirements.txt

COPY . /

CMD python api.py  \
       --registry_id=$registry_id \
       --cloud_region=$cloud_region        \
       --project_id=$project_id        \
       --device_id=$device_id        \
       --algorithm=RS256        \
       --private_key_file=$private_key_file