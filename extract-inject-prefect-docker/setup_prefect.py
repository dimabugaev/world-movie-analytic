#kaggle datasets download -d akshaypawar7/millions-of-movies
# from prefect_gcp import GcpCredentials
# import json
# import os



# with open(os.environ['GOOGLE_APPLICATION_CREDENTIALS']) as json_cred:
#     service_account_info = json.load(json_cred)    

#     if len(service_account_info) > 0:
#         GcpCredentials(
#         service_account_info=service_account_info
#         ).save("world-movies-analytics-cred")


import os
from prefect_gcp import GcpCredentials, CloudRunJob, GcsBucket

gcp_credentials = GcpCredentials.load("world-movies-analytics-cred")

# must be from GCR and have Python + Prefect
image = "eu.gcr.io/world-movies-analytics/my-repository-world-movies-analytics/prefect-gcp:2-python3.9"  # noqa

cloud_run_job = CloudRunJob(
    image=image,
    credentials=gcp_credentials,
    region="europe-central2",
    memory=3,
    memory_unit = "Gi",
)
cloud_run_job.save("world-movies-test-job", overwrite=True)

bucket_name = "cloud-run-job-test-bucket"
gcs_bucket = GcsBucket(
    bucket=bucket_name,
    gcp_credentials=gcp_credentials,
)
gcs_bucket.save("world-movies-test-bucket", overwrite=True)

bucket_name = "raw_movie_data_world-movies-analytics"

gcs_bucket = GcsBucket(
    bucket=bucket_name,
    gcp_credentials=gcp_credentials,
)
gcs_bucket.save("world-movies-raw-bucket", overwrite=True)