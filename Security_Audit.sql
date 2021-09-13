declare @databases sysname
set @databases = 'ALL'

SET nocount ON 

declare @sql nvarchar(4000)
DECLARE @Next SYSNAME 

create table #permission
(
	Database_Name SYSNAME,
	User_Role_Name SYSNAME,
	Is_DatabaseRole bit,
	Is_Login bit,
	Is_WindowsUser bit,
	Is_WindowsGroup bit,
	Is_SQLUser bit,	
	HasAccess varchar(5),
	Action_Type NVARCHAR(128),
	Permission NVARCHAR(60),
	SchemaName SYSNAME NULL,
	ObjectName SYSNAME NULL,
	Object_Type NVARCHAR(60)
) 

create table #objects
(
	obj_id int, 
	obj_type char(2),
	database_name sysname,
	owner_id int
)  

-- object cursor
DECLARE dbs CURSOR FOR
SELECT  name
FROM    master.dbo.sysdatabases
WHERE DATABASEPROPERTYEX(name,'status')='ONLINE'
ORDER BY name         

OPEN dbs

FETCH NEXT
FROM dbs
INTO @Next

WHILE @@FETCH_STATUS = 0
BEGIN

set @sql = 
	'use ['+@Next+'];
	insert into #objects 
	select id, type, '''+@Next+''', uid from ['+@Next+'].dbo.sysobjects'

execute sp_executesql @sql

FETCH NEXT
FROM dbs
INTO @Next
      
END

CLOSE dbs
DEALLOCATE dbs
-- object cursor

-- permission cursor
if @databases = 'ALL'
begin
	DECLARE dbs CURSOR FOR
	SELECT  name
	FROM    master.dbo.sysdatabases
	WHERE DATABASEPROPERTYEX(name,'status')='ONLINE'--state_desc = 'ONLINE'
	ORDER BY name        
end
else
begin
	DECLARE dbs CURSOR FOR
	SELECT  name
	FROM    master.dbo.sysdatabases
	WHERE DATABASEPROPERTYEX(name,'status')='ONLINE'--state_desc = 'ONLINE'
	AND name = @databases
end      

OPEN dbs

FETCH NEXT
FROM dbs
INTO @Next

WHILE @@FETCH_STATUS = 0
BEGIN

set @sql = 
	'use ['+@Next+'];
	INSERT  INTO #permission
	SELECT ''' + @Next + ''' as database_name, a.name as ''User or Role Name'',
	a.issqlrole,
	a.islogin,
	a.isntuser,
	a.isntgroup,
	a.issqluser,
	case a.hasdbaccess
	when 1 then ''YES''
	when 0 then
		case a.issqlrole
		when 0 then ''NO''
		when 1 then ''N/A''
		end
	end as ''HasAccess'',
	case d.action
	when 26 then ''REFERENCES''
	when 178 then ''CREATE FUNCTION''
	when 193 then ''SELECT''
	when 195 then ''INSERT''
	when 196 then ''DELETE''
	when 197 then ''UPDATE''
	when 198 then ''CREATE TABLE''
	when 203 then ''CREATE DATABASE''
	when 207 then ''CREATE VIEW''
	when 222 then ''CREATE PROCEDURE''
	when 224 then ''EXECUTE''
	when 228 then ''BACKUP DATABASE''
	when 233 then ''CREATE DEFAULT''
	when 235 then ''BACKUP LOG''
	when 236 then ''CREATE RULE''
	else USER_NAME(groupuid)
	end as ''Type of Permission'',
	case d.protecttype
	when 204 then ''GRANT_W_GRANT''
	when 205 then ''GRANT''
	when 206 then ''DENY''
	end as ''State of Permission'',
	u.name as ''Schema Name'', object_name(d.id) as ''Object Name'', 
	case e.obj_type 
	when ''AF'' then ''Aggregate function (CLR)'' 
	when ''C'' then ''CHECK constraint'' 
	when ''D'' then ''DEFAULT (constraint or stand-alone)'' 
	when ''F'' then ''FOREIGN KEY constraint'' 
	when ''PK'' then ''PRIMARY KEY constraint'' 
	when ''P'' then ''SQL stored procedure'' 
	when ''PC'' then ''Assembly (CLR) stored procedure'' 
	when ''FN'' then ''SQL scalar function'' 
	when ''FS'' then ''Assembly (CLR) scalar function'' 
	when ''FT'' then ''Assembly (CLR) table-valued function'' 
	when ''R'' then ''Rule (old-style, stand-alone)'' 
	when ''RF'' then ''Replication-filter-procedure'' 
	when ''S'' then ''System base table'' 
	when ''SN'' then ''Synonym'' 
	when ''SQ'' then ''Service queue''
	when ''TA'' then ''Assembly (CLR) DML trigger'' 
	when ''TR'' then ''SQL DML trigger'' 
	when ''IF'' then ''SQL inline table-valued function'' 
	when ''TF'' then ''SQL table-valued-function'' 
	when ''U'' then ''Table (user-defined)'' 
	when ''UQ'' then ''UNIQUE constraint'' 
	when ''V'' then ''View'' 
	when ''X'' then ''Extended stored procedure'' 
	when ''IT'' then ''Internal table'' 
	end as ''Object Type'' 
	FROM 
	[' + @Next + '].dbo.sysusers a --.sys.database_principals a 
	left join [' + @Next + '].dbo.sysprotects d --sys.database_permissions d 
	on a.uid = d.uid --grantee_principal_id 
	left join #objects e on d.id = e.obj_id and e.database_name in (''master'','''+@Next+''')
	left JOIN ['+@Next+'].dbo.sysusers u ON e.owner_id = u.uid
	left join ['+@Next+'].dbo.sysmembers su on a.uid = su.memberuid
	--where a.hasdbaccess = 1
	order by database_name, a.issqlrole desc, a.name--, d.class_desc'

execute sp_executesql @sql

FETCH NEXT
FROM dbs
INTO @Next
      
END

CLOSE dbs
DEALLOCATE dbs
-- permission cursor

SET nocount OFF 

SELECT  CONVERT(varchar(250), SERVERPROPERTY('ServerName')) as 'Instance_Name', *
FROM    #permission 

drop table #permission
drop table #objects
