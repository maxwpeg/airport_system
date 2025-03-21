SELECT
    md5(cast(flight_id || after_departure_airport as varchar)) AS attribute_key,
    md5(cast(flight_id as varchar)) AS anchor_key,
    after_departure_airport AS departure_airport,
    source_txId AS source_system_id,
    ts_ms AS createdAt
FROM {{ source('vertica', 'postgres_public_flights') }}
