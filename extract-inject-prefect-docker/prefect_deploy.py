from cloud_run_job_script import cloud_run_job_flow
from prefect import get_client
from prefect.deployments import Deployment

from prefect_gcp import GcpCredentials, CloudRunJob, GcsBucket

client = get_client()

gcs_block = GcsBucket.load("world-movies-test-bucket")
cloud_run_job_block = CloudRunJob.load("world-movies-test-job")


deployment = Deployment.build_from_flow(
    flow=cloud_run_job_flow,
    name="GCP test flow",
    storage=gcs_block,
    infrastructure=cloud_run_job_block,
    #work_queue_name="kubernetes",
)

if __name__ == "__main__":
    deployment.apply()