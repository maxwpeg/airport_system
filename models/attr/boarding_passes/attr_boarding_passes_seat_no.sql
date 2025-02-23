{{ config(materialized='incremental', unique_key='attribute_key') }}

SELECT
    md5(cast(flight_id || ticket_no || after_seat_no as varchar)) AS attribute_key,
    md5(cast(flight_id || ticket_no as varchar)) AS anchor_key,
    after_seat_no AS seat_no,
    source_txId AS source_system_id,
    ts_ms AS createdAt
FROM {{ source('vertica', 'postgres_public_boarding_passes') }}
