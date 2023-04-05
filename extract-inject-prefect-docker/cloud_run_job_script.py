from prefect import flow, task
import os
import subprocess
#from prefect_gcp.cloud_storage import GcsBucket
from zipfile import ZipFile
import pandas as pd
from prefect_gcp import GcpCredentials

@task(log_prints=True)
def download_dataset():
    #od.download("https://www.kaggle.com/akshaypawar7/millions-of-movies")
    print(subprocess.getoutput("kaggle datasets download -d akshaypawar7/millions-of-movies"))

@task(log_prints=True)    
def unzip_and_put_to_bq():
    with ZipFile('millions-of-movies.zip', 'r') as f:
        f.extractall()

    gcp_credentials_block = GcpCredentials.load("world-movies-analytics-cred")

    df = pd.read_csv("movies.csv")
    df.to_gbq(destination_table='world_movie_dataset.movies',
                project_id='world-movies-analytics',
                chunksize=500000,
                if_exists='replace',
                credentials=gcp_credentials_block.get_credentials_from_service_account())
    
    #gcp_cloud_storage_bucket_block = GcsBucket.load("world-movies-raw-bucket")
    #gcp_cloud_storage_bucket_block.upload_from_path(from_path="movies.csv", to_path="movies.csv")


@flow(log_prints=True)
def cloud_run_job_flow():
    
    #print(subprocess.getoutput("ls"))
    #print(subprocess.check_output("cd .kaggle", shell=True))
    #os.system('cd .kaggle')
    #print(subprocess.getoutput("ls"))
    #print(subprocess.getoutput("kaggle --help"))
    
    download_dataset()
    unzip_and_put_to_bq()


if __name__ == "__main__":
    cloud_run_job_flow()