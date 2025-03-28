from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime, timedelta

DEFAULT_ARGS = {
    'owner': 'komarov',
    'depends_on_past': False,
    'start_date': datetime.today() - timedelta(days=1),
    'email': None,
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 0,
    'retry_delay': timedelta(minutes=5),
    'execution_timeout': timedelta(minutes=120)
}

with DAG("dbt_dwh",
         default_args=DEFAULT_ARGS,
         catchup=False,
         schedule_interval="*/5 * * * *",
         max_active_runs=1,
         concurrency=1) as dag:

    task = BashOperator(
    task_id="dbt_run",
    bash_command="cd /opt/airflow/dbt && dbt run --select \"models/dwh\" || true",
    dag=dag,
    )
