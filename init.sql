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
language plpgsql
