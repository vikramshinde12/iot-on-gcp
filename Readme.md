## The End-2-End IoT Processing in Google Cloud Platform
Following components are used
* IoT Core
* Pub/Sub
* Dataflow
* BigQuery
* Data Studio
* Cloud Function
* Cloud Firestore

![Architecture](https://github.com/vikramshinde12/iot-on-gcp/blob/master/Architecture?raw=true)

### Create Service Account
1. Create Service Account
2. Assign the Editor Role.
3. Download the key and renamed it as terraform-key.json

### Create Config data in Firestore

1. Go to Firestore
2. Select Native Mode
3. Select a Location (e.g. United States)
4. Click on "Create Database"

### Create Infrastructure using Terraform
1. Create Project
2. Create SA, Assign the roles: Editor 
and download key as terraform.json
3. export GOOGLE_CLOUD_KEYFILE_JSON=terraform-key.json
4. terraform init
5. terraform plan
6. terraform apply


The complete detail about this repo is available in the [please refer the blog](https://medium.com/@vikramshinde/iot-in-google-cloud-platform-9708a82c2dea)