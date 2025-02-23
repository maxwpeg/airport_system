{{ config(materialized='incremental', unique_key='attribute_key') }}

SELECT
    md5(cast(ticket_no || after_passenger_name as varchar)) AS attribute_key,
    md5(cast(ticket_no as varchar)) AS anchor_key,
    after_passenger_name AS passenger_name,
    source_txId AS source_system_id,
    ts_ms AS createdAt
FROM {{ source('vertica', 'postgres_public_tickets') }}
