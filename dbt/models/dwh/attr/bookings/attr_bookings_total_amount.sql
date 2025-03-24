SELECT
    md5(cast(book_ref || after_total_amount as varchar)) AS attribute_key,
    md5(cast(book_ref as varchar)) AS anchor_key,
    after_total_amount AS total_amount,
    source_txId AS source_system_id,
    ts_ms AS createdAt
FROM {{ source('vertica', 'postgres_public_bookings') }}
