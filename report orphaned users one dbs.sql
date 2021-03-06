create table #users (
uname varchar(500),
id varbinary(85),
dbname varchar(500),
query varchar(4000)
)

DECLARE @command1 NVARCHAR(4000)
declare @var nvarchar(255)

insert into #users (uname, id)
EXEC sp_change_users_login 'Report';
update #users
set dbname = DB_NAME(),
query = 'use ['+DB_NAME()+']; EXEC sp_change_users_login ''Auto_Fix'', '''+uname+''';'
where dbname is null


select
case uname
when 'dbo' then
'use ['+dbname+']; EXEC sp_changedbowner '''+suser_sname(owner_sid)+''';'
else
query
end as query, *
from #users u join sys.databases d
on u.dbname=d.name

drop table #users
