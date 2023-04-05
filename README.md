1 Create project in GCP
2 Create service user + add roles + create accounts keys JSON 
3 Create bucket for terraform state
4 Change main.tf locals for your GCP project name and bucket for terraform state
5 Set enviroment var GOOGLE_APPLICATION_CREDENTIALS path to your JSON keys
6 Enable BigQuery API
7 Create infrastructure by terraform

eu.gcr.io/world-movies-analytics/my-repository-world-movies-analytics/prefect-gcp:2-python3.9