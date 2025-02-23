{{ config(materialized='table') }}

SELECT
    md5(cast(aircraft_code || seat_no as varchar)) AS anchor_key,
    aircraft_code || seat_no AS business_key,
    source_txId AS source_system_id,
    ts_ms AS createdAt
FROM {{ source('vertica', 'postgres_public_seats') }}
