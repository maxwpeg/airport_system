import requests
import os
from typing import Dict, Any

DEBEZIUM_URL = 'http://debezium:8083/connectors'

pg_connector_config = {
  "name": "pg-connector",
  "config": {
    "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
    "plugin.name": "pgoutput",

    "database.hostname": "postgres_master",
    "database.port": "5432",
    "database.user": "postgres",
    "database.password": "postgres",
    "database.dbname" : "postgres",
    "database.server.name": "pg-dev",

    "table.include.list": "public.(.*)",
    "heartbeat.interval.ms": "5000",
    "slot.name": "dbname_debezium",
    "publication.name": "dbname_publication",

    "topic.creation.default.cleanup.policy": "delete",
    "topic.creation.default.partitions": "1",
    "topic.creation.default.replication.factor": "1",
    "topic.creation.default.retention.ms": "604800000",
    "topic.creation.enable": "true",
    "topic.prefix": "postgres"
  }
}

sink_connectors_info = {
    'postgres.public.aircraft': 'aircraft_code',
    'postgres.public.airports': 'airport_code',
    'postgres.public.boarding_passes': 'flight_id, ticket_no',
    'postgres.public.bookings': 'book_ref',
    'postgres.public.flights': 'flight_id',
    'postgres.public.seats': 'aircraft_code, seat_no',
    'postgres.public.ticket_flights': 'flight_id, ticket_no',
    'postgres.public.tickets': 'ticket_no'
}

def add_connector(connector_dict: Dict[str, Any]) -> None:
    response = requests.post(
        DEBEZIUM_URL,
        json=connector_dict
    )
    assert response.status_code < 400, response.text


def add_pg_connector() -> None:
    add_connector(pg_connector_config)


def add_sink_connectors() -> None:
    for topic, record_keys in sink_connectors_info.items():
        add_connector(
            {
            "name": topic.replace('.', '-'),
            "config": {
                "connector.class": "io.debezium.connector.jdbc.JdbcSinkConnector",
                "topics": topic,
                "connection.url": "jdbc:postgresql://postgres_dwh:5432/postgres",
                "connection.username": "postgres",
                "connection.password": "postgres",
                "tasks.max":"1",
                "insert.mode": "upsert",
                "delete.enabled": "false",
                "primary.key.mode": "record_key",
                "primary.key.fields": record_keys,
                "schema.evolution": "basic"
                }
            }
        )

add_pg_connector()
add_sink_connectors()
os.system("docker stop connector")