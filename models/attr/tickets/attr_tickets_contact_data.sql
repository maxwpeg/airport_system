{{ config(materialized='incremental', unique_key='attribute_key') }}

SELECT
    md5(cast(ticket_no || after_contact_data as varchar)) AS attribute_key,
    md5(cast(ticket_no as varchar)) AS anchor_key,
    after_contact_data AS contact_data,
    source_txId AS source_system_id,
    ts_ms AS createdAt
FROM {{ source('vertica', 'postgres_public_tickets') }}
