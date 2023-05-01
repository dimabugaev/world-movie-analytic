from prefect import flow, task
from dbt.cli.main import dbtRunner, dbtRunnerResult

@task(log_prints=True)
def invoke_dbt_seed():
    # initialize
    dbt = dbtRunner()
    # create CLI args as a list of strings
    cli_args = ['seed', '--project-dir', '/dbt', '--profiles-dir', '/root/.dbt']
    # run the command
    res: dbtRunnerResult = dbt.invoke(cli_args)

    return res

@task(log_prints=True)
def invoke_dbt_run():
    # initialize
    dbt = dbtRunner()
    # create CLI args as a list of strings
    cli_args = ['run', '--project-dir', '/dbt', '--profiles-dir', '/root/.dbt']
    # run the command
    res: dbtRunnerResult = dbt.invoke(cli_args)

    return res

@task(log_prints=True)
def print_result(res : dbtRunnerResult):

    if res.result is not None:
    # inspect the results
        for r in res.result:
            print(f"{r.node.name}: {r.status}")
    else:
        print(res.exception)


@flow(log_prints=True)
def cloud_run_dbt_flow():
    # res = invoke_dbt_seed()
    # print_result(res)
    res = invoke_dbt_run()
    print_result(res)