from prefect import flow, task
import os
import subprocess
#from prefect_gcp.cloud_storage import GcsBucket
from zipfile import ZipFile
import pandas as pd
from prefect_gcp import GcpCredentials
from prefect.deployments import run_deployment

@task(log_prints=True)
def download_dataset():
    print(subprocess.getoutput("kaggle datasets download -d akshaypawar7/millions-of-movies"))

@task(log_prints=True)    
def unzip_and_put_to_bq():
    with ZipFile('millions-of-movies.zip', 'r') as f:
        f.extractall()

    gcp_credentials_block = GcpCredentials.load("world-movies-analytics-cred")

    df = pd.read_csv("movies.csv")
    df.to_gbq(destination_table='world_movie_dataset.movies',
                project_id='world-movie-data-project',
                chunksize=500000,
                if_exists='replace',
                credentials=gcp_credentials_block.get_credentials_from_service_account())
    
    #gcp_cloud_storage_bucket_block = GcsBucket.load("world-movies-raw-bucket")
    #gcp_cloud_storage_bucket_block.upload_from_path(from_path="movies.csv", to_path="movies.csv")

@task(log_prints=True)
def run_transform_dbt():
    response = run_deployment(name="cloud-run-dbt-flow/DbtFlow")
    print(response)

@flow(log_prints=True)
def cloud_run_main_flow():
    
    download_dataset()
    unzip_and_put_to_bq()
    run_transform_dbt()


if __name__ == "__main__":
    cloud_run_main_flow()