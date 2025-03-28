create table airports (
    airport_code char(3) primary key,
    airport_name text,
    city text,
    coordinates_lon double precision,
    coordinates_lat double precision,
    timezone text
);

create table aircraft (
    aircraft_code char(3) primary key,
    model jsonb,
    range integer
);

create table seats (
    aircraft_code char(3) references aircraft(aircraft_code),
    seat_no varchar(4),
    fare_conditions varchar(10),
    primary key (aircraft_code, seat_no)
);

create table flights (
    flight_id serial primary key,
    flight_no char(6),
    scheduled_departure timestamptz,
    scheduled_arrival timestamptz,
    departure_airport char(3) references airports(airport_code),
    arrival_airport char(3) references airports(airport_code),
    status varchar(20),
    aircraft_code char(3) references aircraft(aircraft_code),
    actual_departure timestamptz,
    actual_arrival timestamptz
);

create table bookings (
    book_ref char(6) primary key,
    book_date timestamptz,
    total_amount numeric(10,2)
);

create table tickets (
    ticket_no char(13) primary key ,
    book_ref char(6) references bookings(book_ref),
    passenger_id varchar(20),
    passenger_name text,
    contact_data jsonb
);

create table ticket_flights (
    ticket_no char(13) references tickets(ticket_no),
    flight_id integer references flights(flight_id),
    fare_conditions numeric(10,2),
    amount numeric(10, 2),
    primary key (flight_id, ticket_no)
);

create table boarding_passes (
    ticket_no char(13) references tickets(ticket_no),
    flight_id integer references flights(flight_id),
    boarding_no integer,
    seat_no varchar(4),
    primary key (flight_id, ticket_no)
);

INSERT INTO airports (airport_code, airport_name, city, coordinates_lon, coordinates_lat, timezone)
VALUES
('JFK', 'John F. Kennedy International Airport', 'New York', -73.7781, 40.6413, 'America/New_York'),
('LAX', 'Los Angeles International Airport', 'Los Angeles', -118.4085, 33.9416, 'America/Los_Angeles'),
('ORD', 'OHare International Airport', 'Chicago', -87.9048, 41.9742, 'America/Chicago'),
('ATL', 'Hartsfield-Jackson Atlanta International Airport', 'Atlanta', -84.4277, 33.6407, 'America/New_York'),
('DFW', 'Dallas/Fort Worth International Airport', 'Dallas', -97.0403, 32.8998, 'America/Chicago');

INSERT INTO aircraft (aircraft_code, model, range)
VALUES
('A32', '{"manufacturer": "Airbus", "model": "A320"}', 6100),
('B73', '{"manufacturer": "Boeing", "model": "737"}', 5600),
('E19', '{"manufacturer": "Embraer", "model": "E190"}', 4000);

INSERT INTO seats (aircraft_code, seat_no, fare_conditions)
VALUES
('A32', '1A', 'Economy'), ('A32', '1B', 'Economy'), ('A32', '2A', 'Business'), ('A32', '2B', 'Business'),
('B73', '1A', 'Economy'), ('B73', '1B', 'Economy'), ('B73', '2A', 'Business'), ('B73', '2B', 'Business'),
('E19', '1A', 'Economy'), ('E19', '1B', 'Economy'), ('E19', '2A', 'Business'), ('E19', '2B', 'Business');

INSERT INTO flights (flight_no, scheduled_departure, scheduled_arrival, departure_airport, arrival_airport, status, aircraft_code, actual_departure, actual_arrival)
VALUES
('AA101', '2025-03-25 08:00:00+00', '2025-01-14 11:00:00+00', 'JFK', 'LAX', 'Scheduled', 'A32',  NOW() - INTERVAL '2 days',  NOW() - INTERVAL '2 days'),
('DL202', '2025-03-25 09:00:00+00', '2025-01-14 13:00:00+00', 'ATL', 'ORD', 'Scheduled', 'B73',  NOW() - INTERVAL '2 days', '2025-01-14 11:00:00+00'),
('UA303', '2025-03-25 07:30:00+00', '2025-01-14 09:45:00+00', 'DFW', 'JFK', 'Scheduled', 'E19', '2025-02-25 08:00:00+00',  NOW() - INTERVAL '2 days');

INSERT INTO bookings (book_ref, book_date, total_amount)
VALUES
('BR001', '2025-01-10 10:00:00+00', 350.00),
('BR002', '2025-01-11 11:00:00+00', 450.00),
('BR003', '2025-01-12 12:00:00+00', 500.00);

INSERT INTO tickets (ticket_no, book_ref, passenger_id, passenger_name, contact_data)
VALUES
('TK000000001', 'BR001', 'P001', 'John Doe', '{"phone": "+1234567890", "email": "john.doe@example.com"}'),
('TK000000002', 'BR002', 'P002', 'Jane Smith', '{"phone": "+1987654321", "email": "jane.smith@example.com"}'),
('TK000000003', 'BR003', 'P003', 'Alice Brown', '{"phone": "+1122334455", "email": "alice.brown@example.com"}');

INSERT INTO ticket_flights (ticket_no, flight_id, fare_conditions, amount)
VALUES
('TK000000001', 1, 2, 200.00),
('TK000000002', 2, 3, 300.00),
('TK000000003', 3, 1, 250.00);

INSERT INTO boarding_passes (ticket_no, flight_id, boarding_no, seat_no)
VALUES
('TK000000001', 1, 1, '1A'),
('TK000000002', 2, 2, '2A'),
('TK000000003', 3, 3, '1B');


create materialized view airport_passenger_traffic as
select
    a.airport_code,
    coalesce(df.departure_flights_num, 0) as departure_flights_num,
    coalesce(df.departure_psngr_num, 0) as departure_psngr_num,
    coalesce(af.arrival_flights_num, 0) as arrival_flights_num,
    coalesce(af.arrival_psngr_num, 0) as arrival_psngr_num
from
    airports a
left join (
    select
        f.departure_airport as airport_code,
        count(distinct f.flight_id) as departure_flights_num,
        count(tf.ticket_no) as departure_psngr_num
    from
        flights f
    left join ticket_flights tf on f.flight_id = tf.flight_id
    group by f.departure_airport
) df on a.airport_code = df.airport_code
left join (
    select
        f.arrival_airport as airport_code,
        count(distinct f.flight_id) as arrival_flights_num,
        count(tf.ticket_no) as arrival_psngr_num
    from
        flights f
    left join ticket_flights tf on f.flight_id = tf.flight_id
    group by f.arrival_airport
) af on a.airport_code = af.airport_code
order by a.airport_code;
