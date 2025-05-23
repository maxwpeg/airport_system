SELECT
    md5(cast(airport_code || after_timezone as varchar)) AS attribute_key,
    md5(cast(airport_code as varchar)) AS anchor_key,
    after_timezone AS timezone,
    source_txId AS source_system_id,
    ts_ms AS createdAt
FROM {{ source('vertica', 'postgres_public_airports') }}
