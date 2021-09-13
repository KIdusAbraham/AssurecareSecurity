create table #users (
uname varchar(500),
id varbinary(85),
dbname varchar(500),
query varchar(4000)
)

declare @sql varchar(4000)
DECLARE @command1 NVARCHAR(4000)
declare @var nvarchar(255)

set @sql = '
if ''?'' <> ''tempdb''
begin
print ''?''
use [?];
insert into #users (uname, id)
EXEC sp_change_users_login ''Report'';
update #users
set dbname = ''?'',
query = ''use [?]; EXEC sp_change_users_login ''''Auto_Fix'''', ''''''+uname+'''''';''
where dbname is null;
end
'

exec Sp_MSForEachDB @sql

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
