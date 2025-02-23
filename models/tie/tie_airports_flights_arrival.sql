{{ config(materialized='table') }}

SELECT
    md5(cast(flight_id || after_arrival_airport as varchar)) AS tie_key,
    md5(cast(flight_id as varchar)) AS flight,
    md5(cast(after_arrival_airport as varchar)) AS arrival_airport,
    source_txId AS source_system_id,
    ts_ms AS createdAt
FROM {{ source('vertica', 'postgres_public_flights') }}
