--------------- coś
  with cmp_segment_attr as (
	    select segment.segment_id, segment.flight_id, segment.takeoff_location,
		    a_t.latitude as t_latitude, a_t.longitude as t_longitude,
			        segment.landing_location , a_l.latitude as l_latitude, a_l.longitude as l_longitude
					    from segment
						    join airport a_t
							    on segment.takeoff_location like a_t.iatacode
								    join airport a_l
									    on segment.landing_location like a_l.iatacode
										    where segment.segment_id = 1),
										    segments_with_distance as (
											  select segment.segment_id, segment.flight_id, segment.takeoff_location, a_t.latitude, a_t.longitude,
											          segment.landing_location, a_l.latitude, a_l.longitude,
													      (ST_DISTANCE( ('LINESTRING(' || a_t.longitude ||' '|| a_t.latitude||', '||
																           a_l.longitude|| ' ' || a_l.latitude ||')')::geography,
																	           ('LINESTRING(' || (select t_longitude from cmp_segment_attr)
																				              ||' '|| (select t_latitude from cmp_segment_attr)||', '||
																							             (select l_longitude from cmp_segment_attr)||' '||                                                        (select l_latitude from cmp_segment_attr)|| ')')::geography))::integer
																								    as does_intersect
																									  from segment
																									    join airport a_t
																										  on segment.takeoff_location like a_t.iatacode
																										    join airport a_l
																											  on segment.landing_location like a_l.iatacode)

																											  select segments_with_distance.segment_id, segments_with_distance.flight_id,
																											      segments_with_distance.takeoff_location,
																												      segments_with_distance.landing_location,
																													      segments_with_distance.does_intersect
																														      from segments_with_distance
																															    --where segments_with_distance.does_intersect > 3
;

--------------- coś
--SELECT ST_Distance('LINESTRING(-122.33 47.606, 0.0 51.5)'::geography,                                    -- 'POINT(-21.96 64.15)'::geography)/1000 as distance;


--------------- coś
--with city_location as (
--    select city.longitude as longitude, city.latitude as latitude
--	  from city
--	    where city.name like 'Tirana'
--		  and city.country like 'AL'
--		    and city.province like 'Albania'
--		  ),
--		  segment_with_location as (
--			  select segment.*, at.longitude as t_longitude, at.latitude as t_latitude,
--			    al.longitude as l_longitude, al.latitude as l_latitude
--				  from segment
--				    join airport at
--					  on segment.takeoff_location like at.iatacode
--					    join airport al
--						  on segment.landing_location like al.iatacode )
--						select swl.*, st_distance( ('LINESTRING(' || swl.t_longitude || ' ' ||
--							        swl.t_latitude || ',' || swl.l_longitude || ' ' || swl.l_latitude ||
--									      ')')::geography, ('POINT(' || (select city_location.longitude from
--											        city_location) || ' ' || (select city_location.latitude from
--													        city_location) || ')')::geography)/1000 as distance
--													from segment_with_location swl
--
--with city_location as (
--    select city.longitude as longitude, city.latitude as latitude
--	  from city
--	    where city.name like 'Tirana'
--		  and city.country like 'AL'
--		    and city.province like 'Albania'
--		  ),
--		  segment_with_location as (
--			  select segment.*, at.longitude as t_longitude, at.latitude as t_latitude,
--			    al.longitude as l_longitude, al.latitude as l_latitude,
--				  st_distance( ('LINESTRING(' || at.longitude || ' ' ||
--						      at.latitude || ',' || al.longitude || ' ' || al.latitude ||
--							        ')')::geography, ('POINT(' || (select city_location.longitude from
--									          city_location) || ' ' || (select city_location.latitude from
--											          city_location) || ')')::geography)/1000 as distance
--											    from segment
--												  join airport at
--												    on segment.takeoff_location like at.iatacode
--													  join airport al
--													    on segment.landing_location like al.iatacode ),
--													  flight_parameters as (
--														select swl.flight_id, (array_agg(swl.takeoff_time order by swl.distance asc, swl.takeoff_time asc))[1] as takeoff_time, min(swl.distance) as distance
--														from segment_with_location swl
--														group by swl.flight_id)
--													  select flight_parameters.flight_id as rid, flight_parameters.distance as mdist
--													  from flight_parameters
--													  where flight_parameters.distance < 2000
--													  order by flight_parameters.takeoff_time desc
--													  limit 10
--
--------------- coś
--select segment.*, ST_Distance('LINESTRING(' || -122.33 47.606, 0.0 51.5)'::geography, 'POINT(-21.96 64.15)'::geography)/1000 as distance;
--      distance
--from segment
--;

-- minimalna odległość (w km) samolotu lecącego z Seattle do Londynu (LINESTRING(-122.33 47.606, 0.0 51.5)),
-- a Reykjavikiem (POINT(-21.96 64.15)) - zakładamy lot po najkrótszej możliwej trasie
--------------- coś
--  limit 1);
 -- and segments_with_distance.does_intersect = true;
 -- limit 1;
  --and segments_with_distance.distance > 3;

  --where SELECT ST_Distance('LINESTRING(16.89 51.1, 18.47 54.38)'::geography,
--  'LINESTRING(19.1 50.5, 19.8 50.08)'::geography)/1000 as distance;

--- ST_DISTANCE( ('LINESTRING(' || a_t.latitude ||' '|| a_t.longitude||', '||
---      a_l.latitude|| ' ' || a_l.longitude ||')')::geography,
---     'LINESTRING(34.210017 62.2283, 34.565853 69.212328)'::geography)


-- select * from list_city ('Tirana', 'Albania', 'AL', 6, 20000);

