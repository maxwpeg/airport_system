SELECT
    md5(cast(ticket_no as varchar)) AS anchor_key,
    ticket_no AS business_key,
    source_txId AS source_system_id,
    ts_ms AS createdAt
FROM {{ source('vertica', 'postgres_public_tickets') }}
