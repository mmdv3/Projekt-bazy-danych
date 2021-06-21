drop table if exists segment;

create table segment (
	segment_id int primary key generated always as identity,
	flight_id int,
	takeoff_location varchar(3) not null,
  	takeoff_time timestamp with time zone not null,
 	landing_location varchar(3) not null,
 	landing_time timestamp with time zone not null);

alter table segment add constraint takeoff_fk foreign key (takeoff_location) references airport (iatacode);
alter table segment add constraint landing_fk foreign key (landing_location) references airport (iatacode);
alter table segment add constraint time_relations CHECK (takeoff_time <= landing_time);

create sequence if not exists flight_id_sequence;

create or replace function flight (
  airport_1_id varchar(3), 
  airport_2_id varchar(3), 
  takeoff_1_time timestamp with time zone,
  landing_1_time timestamp with time zone,
  airport_3_id  varchar(3) default NULL,
  takeoff_2_time timestamp with time zone default NULL,
  landing_2_time timestamp with time zone default NULL)
returns varchar
as $$
declare 
  new_flight_id int;
begin
  select nextval('flight_id_sequence') into new_flight_id;
  insert into segment(flight_id, takeoff_location, takeoff_time, landing_location, landing_time) 
  values (new_flight_id, airport_1_id, takeoff_1_time, airport_2_id, landing_1_time);
  if (
	airport_3_id is not null and 
	takeoff_2_time is not null and
	landing_2_time is not null
	) then
   	insert into segment(flight_id, takeoff_location, takeoff_time, landing_location, landing_time) 
	values (new_flight_id, airport_2_id, takeoff_2_time, airport_3_id, landing_2_time);
  end if;
	
  return 'OK';
end;
$$
language plpgsql;

--select flight(
--  'HEA', 'KBL',
--  '2011-01-01 00:00:00+03'::timestamptz,
--  '2011-01-01 00:00:01+03'::timestamptz);
--select flight(
--  'KBL', 'TIA',
--  '2011-01-01 00:00:00+03'::timestamptz,
--  '2011-01-01 00:00:01+03'::timestamptz);
--select flight(
--  'TIA', 'TEE',
--  '2011-01-01 00:00:00+03'::timestamptz,
--  '2011-01-01 00:00:01+03'::timestamptz);
--select flight(
--  'TEE', 'HEA',
--  '2011-01-01 00:00:00+03'::timestamptz,
--  '2011-01-01 00:00:01+03'::timestamptz);
--select flight(
--  'HEA', 'TIA',
--  '2011-01-01 00:01:00+03'::timestamptz,
--  '2011-01-01 00:02:01+03'::timestamptz);
--select flight(
--  'KBL', 'TEE',
--  '2011-01-01 00:00:00+03'::timestamptz,
--  '2011-01-01 00:00:01+03'::timestamptz);
--select flight(
--  'BJA', 'TMR',
--  '2011-01-01 00:00:00+03'::timestamptz,
--  '2011-01-01 00:00:01+03'::timestamptz,
--  'CZL',
--  '2011-01-01 00:00:02+03'::timestamptz,
--  '2011-01-01 00:00:03+03'::timestamptz
--  );


create or replace function list_flights_segment (
  cmp_segment_id int)
returns table (
  segment_id int, flight_id int, takeoff_location varchar(3),
  takeoff_time timestamp with time zone , landing_location varchar(3),
  landing_time timestamp with time zone,
  distance int)
as $$
--declare 
--  new_flight_id int;
begin
 -- with cmp_segment_attr as (
 --   select * 
 --   from segment
 --   where segment.segment_id = cmp_segment_id)
 -- select * 
 -- from segment
 -- join airport a_t
 -- on segment.takeoff_location like a_t.iatacode
 -- join airport a_l
 -- on segment.landing_location like a_l.iatacode
	
--  create temp table segments_with_distance on commit drop as
  return query

  select segments_with_distance.segment_id, segments_with_distance.flight_id,
    segments_with_distance.takeoff_location, segments_with_distance.takeoff_time,
   	segments_with_distance.landing_location, segments_with_distance.landing_time,
	segments_with_distance.distance
   	from (
  with cmp_segment_attr as (
   	select segment.segment_id, segment.flight_id, segment.takeoff_location, a_t.latitude as t_latitude, a_t.longitude as t_longitude,
  		segment.landing_location , a_l.latitude as l_latitude, a_l.longitude as l_longitude
	from segment
   	join airport a_t
   	on segment.takeoff_location like a_t.iatacode
   	join airport a_l
   	on segment.landing_location like a_l.iatacode
	where segment.segment_id = cmp_segment_id)
select segment.segment_id, segment.flight_id, segment.takeoff_location, segment.takeoff_time,
	a_t.latitude as t_latitude, a_t.longitude as t_longitude,
		segment.landing_location, segment.landing_time,
	   	a_l.latitude as l_latitude, a_l.longitude as l_longitude,
	(ST_DISTANCE( ('LINESTRING(' || a_t.longitude ||' '|| a_t.latitude||', '||
		 a_l.longitude|| ' ' || a_l.latitude ||')')::geography,
	 	 ('LINESTRING(' || (select t_longitude from cmp_segment_attr)
		   	||' '|| (select t_latitude from cmp_segment_attr)||', '||
		   (select l_longitude from cmp_segment_attr)||' '|| (select l_latitude from cmp_segment_attr)|| ')')::geography))::int
   	as distance 
  from segment
  join airport a_t
  on segment.takeoff_location like a_t.iatacode
  join airport a_l
  on segment.landing_location like a_l.iatacode
	) segments_with_distance

;
end;
$$
language plpgsql;


create or replace function list_flight (cmp_flight_id int) 
returns table (
  segment_id int, flight_id int, takeoff_location varchar(3),
  takeoff_time timestamp with time zone , landing_location varchar(3),
  landing_time timestamp with time zone,
  distance int)
as $$
begin
  return query
  with ids as (
	select segment.segment_id from segment
	where segment.flight_id = cmp_flight_id)
  select l.*
  from ids,
  lateral list_flights_segment(ids.segment_id) l
  --where segments_with_distance.segment_id != cmp_segment_id
  where l.segment_id not in (select ids.segment_id from ids)
  and l.distance < 1 --comparing floats with zero is risky
  ;
end;
$$ language plpgsql;

create or replace function list_cities_segment(takeoff_longitude float, takeoff_latitude float, landing_longitude float, 
  landing_latitude float)
returns table (name varchar, prov varchar, country varchar, distance float) as $$
begin
  return query
  select city.name, city.province, city.country, 
  (st_distance( ('LINESTRING(' || takeoff_longitude || ' ' || takeoff_latitude || ', ' || landing_longitude || ' ' 
		  || landing_latitude || ')')::geography, ('POINT(' || city.longitude || ' ' || city.latitude || ')')::geography) )::float
  from city;
  --limit 10; --temporary , for test
end;
$$ language plpgsql;
--, distance float) as $$
-- , min(l.distance)
create or replace function list_cities(arg_flight_id int, dist numeric)
returns table (name varchar, prov varchar, country varchar) as $$ 
begin
  return query
  with flight_segment as (
	select a1.longitude as takeoff_longitude, a1.latitude as takeoff_latitude, 
	a2.longitude as landing_longitude, a2.latitude as landing_latitude	
	from segment
	join airport a1
	on segment.takeoff_location like a1.iatacode
	join airport a2
	on segment.landing_location like a2.iatacode
	where segment.flight_id = arg_flight_id)
  select l.name, l.prov, l.country
  from flight_segment,
  lateral list_city_segment(
	flight_segment.takeoff_longitude,
	flight_segment.takeoff_latitude,
	flight_segment.landing_longitude,
	flight_segment.landing_latitude) l
  group by l.name, l.prov, l.country
  having min(l.distance) < dist * 1000
  order by l.name asc;
end;
$$ language plpgsql;

create or replace function list_airport (airport_iatacode varchar(3), -- add limits (n)
  n int) returns table (flight_id int) as $$
begin
  return query
  select segment.flight_id
  from segment
  where segment.takeoff_location like airport_iatacode 
  order by segment.takeoff_time DESC, segment.flight_id
  limit n;
end;
$$ language plpgsql;

-- określ długość w typie name, itd.
-- takeoff time w returnie dla debuga
-- w flight_parameters trzeba dostosować kolejność : asc/desc do tego czego będzie chciał ćwiczeniowiec
create or replace function list_city (a_name varchar, a_prov varchar, 
  a_country varchar, n int, dist int) returns table (rid int, mdist float)
   as $$
begin
  return query
with city_location as (
  select city.longitude as longitude, city.latitude as latitude
  from city
  where city.name like a_name
  and city.country like a_country
  and city.province like a_prov
),
segment_with_location as (
  select segment.*, at.longitude as t_longitude, at.latitude as t_latitude,
  al.longitude as l_longitude, al.latitude as l_latitude,
  st_distance( ('LINESTRING(' || at.longitude || ' ' ||
	  at.latitude || ',' || al.longitude || ' ' || al.latitude ||
	  ')')::geography, ('POINT(' || (select city_location.longitude from
	   	city_location) || ' ' || (select city_location.latitude from
	   	city_location) || ')')::geography)/1000 as distance
  from segment
  join airport at
  on segment.takeoff_location like at.iatacode
  join airport al
  on segment.landing_location like al.iatacode ),
flight_parameters as (
select swl.flight_id, (array_agg(swl.takeoff_time order by swl.distance asc, swl.takeoff_time asc))[1] as takeoff_time, min(swl.distance) as distance
from segment_with_location swl
group by swl.flight_id)
select flight_parameters.flight_id as rid, flight_parameters.distance as mdist
from flight_parameters
where flight_parameters.distance < dist
order by flight_parameters.takeoff_time desc
limit n;

end;
$$ language plpgsql;
