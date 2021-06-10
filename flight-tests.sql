begin;
  select flight(
	'HEA', 'KBL', 
	'2013-11-03 00:00:00-07'::timestamptz,
	'2013-11-03 01:00:00-07'::timestamptz);
  select flight(
	'HEA', 'KBL', 
	'2013-11-03 00:30:00-07'::timestamptz,
	'2013-11-03 01:30:00-07'::timestamptz,
	'TEE',
	'2013-11-03 02:30:00-07'::timestamptz,
	'2013-11-03 03:30:00-07'::timestamptz
  );
  select * from segment;
rollback;
