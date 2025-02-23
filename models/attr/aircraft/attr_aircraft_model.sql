{{ config(materialized='incremental', unique_key='attribute_key') }}

SELECT
    md5(cast(aircraft_code || after_model as varchar)) AS attribute_key,
    md5(cast(aircraft_code as varchar)) AS anchor_key,
    after_model AS model,
    source_txId AS source_system_id,
    ts_ms AS createdAt
FROM {{ source('vertica', 'postgres_public_aircraft') }}
