select *
from sys.server_principals
order by modify_date desc


IF (SELECT convert(int,value_in_use) FROM sys.configurations WHERE name = 'default trace enabled')  = 1
BEGIN
	SELECT  *
	--(dense_rank() over (order by StartTime desc))%2 as l1,
	--convert(int, EventClass) as EventClass,
	--DatabaseName,
	--Filename,
	--(Duration/1000) as Duration,
	--StartTime,
	--EndTime,
	--(IntegerData*8.0/1024) as ChangeInSize 
	FROM ::fn_trace_gettable( (
		select left( path,len(path) - (patindex('%\%', reverse(path)))) + '\log.trc' 
		from sys.traces 
		where is_default = 1
	), default ) 
	WHERE EventClass = 108
	order by StartTime desc 
END
ELSE
BEGIN
	select 'Default trace is disabled'
END
