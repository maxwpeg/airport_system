SELECT
    md5(cast(flight_id || after_actual_departure as varchar)) AS attribute_key,
    md5(cast(flight_id as varchar)) AS anchor_key,
    after_actual_departure AS actual_departure,
    source_txId AS source_system_id,
    ts_ms AS createdAt
FROM {{ source('vertica', 'postgres_public_flights') }}
