from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime, timedelta

DEFAULT_ARGS = {
    'owner': 'komarov',
    'depends_on_past': False,
    'start_date': datetime.today() - timedelta(days=2),
    'email': None,
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 0,
    'retry_delay': timedelta(minutes=5),
    'execution_timeout': timedelta(minutes=120)
}

with DAG("dbt_airports_traffic_mart",
         default_args=DEFAULT_ARGS,
         catchup=False,
         schedule_interval="@daily",
         max_active_runs=1,
         concurrency=1) as dag:

    task1 = BashOperator(
    task_id="delete",
    bash_command="sleep 15 && cd /opt/airflow/dbt && dbt run --select \"models/mart/airports_traffic_clear.sql\" --vars '{\"business_date\": \"{{ macros.ds_add(ds, -1) }}\"}' || true",
    dag=dag,
    )

    task2 = BashOperator(
    task_id="insert",
    bash_command="cd /opt/airflow/dbt && dbt run --select \"models/mart/airports_traffic.sql\" --vars '{\"business_date\": \"{{ macros.ds_add(ds, -1) }}\"}' || true",
    dag=dag,
    )

    task1 >> task2
