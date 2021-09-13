
create table #adgroup (
loginname sysname,
logintype char(8),
priv char(9),
loginmapped sysname,
adgroup sysname
)

/*
--GET GROUPS
select 'insert into #adgroup
exec xp_logininfo @acctname = '''+sp.name+''', @option=''members'';'
FROM sys.server_principals sp 
where [type] = 'G'
*/

--PASTE GET GROUPS OUTPUT 'from text' HERE

create table #srvroles (
serverrole sysname,
loginname sysname,
loginsid varbinary(85)
)

insert into #srvroles
EXEC master..sp_helpsrvrolemember


DECLARE @DB_Users TABLE (DBName sysname, UserName sysname, LoginType sysname
, AssociatedRole varchar(max), create_date datetime, modify_date datetime, sid varbinary(85))

INSERT @DB_Users
EXEC sp_MSforeachdb
'use [?]
SELECT ''?'' AS DB_Name,
case prin.name when ''dbo'' then prin.name + '' (''
    + (select SUSER_SNAME(owner_sid) from master.sys.databases where name =''?'') + '')''
    else prin.name end AS UserName,
    prin.type_desc AS LoginType,
    isnull(USER_NAME(mem.role_principal_id),'''') AS AssociatedRole, 
    create_date, modify_date, prin.sid
FROM sys.database_principals prin
LEFT OUTER JOIN sys.database_role_members mem
    ON prin.principal_id=mem.member_principal_id
WHERE prin.sid IS NOT NULL and prin.sid NOT IN (0x00)
and prin.is_fixed_role <> 1 AND prin.name NOT LIKE ''##%'''

SELECT dbname, username, logintype, create_date, modify_date, sid,
    STUFF((SELECT ',' + CONVERT(VARCHAR(500), associatedrole)
        FROM @DB_Users user2
        WHERE user1.DBName=user2.DBName AND user1.UserName=user2.UserName
        FOR XML PATH('')
    ),1,1,'') AS Permissions_user
into #dbroles
FROM @DB_Users user1
--WHERE user1.UserName = N'<put your login-name here!>'
GROUP BY dbname, username, logintype, create_date, modify_date, sid
ORDER BY DBName, username

--select * from #dbroles



    SELECT distinct dbname,
       drole.logintype,-- [UserType] = CASE membprinc.[type]
                     --    WHEN 'S' THEN 'SQL User'
                     --    WHEN 'U' THEN 'Windows User'
                     --    WHEN 'G' THEN 'Windows Group'
                     --END,
        [LoginName]        = ulogin.[name],
		[InstanceRole] = srole.serverrole,
        username,--[DatabaseUserName] = membprinc.[name],
        [DBRole]             = drole.Permissions_user,
		grp.adgroup
		
		--, stuff(
		--	(
		--		select ','+roleprinc.name
		--		from --sys.database_role_members          AS members
		--		--JOIN      
		--		sys.database_principals  AS roleprinc
		--		--ON roleprinc.[principal_id] = members.[role_principal_id]
		--		--JOIN      sys.database_principals  AS membprinc ON membprinc.[principal_id] = members.[member_principal_id]
		--		where roleprinc.type = 'R'
		--		and roleprinc.[principal_id] = members.[role_principal_id]
		--		for xml path ('')
		--	), 1, 1, ''
		--) AS dbroles
        
    FROM
        ------Role/member associations
        ----sys.database_role_members          AS members

        ------db Roles
        ------JOIN      sys.database_principals  AS roleprinc ON roleprinc.[principal_id] = members.[role_principal_id]

        ------Role members (database users)
        ----right JOIN      sys.database_principals  AS membprinc ON membprinc.[principal_id] = members.[member_principal_id]

        --Login accounts
        --right JOIN 
		sys.server_principals    AS ulogin    --ON ulogin.[sid] = membprinc.[sid]

		--instance roles
		left join #srvroles srole on ulogin.sid=srole.loginsid
		left join #dbroles drole on ulogin.sid=drole.sid
		left join #adgroup grp on ulogin.name=grp.loginname
    WHERE ulogin.[name] not like '%#%' and drole.logintype <> 'R'
        --membprinc.[type] IN ('S','U','G')
        -- No need for these system accounts
       -- AND membprinc.[name] NOT IN ('sys', 'INFORMATION_SCHEMA')
		order by [LoginName]


drop table #srvroles
drop table #dbroles 
drop table #adgroup
