

INSTALL

IN GCP 

1. Create trial GCP account
2. Create new progect
3. Create bucket for Terraform states files
4. Create service account with roles 
    a. Kubernetes Engine Admin
    b. Artifact Registry Administrator
    c. BigQuery Admin
    d. Cloud Run Admin
    e. Storage Admin
5. Create and download private key JSON
6. Enable on API
    a. Kubernetes Engine API
    b. Artifact Registry API
    c. BigQuery API
    d. Cloud Run API
    e. Cloud Storage 

IN PREFECT CLOUD

1. Log in https://app.prefect.cloud
2. Create API Key in profile settings and copy login command it will be showed just once

prefect cloud login -k pnu_rVsf8cVuljZlESwl5atvingCwBh2ZY1bJI9i

LOCAL 



1. Create new project directory for example wma-project
    cd ~
    mkdir wma-project
    cd wma-project
2. Clone GitHub repository to new directory
    git clone https://github.com/dimabugaev/world-movie-analytic.git .
3. Must be installed 
    a. python 3
    c. terraform 
4. Create and activate venv 
    python3 -m venv wma-env
    source wma-env/bin/activate
5. Setup env-var
    a. GOOGLE_APPLICATION_CREDENTIALS - full path to GCP private key JSON
    export GOOGLE_APPLICATION_CREDENTIALS=${FULLPATHTOKEY}/world-movie-data-project-05529ebbd593.json
    b. TF_VAR_project_name - created GCP project name
    export TF_VAR_project_name=world-movie-data-project
    c. TF_VAR_state_backet_name - bucket name for Terraform states
    export TF_VAR_state_backet_name=world-movie-terraform-state
    d. TF_VAR_region - region GCP
    export TF_VAR_region=europe-central2

6. Terraform init
    terraform init -backend-config "bucket=$TF_VAR_state_backet_name"
    