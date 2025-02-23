{{ config(materialized='table') }}

SELECT
    md5(cast(ticket_no || after_book_ref as varchar)) AS tie_key,
    md5(cast(ticket_no as varchar)) AS ticket,
    md5(cast(after_book_ref as varchar)) AS booking,
    source_txId AS source_system_id,
    ts_ms AS createdAt
FROM {{ source('vertica', 'postgres_public_tickets') }}
