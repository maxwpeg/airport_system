SELECT
    md5(cast(book_ref as varchar)) AS anchor_key,
    book_ref AS business_key,
    source_txId AS source_system_id,
    ts_ms AS createdAt
FROM {{ source('vertica', 'postgres_public_bookings') }}
