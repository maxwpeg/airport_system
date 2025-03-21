{{ config(
    materialized='incremental',
    unique_key='passenger_id',
    on_schema_change='sync',
    incremental_strategy='delete+insert'
) }}

WITH passenger_flights AS (
    SELECT
        atpi.passenger_id,
        atpn.passenger_name,
        COUNT(affn.flight_no) AS flights_number,
        SUM(atfa.amount) AS purchase_sum
    FROM {{ source('vertica-dwh', 'attr_tickets_passenger_name') }} atpn
    JOIN {{ source('vertica-dwh', 'attr_tickets_passenger_id') }} atpi 
        ON atpn.anchor_key = atpi.anchor_key
    JOIN {{ source('vertica-dwh', 'anchor_tickets') }} at 
        ON atpi.anchor_key = at.anchor_key
    JOIN {{ source('vertica-dwh', 'tie_tickets_ticket_flights') }} tttf 
        ON at.anchor_key = tttf.ticket
    JOIN {{ source('vertica-dwh', 'anchor_ticket_flights') }} atf 
        ON tttf.ticket_flight = atf.anchor_key
    JOIN {{ source('vertica-dwh', 'attr_ticket_flights_amount') }} atfa 
        ON atf.anchor_key = atfa.anchor_key
    JOIN {{ source('vertica-dwh', 'tie_flights_ticket_flights') }} tftf 
        ON atfa.anchor_key = tftf.ticket_flight
    JOIN {{ source('vertica-dwh', 'anchor_flights') }} af 
        ON tftf.flight = af.anchor_key
    JOIN {{ source('vertica-dwh', 'attr_flights_flight_no') }} affn 
        ON af.anchor_key = affn.anchor_key
    GROUP BY atpi.passenger_id, atpn.passenger_name
),

passenger_airports AS (
    SELECT
        atpi.passenger_id,
        afaa.arrival_airport AS arrival_airport,
        afda.departure_airport AS departure_airport
    FROM {{ source('vertica-dwh', 'attr_tickets_passenger_id') }} atpi
    JOIN {{ source('vertica-dwh', 'anchor_tickets') }} at 
        ON atpi.anchor_key = at.anchor_key
    JOIN {{ source('vertica-dwh', 'tie_tickets_ticket_flights') }} tttf 
        ON at.anchor_key = tttf.ticket
    JOIN {{ source('vertica-dwh', 'anchor_ticket_flights') }} atf 
        ON tttf.ticket_flight = atf.anchor_key
    JOIN {{ source('vertica-dwh', 'tie_flights_ticket_flights') }} tftf 
        ON atf.anchor_key = tftf.ticket_flight
    JOIN {{ source('vertica-dwh', 'anchor_flights') }} af 
        ON tftf.flight = af.anchor_key
    JOIN {{ source('vertica-dwh', 'attr_flights_arrival_airport') }} afaa 
        ON af.anchor_key = afaa.anchor_key
    JOIN {{ source('vertica-dwh', 'attr_flights_departure_airport') }} afda 
        ON af.anchor_key = afda.anchor_key
),

airport_counts AS (
    SELECT
        passenger_id,
        airport,
        COUNT(airport) AS visit_count
    FROM (
        SELECT passenger_id, arrival_airport AS airport FROM passenger_airports
        UNION ALL
        SELECT passenger_id, departure_airport AS airport FROM passenger_airports
    ) AS flights_combined
    GROUP BY passenger_id, airport
),

ranked AS (
    SELECT
        passenger_id,
        airport,
        visit_count,
        ROW_NUMBER() OVER (PARTITION BY passenger_id ORDER BY visit_count DESC, airport ASC) AS rnk
    FROM airport_counts
),

home_airports AS (
    SELECT passenger_id, airport AS home_airport
    FROM ranked
    WHERE rnk = 1
),

customer_groups AS (
    SELECT
        passenger_id,
        purchase_sum,
        PERCENT_RANK() OVER (ORDER BY purchase_sum DESC) AS percentile
    FROM passenger_flights
)

SELECT
    NOW() AS created_at,
    pf.passenger_id,
    pf.passenger_name,
    pf.flights_number,
    pf.purchase_sum,
    ha.home_airport,
    CASE
        WHEN cg.percentile <= 0.05 THEN '5'
        WHEN cg.percentile <= 0.10 THEN '10'
        WHEN cg.percentile <= 0.25 THEN '25'
        WHEN cg.percentile <= 0.50 THEN '50'
        ELSE '50+'
    END AS customer_group
FROM passenger_flights pf
LEFT JOIN home_airports ha 
    ON pf.passenger_id = ha.passenger_id
LEFT JOIN customer_groups cg 
    ON pf.passenger_id = cg.passenger_id
ORDER BY pf.purchase_sum DESC
