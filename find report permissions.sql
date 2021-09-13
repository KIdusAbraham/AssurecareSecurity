select C.UserName, D.RoleName, D.Description, E.Path, E.Name 
from dbo.PolicyUserRole A
   inner join dbo.Policies B on A.PolicyID = B.PolicyID
   inner join dbo.Users C on A.UserID = C.UserID
   inner join dbo.Roles D on A.RoleID = D.RoleID
   inner join dbo.Catalog E on A.PolicyID = E.PolicyID
order by path

SELECT C.Name 
      ,U.UserName 
      ,R.RoleName 
      ,R.Description 
      ,U.AuthType 
  FROM Reportserver.dbo.Users U 
  JOIN Reportserver.dbo.PolicyUserRole PUR 
    ON U.UserID = PUR.UserID 
  JOIN Reportserver.dbo.Policies P 
    ON P.PolicyID = PUR.PolicyID 
  JOIN Reportserver.dbo.Roles R 
    ON R.RoleID = PUR.RoleID 
  JOIN Reportserver.dbo.Catalog c 
    ON C.PolicyID = P.PolicyID 
 
ORDER BY U.UserName 


SELECT Catalog.Name, Catalog.Path, Users.UserName


FROM Catalog INNER JOIN


Policies ON Catalog.PolicyID = Policies.PolicyID INNER JOIN


PolicyUserRole ON PolicyUserRole.PolicyID = Policies.PolicyID INNER JOIN


Users ON PolicyUserRole.UserID = Users.UserID


WHERE (Catalog.ParentID =


(SELECT ItemID


FROM Catalog


WHERE (ParentID IS NULL)))

ORDER BY Catalog.Path, Users.UserName

SELECT distinct Users.UserName [User],

STUFF(( select ','+isnull(R2.RoleName,'')
FROM Catalog Catalog2 INNER JOIN
Policies Policies2 ON Catalog2.PolicyID = Policies2.PolicyID INNER JOIN
PolicyUserRole PolicyUserRole2  ON PolicyUserRole2.PolicyID = Policies2.PolicyID INNER JOIN
Users Users2 ON PolicyUserRole2.UserID = Users2.UserID
 JOIN Reportserver.dbo.Roles R2
    ON R2.RoleID = PolicyUserRole2.RoleID 
where users2.UserName = users.UserName
and catalog2.Name = Catalog.Name
order by R2.RoleName
for XML path ('')),1,1,'') as [Role]

,Catalog.Name [Type]

FROM Catalog INNER JOIN
Policies ON Catalog.PolicyID = Policies.PolicyID INNER JOIN
PolicyUserRole ON PolicyUserRole.PolicyID = Policies.PolicyID 
INNER JOIN
Users ON PolicyUserRole.UserID = Users.UserID
 --JOIN Reportserver.dbo.Roles R 
 --   ON R.RoleID = PolicyUserRole.RoleID 
WHERE (Catalog.ParentID =
(SELECT ItemID
FROM Catalog
WHERE (ParentID IS NULL)))
ORDER BY 3, 1

