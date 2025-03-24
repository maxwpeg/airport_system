SELECT
    md5(cast(airport_code || after_city as varchar)) AS attribute_key,
    md5(cast(airport_code as varchar)) AS anchor_key,
    after_city AS city,
    source_txId AS source_system_id,
    ts_ms AS createdAt
FROM {{ source('vertica', 'postgres_public_airports') }}
