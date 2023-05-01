

INSTALL

IN KAGGLE (it's source kaggle.com)

1. Create profile in Kaggle (if not exist)
2. Create API token and download kaggle.json in profile settings 

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
    f. Service Account User 

IN PREFECT CLOUD

1. Log in https://app.prefect.cloud
2. Create API Key in profile settings and copy login command it will be showed just once
3. Create Workspace any name

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
    b. gcloud
    c. docker
    d. terraform
    e. prefect
    f. dbt (min 1.5.0) 
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
    e. KAGGLE_USERNAME - username from kaggle.json
    export KAGGLE_USERNAME=bo0gie
    f. KAGGLE_KEY - key from kaggle.json
    export KAGGLE_KEY=8329bfc0498057617a58d400c42dda52

6. Connect prefect to prefect cloud through API KEY
    prefect cloud login -k ${API_KEY}

7. Add bloks GCP to prefect
    prefect block register -m prefect_gcp

8. Install local lib prefect-gcp
    pip install prefect-gcp
    pip install dbt-bigquery
    pip install python-terraform  

9. Make kubernetes manifest for prefect agent
    prefect kubernetes manifest agent -i prefecthq/prefect:2-python3.9 -q default > terraform/k8s.cfg

10. gcloud init

11. Terraform init and apply
    cd terraform
    terraform init -backend-config "bucket=$TF_VAR_state_backet_name"
    terraform apply

12. Setup prefect blocks for deploymen
    export IMAGE_DBT=$(terraform output image_python_dbt)
    export IMAGE_MAIN=$(terraform output image_python_prefect)
    export JOB_BUCKET_NAME=$(terraform output cloud_run_job_bucket)
    cd ../extract-inject-prefect-docker/
    python3 setup_prefect.py


