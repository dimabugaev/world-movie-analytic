import os
from prefect_gcp import GcpCredentials, CloudRunJob, GcsBucket
import json


with open(os.environ['GOOGLE_APPLICATION_CREDENTIALS']) as json_cred:
     service_account_info = json.load(json_cred)    

     if len(service_account_info) > 0:
         GcpCredentials(
         service_account_info=service_account_info
         ).save("world-movies-analytics-cred", overwrite=True)

gcp_credentials = GcpCredentials.load("world-movies-analytics-cred")


# must be from GCR and have Python + Prefect
image_main = os.environ['IMAGE_MAIN']  
image_dbt = os.environ['IMAGE_DBT'] 
region = os.environ['TF_VAR_region']

cloud_run_main = CloudRunJob(
    image=image_main,
    credentials=gcp_credentials,
    region=region,
    memory=3,
    memory_unit = "Gi",
)
cloud_run_main.save("world-movies-main-job", overwrite=True)

cloud_run_dbt = CloudRunJob(
    image=image_dbt,
    credentials=gcp_credentials,
    region=region,
    memory=1,
    memory_unit = "Gi",
)
cloud_run_dbt.save("world-movies-dbt-job", overwrite=True)

bucket_name = "cloud-run-job-test-bucket"
gcs_bucket = GcsBucket(
    bucket=bucket_name,
    gcp_credentials=gcp_credentials,
)
gcs_bucket.save("world-movies-test-bucket", overwrite=True)

# bucket_name = "raw_movie_data_world-movies-analytics"

# gcs_bucket = GcsBucket(
#     bucket=bucket_name,
#     gcp_credentials=gcp_credentials,
# )
# gcs_bucket.save("world-movies-raw-bucket", overwrite=True)