create table #users (
uname varchar(500),
id varchar(500)
)

insert into #users
EXEC sp_change_users_login 'Report'

DECLARE @command1 NVARCHAR(4000)
declare @var nvarchar(255)

declare dbs cursor for
select uname from #users

open dbs
fetch next from dbs into @var
while @@fetch_status=0
begin

set @command1 = 'EXEC sp_change_users_login ''Auto_Fix'', '''+@var+'''
GO
'
print @command1

fetch next from dbs into @var
end
close dbs
deallocate dbs

drop table #users