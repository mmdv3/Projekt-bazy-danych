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
--  '2011-01-01 00:00:00+03'::timestamptz,
--  '2011-01-01 00:00:01+03'::timestamptz);
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
  landing_time timestamp with time zone)
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
	
  create temp table segments_with_distance on commit drop as
  (with recursive cmp_segment_attr as (
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
		   (select l_longitude from cmp_segment_attr)||' '|| (select l_latitude from cmp_segment_attr)|| ')')::geography))::float
   	as does_intersect 
  from segment
  join airport a_t
  on segment.takeoff_location like a_t.iatacode
  join airport a_l
  on segment.landing_location like a_l.iatacode);

  return query
  select segments_with_distance.segment_id, segments_with_distance.flight_id,
    segments_with_distance.takeoff_location, segments_with_distance.takeoff_time,
   	segments_with_distance.landing_location, segments_with_distance.landing_time from segments_with_distance
  where segments_with_distance.segment_id != cmp_segment_id
  and does_intersect < 1 --comparing floats with zero is risky
;
end;
$$
language plpgsql;


create or replace function list_flight (cmp_flight_id int) 
returns table (
  segment_id int, flight_id int, takeoff_location varchar(3),
  takeoff_time timestamp with time zone , landing_location varchar(3),
  landing_time timestamp with time zone)
as $$
begin
  with ids as (
	select segment.segment_id from segment
	where segment.flight_id = cmp_flight_id)
  select l.*
  from ids,
  lateral list_flights_segment(ids.segment_id) l;
end;
$$ language plpgsql;












----------------------
--  with cmp_segment_attr as (
--   	select segment.segment_id, segment.flight_id, segment.takeoff_location, a_t.latitude as t_latitude, a_t.longitude as t_longitude,
--  		segment.landing_location , a_l.latitude as l_latitude, a_l.longitude as l_longitude
--	from segment
--   	join airport a_t
--   	on segment.takeoff_location like a_t.iatacode
--   	join airport a_l
--   	on segment.landing_location like a_l.iatacode
--	where segment.segment_id = 1),
--  segments_with_distance as (
--select segment.segment_id, segment.flight_id, segment.takeoff_location, a_t.latitude, a_t.longitude,
--		segment.landing_location, a_l.latitude, a_l.longitude,
--	(ST_DISTANCE( ('LINESTRING(' || a_t.longitude ||' '|| a_t.latitude||', '||
--		 a_l.longitude|| ' ' || a_l.latitude ||')')::geography,
--	 	 ('LINESTRING(' || (select t_longitude from cmp_segment_attr)
--		   	||' '|| (select t_latitude from cmp_segment_attr)||', '||
--		   (select l_longitude from cmp_segment_attr)||' '|| (select l_latitude from cmp_segment_attr)|| ')')::geography))::integer
--   	as does_intersect 
--  from segment
--  join airport a_t
--  on segment.takeoff_location like a_t.iatacode
--  join airport a_l
--  on segment.landing_location like a_l.iatacode)
--
--  select segments_with_distance.segment_id, segments_with_distance.flight_id,
--    segments_with_distance.takeoff_location,
--   	segments_with_distance.landing_location,
--	segments_with_distance.does_intersect
--	from segments_with_distance
--  --where segments_with_distance.segment_id != 1
--  --and segments_with_distance.does_intersect > 3
--  limit 1
--  --limit 2
--;



















--  limit 1);
 -- and segments_with_distance.does_intersect = true;
 -- limit 1;
  --and segments_with_distance.distance > 3;

  --where SELECT ST_Distance('LINESTRING(16.89 51.1, 18.47 54.38)'::geography, 
--	'LINESTRING(19.1 50.5, 19.8 50.08)'::geography)/1000 as distance; 

---	ST_DISTANCE( ('LINESTRING(' || a_t.latitude ||' '|| a_t.longitude||', '||
---		 a_l.latitude|| ' ' || a_l.longitude ||')')::geography,
---	   	'LINESTRING(34.210017 62.2283, 34.565853 69.212328)'::geography)
