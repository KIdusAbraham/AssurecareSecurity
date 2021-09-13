declare @dbname sysname
--set @dbname = 'MSOW'

/* Users and Server Roles */

SELECT role.name AS RoleName,
member.name AS MemberName
FROM sys.server_role_members
JOIN sys.server_principals AS role
ON sys.server_role_members.role_principal_id = role.principal_id
JOIN sys.server_principals AS member
ON sys.server_role_members.member_principal_id = member.principal_id;

/* Users and database Roles*/
CREATE TABLE #temp
(
[Instance Name] VARCHAR(128),
[Database Name] VARCHAR(128),
[Database Role] VARCHAR(128),
[Database User] VARCHAR(128)
)

exec sp_msForEachDb ' use [?]
INSERT into #temp
select @@SERVERNAME AS [Server Name],
db_name() AS [Database Name],
rp.name as database_role,
mp.name as database_user
from sys.database_role_members drm
join sys.database_principals rp on (drm.role_principal_id = rp.principal_id)
join sys.database_principals mp on (drm.member_principal_id = mp.principal_id)'

if @dbname is null
begin
	select * from #temp where [Database Name] <> 'tempdb'
	ORDER BY [Database Name] ASC
end
else
begin
	select * from #temp where [Database Name] = @dbname
end

drop table #temp

--SERVER LEVEL SECURITY

SELECT sp.state_desc [State Description],
sp.permission_name [Permission Name],
[Login Name] = QUOTENAME(spl.name),
spl.type_desc [Login Type]--,
--sp.state_desc + N' ' + sp.permission_name + N' TO ' + cast(QUOTENAME(spl.name COLLATE DATABASE_DEFAULT) as nvarchar(256)) AS "T-SQL Script"
FROM sys.server_permissions sp
inner join sys.server_principals spl on (sp.grantee_principal_id = spl.principal_id)
where spl.name not like '##%' -- skip PBM accounts
and spl.name not in ('dbo', 'sa', 'public')
order by sp.permission_name, spl.name

--DATABASE LEVEL EXPLICIT PERMISSIONS [USING MSFOREACHDB TO GATHER FROM ALL DB'S]

IF OBJECT_ID('tempdb..#DBLevelPermissions') IS NOT NULL
DROP TABLE #DBLevelPermissions

Create Table #DBLevelPermissions (
	 [Database Name] VARCHAR(50)
	,[State Description] VARCHAR(50)
	,[Permission Name] VARCHAR(50)
	--,[Schema Name] VARCHAR(50)
	--,[Object Name] VARCHAR(400)
	,[Full Object Name] VARCHAR(400)
	,[User Name] VARCHAR (50)
	,[User Type] VARCHAR (50)
	,[Object Type] VARCHAR (100)
	--,[T-SQL Script] VARCHAR (500)r
	)

Execute master.sys.sp_MSforeachdb 'USE [?]; INSERT INTO #DBLevelPermissions

SELECT 
DB_NAME() AS DatabaseName,
dp.state_desc AS "StateDescription" ,
dp.permission_name AS "PermissionName" ,
--SCHEMA_NAME(obj.schema_id) AS [Schema Name],
--obj.NAME AS [Object Name],
QUOTENAME(SCHEMA_NAME(obj.schema_id)) + ''.'' + QUOTENAME(obj.name) + CASE WHEN col.column_id IS NULL THEN SPACE(0) ELSE ''('' + QUOTENAME(col.name COLLATE DATABASE_DEFAULT) + '')'' END AS "ObjectName" ,
QUOTENAME(dpl.name COLLATE database_default) AS "UserName" ,
dpl.type_Desc AS "UserRoleType" ,
obj.type_desc AS "ObjectType" --,
--dp.state_desc + N'' '' + dp.permission_name + N'' ON '' + QUOTENAME(SCHEMA_NAME(obj.schema_id)) + ''.'' + QUOTENAME(obj.name) + N'' TO '' + QUOTENAME(dpl.name COLLATE database_default) AS "T-SQL Script"
FROM sys.database_permissions AS dp
INNER JOIN sys.objects AS obj ON ( dp.major_id = obj.[object_id] )
INNER JOIN sys.database_principals AS dpl ON ( dp.grantee_principal_id = dpl.principal_id )
LEFT JOIN sys.columns AS col ON ( col.column_id = dp.minor_id AND col.[object_id] = dp.major_id)
WHERE obj.name NOT LIKE ''dt%''
AND obj.is_ms_shipped = 0
AND dpl.name NOT IN ( ''dbo'', ''sa'', ''public'' ,''RSExecRole'')
ORDER BY dp.permission_name ASC , dp.state_desc ASC'

if @dbname is null
begin
	SELECT * 
	FROM #DBLevelPermissions
end
else
begin
	SELECT * 
	FROM #DBLevelPermissions
	where [Database Name] = @dbname
	--and [User Name] not in ( '[Morrisey]', '[MSOWReports]' )
end

DROP TABLE #DBLevelPermissions