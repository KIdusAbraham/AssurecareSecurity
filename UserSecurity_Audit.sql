--create procedure usp_AccessList_new 
declare @databases sysname 
set @databases = 'ALL'
--as
--begin

--SET nocount ON 

declare @sql nvarchar(4000)

--DECLARE @permission TABLE
create table #permission
(
	Database_Name SYSNAME,
	User_Role_Name SYSNAME,
	Account_Type NVARCHAR(60),
	Action_Type NVARCHAR(128),
	Permission NVARCHAR(60),
	ObjectName SYSNAME NULL,
	Object_Type NVARCHAR(60)
) 

--declare @objects table 
create table #objects
(
	obj_id int, 
	obj_type char(2)
)  

insert into #objects 
	select id, xtype from master.sys.sysobjects 

insert into #objects 
	select object_id, type from sys.objects 

--DECLARE @dbs TABLE ( dbname SYSNAME ) r

DECLARE @Next SYSNAME 

if @databases = 'ALL'
begin
	DECLARE dbs CURSOR FOR
	SELECT  name
	FROM    sys.databases
	WHERE state_desc = 'ONLINE'
	ORDER BY name        
end
else
begin
	DECLARE dbs CURSOR FOR
	SELECT  name
	FROM    sys.databases
	WHERE state_desc = 'ONLINE'
	AND name = @databases
end      

OPEN dbs

FETCH NEXT
FROM dbs
INTO @Next

WHILE @@FETCH_STATUS = 0
BEGIN

set @sql = 
	'INSERT  INTO #permission
	SELECT ''' + @Next + ''', a.name as ''User or Role Name'', a.type_desc as ''Account Type'', 
	d.permission_name as ''Type of Permission'', d.state_desc as ''State of Permission'', 
	OBJECT_SCHEMA_NAME(d.major_id) + ''.'' + object_name(d.major_id) as ''Object Name'', 
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
	FROM [' + @Next + '].sys.database_principals a 
	left join [' + @Next + '].sys.database_permissions d on a.principal_id = d.grantee_principal_id 
	left join #objects e on d.major_id = e.obj_id 
	order by a.name, d.class_desc'

execute sp_executesql @sql

FETCH NEXT
FROM dbs
INTO @Next
      
END

-- Close and deallocate the cursor.
CLOSE dbs
DEALLOCATE dbs

--SET nocount OFF 

SELECT  *
FROM    #permission 

drop table #permission
drop table #objects