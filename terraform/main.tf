
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
    google = {
      source  = "hashicorp/google"
    }
  }
}

data "terraform_remote_state" "state" {
  backend = "gcs"
  config {
    #bucket     = "${var.tf_state_bucket}"
    bucket     = var.state_backet_name
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

        command     = "docker build -t ${local.gcr_addres}/${local.project}/${resource.google_artifact_registry_repository.my-repo.repository_id}/${local.docker_image} . && docker login -u _json_key --password-stdin https://${local.gcr_addres} < $GOOGLE_APPLICATION_CREDENTIALS && docker push ${local.gcr_addres}/${local.project}/${resource.google_artifact_registry_repository.my-repo.repository_id}/${local.docker_image}"
    }
}

 
module "gke" {
  source     = "terraform-google-modules/kubernetes-engine/google"
  project_id = local.project
  name       = "prefect-agent-cluster"
  regional   = true
  region     = local.region
  release_channel        = "REGULAR"
  horizontal_pod_autoscaling = true

  network    = "default"
  subnetwork = "default"
  #network    = var.network
  #subnetwork = var.subnetwork

  ip_range_pods          = "ip-range-pods-simple-autopilot-public"
  ip_range_services      = "ip-range-svc-simple-autopilot-public"
  #create_service_account = false
  #service_account        = var.compute_engine_service_account
}
