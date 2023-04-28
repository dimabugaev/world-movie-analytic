
variable "region" {
  type = string
  default = "europe-central2"
}

variable "project_name" {
  type = string  
}

variable "state_backet_name" {
  type = string  
}

terraform {
  required_version = ">= 1.0"
  backend "gcs" {}  
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      #version = ">= 2.0.3"
    }
    google = {
      source  = "hashicorp/google"
      #version = "3.52"
    }
  }
}


locals {
  project = var.project_name
  region = var.region
  bq_dataset_name = "${var.project_name}_dataset"
  docker_image = "prefect-gcp:2-python3.9"
  gcr_addres = "eu.gcr.io"
}

provider "google" {
  project = local.project
  region = local.region
  // credentials = file(var.credentials)  # Use this if you do not want to set env-var GOOGLE_APPLICATION_CREDENTIALS
}

resource "google_storage_bucket" "raw-movie-data" {
  name          = "raw_movie_data_${local.project}" # Concatenating DL bucket & Project name for unique naming
  location      = local.region

  # Optional, but recommended settings:
  storage_class = "STANDARD"
  uniform_bucket_level_access = true

  versioning {
    enabled     = false
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 30  // days
    }
  }

  force_destroy = true
}

resource "google_storage_bucket" "cloud-run-job-data" {
  name          = "cloud-run-job-test-bucket" # Concatenating DL bucket & Project name for unique naming
  location      = local.region

  # Optional, but recommended settings:
  storage_class = "STANDARD"
  uniform_bucket_level_access = true

  versioning {
    enabled     = false
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 30  // days
    }
  }

  force_destroy = true
}

resource "google_bigquery_dataset" "dataset" {
  dataset_id = local.bq_dataset_name
  project    = local.project
  location   = local.region
}

resource "google_artifact_registry_repository" "my-repo" {
  location      = local.region
  repository_id = "my-repository-${local.project}"
  description   = "Docker repository for perfect flows run"
  format        = "DOCKER"
}

resource "null_resource" "docker_build" {

    triggers = {
        always_run = timestamp()

    }

    provisioner "local-exec" {
        working_dir = "../extract-inject-prefect-docker/"

        command     = "docker build -t ${local.gcr_addres}/${local.project}/${resource.google_artifact_registry_repository.my-repo.repository_id}/${local.docker_image} --build-arg P_KAGGLE_USERNAME=$KAGGLE_USERNAME --build-arg P_KAGGLE_KEY=$KAGGLE_KEY . && docker login -u _json_key --password-stdin https://${local.gcr_addres} < $GOOGLE_APPLICATION_CREDENTIALS && docker push ${local.gcr_addres}/${local.project}/${resource.google_artifact_registry_repository.my-repo.repository_id}/${local.docker_image}"
    }
}

resource "null_resource" "docker_dbt_build" {

    triggers = {
        always_run = timestamp()

    }

    provisioner "local-exec" {
        working_dir = "../transform_dbt/"

        command     = "docker build -t ${local.gcr_addres}/${local.project}/${resource.google_artifact_registry_repository.my-repo.repository_id}/dbt --build-arg P_GCP_KEYFILE=$GOOGLE_APPLICATION_CREDENTIALS --build-arg P_GCP_BQ_DATASET=${local.bq_dataset_name} --build-arg P_GCP_REGION=${local.region} --build-arg P_GCP_PROJECT=${local.project} . && docker login -u _json_key --password-stdin https://${local.gcr_addres} < $GOOGLE_APPLICATION_CREDENTIALS && docker push ${local.gcr_addres}/${local.project}/${resource.google_artifact_registry_repository.my-repo.repository_id}/dbt"
    }
}


resource "google_container_cluster" "primary" {
  name     = "${local.project}-gke"
  location = local.region
 
  project = local.project

  #network    = google_compute_network.vpc.name
  #subnetwork = google_compute_subnetwork.subnet.name
 
# Enabling Autopilot for this cluster
  enable_autopilot = true
}


provider "kubernetes" {
  
  host = google_container_cluster.primary.endpoint
  
  #cluster_ca_certificate = base64decode(data.google_container_cluster.default.master_auth.0.cluster_ca_certificate)
  #client_certificate     = base64decode(data.google_container_cluster.default.master_auth.0.client_certificate)
  #client_key             = data.google_container_cluster.default.master_auth.0.client_key
  
  #load_config_file       = false
}

resource "kubernetes_manifest" "my_config" {
  yaml_body = file("k8s.cfg")
}

output "image_python_prefect" {
  value = "${local.gcr_addres}/${local.project}/${resource.google_artifact_registry_repository.my-repo.repository_id}/${local.docker_image}"
}

output "image_python_dbt" {
  value = "${local.gcr_addres}/${local.project}/${resource.google_artifact_registry_repository.my-repo.repository_id}/dbt"
}