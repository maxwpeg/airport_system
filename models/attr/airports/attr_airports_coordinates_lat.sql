{{ config(materialized='incremental', unique_key='attribute_key') }}

SELECT
    md5(cast(airport_code || after_coordinates_lat as varchar)) AS attribute_key,
    md5(cast(airport_code as varchar)) AS anchor_key,
    after_coordinates_lat AS coordinates_lat,
    source_txId AS source_system_id,
    ts_ms AS createdAt
FROM {{ source('vertica', 'postgres_public_airports') }}
