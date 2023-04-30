from cloud_run_main_script import cloud_run_main_flow
from cloud_run_dbt_script import cloud_run_dbt_flow
from prefect import get_client
from prefect.deployments import Deployment
from prefect.server.schemas.schedules import CronSchedule

from prefect_gcp import CloudRunJob, GcsBucket

client = get_client()

gcs_block = GcsBucket.load("world-movies-test-bucket")
cloud_run_main_block = CloudRunJob.load("world-movies-main-job")

cloud_run_dbt_block = CloudRunJob.load("world-movies-dbt-job")


deployment_dbt = Deployment.build_from_flow(
    flow=cloud_run_dbt_flow,
    name="DbtFlow",
    storage=gcs_block,
    infrastructure=cloud_run_dbt_block,
    #work_queue_name="kubernetes",
)

deployment_main = Deployment.build_from_flow(
    flow=cloud_run_main_flow,
    name="MainFlow",
    storage=gcs_block,
    infrastructure=cloud_run_main_block,
    schedule=CronSchedule(cron="0 0 * * *"),
    #work_queue_name="kubernetes",
)

if __name__ == "__main__":
    deployment_dbt.apply()
    deployment_main.apply()