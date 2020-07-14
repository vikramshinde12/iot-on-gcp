provider "google" {
  project = var.project_name
  region = var.region
  zone = var.zone
}

#-------------------------------------------------------
# Enable APIs
#    - Cloud Function
#    - Pub/Sub
#    - Firestore
#    - Cloud IoT
#    - Dataflow
#-------------------------------------------------------

module "project_services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "3.3.0"

  project_id    = var.project_name
  activate_apis =  [
    "cloudresourcemanager.googleapis.com",
    "cloudfunctions.googleapis.com",
    "pubsub.googleapis.com",
    "firestore.googleapis.com",
    "dataflow.googleapis.com",
    "cloudiot.googleapis.com"
  ]

  disable_services_on_destroy = false
  disable_dependent_services  = false
}

#---------------------------------------------------------
# Create Pub/Sub Topic
# IOT-EVENT
# ALERT
#---------------------------------------------------------

resource "google_pubsub_topic" "pubsub" {
  name = "iot-event-topic"
  depends_on = [module.project_services]
}


resource "google_pubsub_topic" "alert-topic" {
  name = "alert-topic"
  depends_on = [module.project_services]
}


resource "google_pubsub_subscription" "echo" {
  name = "echo"
  topic = google_pubsub_topic.pubsub.name
}


#--------------------------------------------------------------------------------
# Event Collection Function
#  - Create source bucket
#  - Copy code from local into bucket
#  - Create function using source code and trigger based on pub/sub
#--------------------------------------------------------------------------------

resource "google_storage_bucket" "bucket" {
  name = "${var.project_name}-source-bucket1"
}

resource "google_storage_bucket_object" "archive" {
  name = "event-collection.zip"
  bucket = google_storage_bucket.bucket.name
  source = "./event-collection.zip"
}

resource "google_cloudfunctions_function" "function" {
  name = "event-collection"
  runtime = "python37"
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.archive.name

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource = google_pubsub_topic.pubsub.name
  }
  entry_point = "hello_pubsub"
  labels = {
    app = "iot-demo"
  }

  environment_variables = {
    ALERT_TOPIC = google_pubsub_topic.alert-topic.name
  }
  depends_on = [google_pubsub_topic.pubsub, google_pubsub_topic.alert-topic]
}


#--------------------------------------------------------------------------------
# Event Collection Function
#  - Copy code from local into the existing source bucket
#  - Create function using source code and trigger based on pub/sub
#--------------------------------------------------------------------------------

resource "google_storage_bucket_object" "archive2" {
  name = "alert-email-function.zip"
  bucket = google_storage_bucket.bucket.name
  source = "./alert-email-function.zip"
}

resource "google_cloudfunctions_function" "alert-function" {
  name = "alert-email-function"
  runtime = "python37"
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.archive2.name

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource = google_pubsub_topic.alert-topic.name
  }
  entry_point = "hello_pubsub"
  labels = {
    app = "iot-demo"
  }

  environment_variables = {
    ALERT_TOPIC = google_pubsub_topic.alert-topic.name
    SENDGRID_API_KEY = var.sendgrid_api_key
    FROM_EMAIL = var.from_email
    TO_EMAIL = var.to_email
    SUBJECT = var.alert_email_subject
  }
}


resource "google_bigquery_dataset" "dataset" {
  dataset_id = "iot_dataset"
  friendly_name = "iot"
  description = "This is a IOT dataset"

  default_table_expiration_ms = 3600000

  labels = {
    env = "iot-demo"
  }
}


resource "google_bigquery_table" "device-data" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  table_id   = "device_data"
  schema = file("${path.module}/schema.json")
}


resource "google_dataflow_job" "ps_to_bq_job" {
  name              = "ps-to-bq-iot-event-topic"
  max_workers = 1
  on_delete = "cancel"
  template_gcs_path = "gs://dataflow-templates-us-central1/latest/PubSub_to_BigQuery"
  temp_gcs_location = "${google_storage_bucket.bucket.url}/tmp"
  parameters = {
    inputTopic = google_pubsub_topic.pubsub.id
    outputTableSpec = "${var.project_name}:${google_bigquery_table.device-data.dataset_id}.${google_bigquery_table.device-data.table_id}"
  }
}


resource "google_cloudiot_registry" "registry" {
  name     = "cloudiot-registry"

  event_notification_configs {
    pubsub_topic_name = google_pubsub_topic.pubsub.id
    subfolder_matches = ""
  }

  mqtt_config = {
    mqtt_enabled_state = "MQTT_ENABLED"
  }

  http_config = {
    http_enabled_state = "HTTP_ENABLED"
  }
  log_level = "INFO"
}

resource "null_resource" "generate-key" {
  provisioner "local-exec" {
    command = "sh ../devices/generate-key.sh"
    interpreter = ["/bin/bash", "-c"]
  }
}

resource "null_resource" "register-devices" {
  provisioner "local-exec" {
    command = "sh ../devices/register-device.sh ${var.project_name} ${var.region} ${google_cloudiot_registry.registry.name} ${var.num_of_devices}"
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = [google_cloudiot_registry.registry, null_resource.generate-key]
}

resource "null_resource" "device-config" {
  provisioner "local-exec" {
    command = "sh ../devices/device-config-data.sh ${var.num_of_devices}"
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = [null_resource.register-devices]
}

resource "null_resource" "run-simulated-devices" {
  provisioner "local-exec" {
    command = "sh ../devices/run-docker-containers.sh ${var.project_name} ${var.region} ${google_cloudiot_registry.registry.name} ${var.num_of_devices}"
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = [null_resource.device-config, google_cloudiot_registry.registry]
}