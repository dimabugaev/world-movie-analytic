from prefect import flow, task
from dbt.cli.main import dbtRunner, dbtRunnerResult

@task(log_prints=True)
def invoke_dbt():
    # initialize
    dbt = dbtRunner()
    # create CLI args as a list of strings
    cli_args = ['run', '--project', 'transform_dbt']
    # run the command
    res: dbtRunnerResult = dbt.invoke(cli_args)

    return res

@task(log_prints=True)
def print_result(res : dbtRunnerResult):

    # inspect the results
    for r in res.result:
        print(f"{r.node.name}: {r.status}")


@flow(log_prints=True)
def cloud_run_dbt_flow():
    res = invoke_dbt()
    print_result(res)