SELECT
    md5(cast(ticket_no || flight_id || ticket_no as varchar)) AS tie_key,
    md5(cast(ticket_no as varchar)) AS ticket,
    md5(cast(flight_id || ticket_no as varchar)) AS ticket_flight,
    source_txId AS source_system_id,
    ts_ms AS createdAt
FROM {{ source('vertica', 'postgres_public_ticket_flights') }}
