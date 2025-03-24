delete from {{ source('vertica-presentation', 'airports_traffic') }}
       where flight_date::DATE = '{{ var("business_date") }}'