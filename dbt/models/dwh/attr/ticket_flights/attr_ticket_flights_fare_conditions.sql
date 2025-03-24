SELECT
    md5(cast(flight_id || ticket_no || after_fare_conditions as varchar)) AS attribute_key,
    md5(cast(flight_id || ticket_no as varchar)) AS anchor_key,
    after_fare_conditions AS fare_conditions,
    source_txId AS source_system_id,
    ts_ms AS createdAt
FROM {{ source('vertica', 'postgres_public_ticket_flights') }}
