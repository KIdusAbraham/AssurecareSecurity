--SERVER LEVEL SECURITY

SELECT sp.state_desc,
sp.permission_name,
principal_name = QUOTENAME(spl.name),
spl.type_desc,
sp.state_desc + N' ' + sp.permission_name + N' TO ' + cast(QUOTENAME(spl.name COLLATE DATABASE_DEFAULT) as nvarchar(256)) AS "T-SQL Script"
FROM sys.server_permissions sp
inner join sys.server_principals spl on (sp.grantee_principal_id = spl.principal_id)
where spl.name not like '##%' -- skip PBM accounts
and spl.name not in ('dbo', 'sa', 'public')
order by sp.permission_name, spl.name


-------------------------------------------------------------------------------------------------


--SERVER LEVEL ROLES

SELECT DISTINCT
QUOTENAME(sp.name) AS "ServerRoleName",
sp.type_desc AS "RoleDescription",
QUOTENAME(m.name) AS "PrincipalName",
m.type_desc AS "LoginDescription",
'EXEC master..sp_addsrvrolemember @loginame = N''' + m.name + ''', @rolename = N''' + sp.name + '''' AS "T-SQL Script"
FROM sys.server_role_members AS srm
inner join sys.server_principals sp on (srm.role_principal_id = sp.principal_id)
inner join sys.server_principals m on (srm.member_principal_id = m.principal_id)
where sp.is_disabled = 0
and m.is_disabled = 0
and m.name not in ('dbo', 'sa', 'public')
and m.name <> 'NT AUTHORITY\SYSTEM'


----------------------------------------------------------------------------------------------------------------


--DATABASE LEVEL SECURITY [USING MSFOREACHDB TO GATHER FROM ALL DB'S]

IF OBJECT_ID('tempdb..#DBLevelSecurity') IS NOT NULL
DROP TABLE #DBLevelSecurity

Create Table #DBLevelSecurity (
	 DatabaseName VARCHAR(50)
	,State_Desc VARCHAR (30)
	,Permission_Name VARCHAR (30)
	,Principal_Name VARCHAR (100)
	,Type_Desc VARCHAR (50)
	,TSQL_Script VARCHAR (200)
	)
	
Execute master.sys.sp_MSforeachdb 'USE [?]; INSERT INTO #DBLevelSecurity

SELECT DB_NAME() as DatabaseName, dp.state_desc,

dp.permission_name,
QUOTENAME(dpl.name) AS ''Principal_Name'',
dpl.type_desc,
''IF NOT EXISTS (SELECT name FROM master.sys.server_principals WHERE [name] = '''' + [name] + '''')'' + dp.state_desc + N'' '' + dp.permission_name + N'' TO '' + cast(QUOTENAME(dpl.name COLLATE DATABASE_DEFAULT) as nvarchar(500)) AS "T-SQL Script"
FROM sys.database_permissions AS dp
INNER JOIN sys.database_principals AS dpl ON (dp.grantee_principal_id = dpl.principal_id)
WHERE dp.major_id = 0
and dpl.name not like ''##%'' -- excluds PBM accounts
and dpl.name not in (''dbo'', ''sa'', ''public'')
ORDER BY dp.permission_name ASC, dp.state_desc ASC'

SELECT * 
FROM #DBLevelSecurity

--DROP TABLE #DBLevelSecurity


-----------------------------------------------------------------------------------------------------------



--DATABASE LEVEL ROLES [USING MSFOREACHDB TO GATHER FROM ALL DB'S]

IF OBJECT_ID('tempdb..#DBLevelRoles') IS NOT NULL
DROP TABLE #DBLevelRoles

Create Table #DBLevelRoles (
	 DatabaseName VARCHAR(50)
	,DatabaseRoleName VARCHAR(30)
	,Role_desc VARCHAR(30)
	,PrincipalName VARCHAR(100)
	,Type_Desc VARCHAR(50)
	,TSQL_Script VARCHAR(200)
	)

Execute master.sys.sp_MSforeachdb 'USE [?]; INSERT INTO #DBLevelRoles

SELECT DISTINCT
DB_NAME() AS DatabaseName,
QUOTENAME(drole.name) as "DatabaseRoleName",
drole.type_desc,
QUOTENAME(dp.name) as "PrincipalName",
dp.type_desc,
''EXEC sp_addrolemember @membername = N'''''' + dp.name COLLATE DATABASE_DEFAULT + '''''', @rolename = N'''''' + drole.name + '''''''' AS "T-SQL Script"
FROM sys.database_role_members AS drm
inner join sys.database_principals drole on (drm.role_principal_id = drole.principal_id)
inner join sys.database_principals dp on (drm.member_principal_id = dp.principal_id)
where dp.name not in (''dbo'', ''sa'', ''public'')'

SELECT * 
FROM #DBLevelRoles

--DROP TABLE #DBLevelRoles


---------------------------------------------------------------------------------------------------



--DATABASE LEVEL EXPLICIT PERMISSIONS [USING MSFOREACHDB TO GATHER FROM ALL DB'S]

IF OBJECT_ID('tempdb..#DBLevelPermissions') IS NOT NULL
DROP TABLE #DBLevelPermissions

Create Table #DBLevelPermissions (
	 DatabaseName VARCHAR(50)
	,StateDescription VARCHAR(50)
	,PermissionName VARCHAR(50)
	,[Schema Name] VARCHAR(50)
	,[Object Name] VARCHAR(400)
	,[Full Object Name] VARCHAR(400)
	,UserName VARCHAR (50)
	,UserRoleType VARCHAR (50)
	,ObjectType VARCHAR (100)
	,[T-SQL Script] VARCHAR (500)
	)

Execute master.sys.sp_MSforeachdb 'USE [?]; INSERT INTO #DBLevelPermissions

SELECT 
DB_NAME() AS DatabaseName,
dp.state_desc AS "StateDescription" ,
dp.permission_name AS "PermissionName" ,
SCHEMA_NAME(obj.schema_id) AS [Schema Name],
obj.NAME AS [Object Name],
QUOTENAME(SCHEMA_NAME(obj.schema_id)) + ''.'' + QUOTENAME(obj.name) + CASE WHEN col.column_id IS NULL THEN SPACE(0) ELSE ''('' + QUOTENAME(col.name COLLATE DATABASE_DEFAULT) + '')'' END AS "ObjectName" ,
QUOTENAME(dpl.name COLLATE database_default) AS "UserName" ,
dpl.type_Desc AS "UserRoleType" ,
obj.type_desc AS "ObjectType" ,
dp.state_desc + N'' '' + dp.permission_name + N'' ON '' + QUOTENAME(SCHEMA_NAME(obj.schema_id)) + ''.'' + QUOTENAME(obj.name) + N'' TO '' + QUOTENAME(dpl.name COLLATE database_default) AS "T-SQL Script"
FROM sys.database_permissions AS dp
INNER JOIN sys.objects AS obj ON ( dp.major_id = obj.[object_id] )
INNER JOIN sys.database_principals AS dpl ON ( dp.grantee_principal_id = dpl.principal_id )
LEFT JOIN sys.columns AS col ON ( col.column_id = dp.minor_id AND col.[object_id] = dp.major_id)
WHERE obj.name NOT LIKE ''dt%''
AND obj.is_ms_shipped = 0
AND dpl.name NOT IN ( ''dbo'', ''sa'', ''public'' )
ORDER BY dp.permission_name ASC , dp.state_desc ASC'

SELECT * 
FROM #DBLevelPermissions

--DROP TABLE #DBLevelPermissions