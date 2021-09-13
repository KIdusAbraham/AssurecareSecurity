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
select * from #temp where [Database Name] <> 'tempdb'
ORDER BY [Database Name] ASC
drop table #temp