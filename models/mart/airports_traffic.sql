WITH flights AS (
    SELECT
        af.business_key AS flight_id,
        afaa2.actual_arrival AS flight_date,
        afaa.arrival_airport AS arrival_airport,
        afda.departure_airport AS departure_airport,
        COUNT(atpi.passenger_id) AS passengers
    FROM {{ source('vertica-dwh', 'attr_flights_arrival_airport') }} afaa
    JOIN {{ source('vertica-dwh', 'anchor_flights') }} af ON afaa.anchor_key = af.anchor_key
    JOIN {{ source('vertica-dwh', 'attr_flights_departure_airport') }} afda ON af.anchor_key = afda.anchor_key
    JOIN {{ source('vertica-dwh', 'attr_flights_actual_arrival') }} afaa2 ON af.anchor_key = afaa2.anchor_key
    LEFT JOIN {{ source('vertica-dwh', 'tie_flights_ticket_flights') }} tftf ON af.anchor_key = tftf.flight
    LEFT JOIN {{ source('vertica-dwh', 'anchor_ticket_flights') }} atf ON tftf.ticket_flight = atf.anchor_key
    LEFT JOIN {{ source('vertica-dwh', 'tie_tickets_ticket_flights') }} ttf ON atf.anchor_key = ttf.ticket_flight
    LEFT JOIN {{ source('vertica-dwh', 'anchor_tickets') }} at ON ttf.ticket = at.anchor_key
    LEFT JOIN {{ source('vertica-dwh', 'attr_tickets_passenger_id') }} atpi ON at.anchor_key = atpi.anchor_key
    WHERE afaa2.actual_arrival::DATE = CURRENT_DATE - INTERVAL '1 day'
    GROUP BY af.business_key, afaa.arrival_airport, afda.departure_airport, afaa2.actual_arrival
    order by passengers desc, arrival_airport, departure_airport
),

flights_agg AS (
    SELECT
        flight_date,
        LEAST(departure_airport, arrival_airport) AS airport_code,
        GREATEST(departure_airport, arrival_airport) AS linked_airport_code,
        COUNT(*) AS flights_count,
        SUM(passengers) AS passengers_count,
        SUM(CASE WHEN departure_airport < arrival_airport THEN 1 ELSE 0 END) AS flights_out,
        SUM(CASE WHEN departure_airport > arrival_airport THEN 1 ELSE 0 END) AS flights_in,
        SUM(CASE WHEN departure_airport < arrival_airport THEN passengers ELSE 0 END) AS passengers_out,
        SUM(CASE WHEN departure_airport > arrival_airport THEN passengers ELSE 0 END) AS passengers_in
    FROM flights
    GROUP BY flight_date, LEAST(departure_airport, arrival_airport), GREATEST(departure_airport, arrival_airport)
)

SELECT
    NOW() AS created_at,
    flight_date,
    airport_code,
    linked_airport_code,
    COALESCE(SUM(flights_in), 0) AS flights_in,
    COALESCE(SUM(flights_out), 0) AS flights_out,
    COALESCE(SUM(passengers_in), 0) AS passengers_in,
    COALESCE(SUM(passengers_out), 0) AS passengers_out
FROM flights_agg
GROUP BY flight_date, airport_code, linked_airport_code