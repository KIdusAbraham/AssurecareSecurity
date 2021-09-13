declare @command1 varchar(500)
SET @command1 = 'USE [?]; '
SET @command1 = @command1 + 'IF DB_NAME(DB_ID(''?'')) NOT IN (''master'',''model'',''msdb'',''tempdb'')'
SET @command1 = @command1 + '
EXEC sp_changedbowner ''sa''
'
EXEC dbo.sp_MSforeachdb @command1

select loginname, name, sysadmin, securityadmin, serveradmin, setupadmin, processadmin, diskadmin, dbcreator, bulkadmin, createdate
from sys.syslogins
where hasaccess=1 and isntgroup=0
and sysadmin=1
order by loginname
/*

select * from sys.databases --sd
--where sd.owner_sid<>0x01 and sd.owner_sid<>0x0105000000000005150000007B017D79AA297E06B8655B51A7320000
--and sd.owner_sid<>0x88C1086D59CFE249BB485C8460128AC7
order by name




select sd.name as databasename, sd.owner_sid, sl.name as loginname from sys.databases sd  join sys.syslogins sl
on sd.owner_sid=sl.sid
--where sd.owner_sid<>0x01 and sd.owner_sid<>0x0105000000000005150000007B017D79AA297E06B8655B51A7320000
--and sd.owner_sid<>0x88C1086D59CFE249BB485C8460128AC7
order by databasename

*/

--use vWork_Test
--go
--exec sp_changedbowner 'sa'
SELECT
[Has DB Access] = 
	CASE is_disabled
		WHEN '0' THEN 'Y'
		else 'N'
	END,
[sys admin]=
	case IS_SRVROLEMEMBER('sysadmin', name)
		when 1 then 'Y'
		when 0 then 'N'
	end,
[updated]=
	case IS_SRVROLEMEMBER('sysadmin', name)
		when 1 then 'N'
		when 0 then '-'
	end,
name,
[group] = 
	CASE [type]
		When 'G' then 'Y'
		else 'N'
	END,
create_date as [Create Date]
FROM sys.server_principals 
where [type] not in ('R', 'C')
and name not like '##%##'
order by IS_SRVROLEMEMBER('sysadmin', name) desc, name

select d.name, 
[owner] = 
	CASE s.name
		When null then 'NO LONGER EXISTS'
		else s.name
	END
--select *
from sys.databases d
left join sys.syslogins s
on d.owner_sid=s.sid
order by s.name, d.name

--use CWCoreData
--go
--EXEC sp_changedbowner 'sa'
--go
