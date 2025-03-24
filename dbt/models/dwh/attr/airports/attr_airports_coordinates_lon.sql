SELECT
    md5(cast(airport_code || after_coordinates_lon as varchar)) AS attribute_key,
    md5(cast(airport_code as varchar)) AS anchor_key,
    after_coordinates_lon AS coordinates_lon,
    source_txId AS source_system_id,
    ts_ms AS createdAt
FROM {{ source('vertica', 'postgres_public_airports') }}
