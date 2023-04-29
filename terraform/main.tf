
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
  bq_dataset_name = "world_movie_dataset"
  docker_image = "prefect-gcp:2-python3.9"
  gcr_addres = "eu.gcr.io"
  k8s_file = file("./k8s.cfg")
}

provider "google" {
  project = local.project
  region = local.region
  // credentials = file(var.credentials)  # Use this if you do not want to set env-var GOOGLE_APPLICATION_CREDENTIALS
}

# resource "google_storage_bucket" "raw-movie-data" {
#   name          = "raw-movie-data_${local.project}" # Concatenating DL bucket & Project name for unique naming
#   location      = local.region

#   # Optional, but recommended settings:
#   storage_class = "STANDARD"
#   uniform_bucket_level_access = true

#   versioning {
#     enabled     = false
#   }

#   lifecycle_rule {
#     action {
#       type = "Delete"
#     }
#     condition {
#       age = 30  // days
#     }
#   }

#   force_destroy = true
# }

resource "google_storage_bucket" "cloud-run-job-data" {
  name          = "cloud-run-job-bucket-${local.project}" # Concatenating DL bucket & Project name for unique naming
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

        command     = "echo \"{\"username\":\"$KAGGLE_USERNAME\",\"key\":\"$KAGGLE_KEY\"}\" > kaggle.json && docker build -t ${local.gcr_addres}/${local.project}/${resource.google_artifact_registry_repository.my-repo.repository_id}/${local.docker_image} --build-arg P_KAGGLE_USERNAME=$KAGGLE_USERNAME --build-arg P_KAGGLE_KEY=$KAGGLE_KEY . && docker login -u _json_key --password-stdin https://${local.gcr_addres} < $GOOGLE_APPLICATION_CREDENTIALS && docker push ${local.gcr_addres}/${local.project}/${resource.google_artifact_registry_repository.my-repo.repository_id}/${local.docker_image}"
    }
}

resource "null_resource" "docker_dbt_build" {

    triggers = {
        always_run = timestamp()

    }

    provisioner "local-exec" {
        working_dir = "../transform_dbt/"

        command     = "cp $GOOGLE_APPLICATION_CREDENTIALS config/gcpkeyfile.json && docker build -t ${local.gcr_addres}/${local.project}/${resource.google_artifact_registry_repository.my-repo.repository_id}/dbt --build-arg P_GCP_BQ_DATASET=${local.bq_dataset_name} --build-arg P_GCP_REGION=${local.region} --build-arg P_GCP_PROJECT=${local.project} . && docker login -u _json_key --password-stdin https://${local.gcr_addres} < $GOOGLE_APPLICATION_CREDENTIALS && docker push ${local.gcr_addres}/${local.project}/${resource.google_artifact_registry_repository.my-repo.repository_id}/dbt && rm -rf config/gcpkeyfile.json"
    }
}


resource "google_container_cluster" "primary" {
  name     = "${local.project}-gke"
  location = local.region
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = ""
    services_ipv4_cidr_block = ""
  }
  project = local.project

  #network    = google_compute_network.vpc.name
  #subnetwork = google_compute_subnetwork.subnet.name
 
# Enabling Autopilot for this cluster
  enable_autopilot = true
}

module "gke_auth" {
  source               = "terraform-google-modules/kubernetes-engine/google//modules/auth"

  project_id           = local.project
  cluster_name         = google_container_cluster.primary.name
  location             = local.region
  use_private_endpoint = true
}

# provider "kubernetes" {
#   cluster_ca_certificate = module.gke_auth.cluster_ca_certificate
#   host                   = module.gke_auth.host
#   token                  = module.gke_auth.token
# }

provider "kubectl" {
  host                   = module.gke_auth.host
  cluster_ca_certificate = module.gke_auth.cluster_ca_certificate
  token                  = module.gke_auth.token
  load_config_file       = false
}

resource "kubectl_manifest" "test" {
    yaml_body = file("./k8s.cfg")

}

# provider "kubernetes" {
  
#   host = google_container_cluster.primary.endpoint
  
#   #cluster_ca_certificate = base64decode(data.google_container_cluster.default.master_auth.0.cluster_ca_certificate)
#   #client_certificate     = base64decode(data.google_container_cluster.default.master_auth.0.client_certificate)
#   #client_key             = data.google_container_cluster.default.master_auth.0.client_key
  
#   #load_config_file       = false
# }

# resource "kubernetes_manifest" "my_config" {
#   provider = kubernetes
#   #  for_each = {
#   #    for value in [
#   #      for yaml in split(
#   #        "\n---\n",
#   #        "\n${replace(local.k8s_file, "/(?m)^---[[:blank:]]*(#.*)?$/", "---")}\n"
#   #      ) :
#   #      yamldecode(yaml)
#   #      if trimspace(replace(yaml, "/(?m)(^[[:blank:]]*(#.*)?$)+/", "")) != ""
#   #    ] : "${value["kind"]}--${value["metadata"]["name"]}" => value
#   #  }
#   #  manifest = each.value
#   manifest = file("./k8s.cfg")
# }

output "image_python_prefect" {
  value = "${local.gcr_addres}/${local.project}/${resource.google_artifact_registry_repository.my-repo.repository_id}/${local.docker_image}"
}

output "image_python_dbt" {
  value = "${local.gcr_addres}/${local.project}/${resource.google_artifact_registry_repository.my-repo.repository_id}/dbt"
}

output "cloud_run_job_bucket" {
  value = google_storage_bucket.cloud-run-job-data.name
}

output "cluster_name" {
  value = google_container_cluster.primary.name
}
