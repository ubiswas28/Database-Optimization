set statistics io,time on

--Spooling Sample 
--Spooling means copy of data
--Query 1
SELECT *
FROM Student AS S
WHERE DOB IN (
		SELECT MAX(DOB)
		FROM Student sp
		WHERE YEAR(S.DOB) = YEAR(sp.DOB)
		GROUP BY YEAR(sp.DOB)
		)
ORDER BY DOB;

select count(*) from  Student

;WITH CTE
AS (
	SELECT YEAR(DOB) [Year]
		,max(DOB) [DOB]
	FROM Student sp
	GROUP BY YEAR(DOB)
	)
SELECT *
FROM Student AS S
INNER JOIN CTE ON s.DOB = CTE.DOB

--Query 2
SELECT DISTINCT cust.CompanyName
	,(
		SELECT sum(freight)
		FROM orders ord1
		WHERE upper(ord1.CustomerID) = ord.CustomerID
		)
FROM orders ord
INNER JOIN customers cust ON ord.CustomerID = cust.customerid

SELECT DISTINCT cust.CompanyName
	,(
		SELECT sum(freight)
		FROM orders ord1
		WHERE ord1.CustomerID = ord.CustomerID
		)
FROM orders ord
INNER JOIN customers cust ON ord.CustomerID = cust.customerid

--Spooling in insertion

UPDATE orders
SET Freight = Freight + 1 - 1
WHERE orders.Freight < 100

UPDATE orders
SET Freight = Freight + 1 - 1
FROM orders
WHERE orders.Freight < 100

UPDATE orders
SET Freight = Freight + 1 - 1
FROM orders WITH (INDEX = PK_Orders)
WHERE orders.Freight < 100


--Spooling in recursive CTE
WITH CTE AS
  (SELECT H1.EmpID,
          H1.ParentID,
          h1.Description [Parent],
          Description [Self Description],
          CAST(id AS varbinary(MAX)) [Level],
          CAST (h1.id AS varchar(max)) [LevelID]
   FROM HierarchyTB H1
   WHERE h1.ParentID=0
   UNION ALL SELECT H2.EmpID,
                    H2.ParentID,
                    c.[Self Description],
                    Description [Self Description],
                    c.[Level]+CAST(h2.id AS varbinary(MAX)) AS [Level],
                                  c.[LevelID] + '>' + CAST (h2.id AS varchar(max)) [LevelID]
   FROM HierarchyTB H2
   INNER JOIN CTE c ON h2.ParentID=c.EmpID)
SELECT *
FROM CTE CROSS apply
  ( SELECT SUBSTRING(LevelID,1,CHARINDEX('>',LevelID+ '>')-1) ) c(RootLevelID)
ORDER BY [Level] OPTION (MAXRECURSION 1000)




-- If want to select max freight
-- you can't use max(Freight) here with this
-- also want to select ship name
SELECT cust.companyname
	,(
		SELECT TOP 1 orderid
		FROM orders o
		WHERE o.customerid = cust.customerid
		ORDER BY orderid DESC
		) [Last order]
	,(
		SELECT TOP 1 freight
		FROM orders o
		WHERE o.customerid = cust.customerid
		ORDER BY orderid DESC
		) [Last Freight]
	,(
		SELECT TOP 1 shipname
		FROM orders o
		WHERE o.customerid = cust.customerid
		ORDER BY orderid DESC
		) [Last shipname]
		,(
		SELECT TOP 1 OrderDate
		FROM orders o
		WHERE o.customerid = cust.customerid
		ORDER BY orderid DESC
		) OrderDate
			,(
		SELECT TOP 1 o.ShipCountry
		FROM orders o
		WHERE o.customerid = cust.customerid
		ORDER BY orderid DESC
		) ShipCountry
FROM customers cust
ORDER BY cust.companyname

SELECT cust.companyname
	,CApOperator.*
FROM customers cust
outer APPLY (
	SELECT TOP 1 orderid AS [Last order]
		,freight AS [Last Freight]
		,shipname AS [Last shipname],
		OrderDate
	FROM orders o
	WHERE o.customerid = cust.customerid
	ORDER BY orderid DESC
	) CApOperator
ORDER BY cust.companyname

SELECT cust.companyname
	,t1.orderid
	,t1.shipname
	,t1.freight
FROM (
	SELECT o1.customerid
		,orderid
		,shipname
		,freight
	FROM orders o1
	WHERE orderid = (
			SELECT TOP 1 orderid
			FROM orders o
			WHERE o.customerid = o1.customerid
			ORDER BY orderid DESC
			)
	) t1
INNER JOIN customers cust ON t1.customerid = cust.customerid
ORDER BY cust.companyname

-- What is more optimized 
SELECT cust.companyname
	,t1.orderid
	,t1.shipname
	,t1.freight
FROM (
	SELECT o1.customerid
		,orderid
		,shipname
		,freight
	FROM orders o1
	WHERE orderid = (
			SELECT max(orderid)
			FROM orders o
			WHERE o.customerid = o1.customerid
			)
	) t1
INNER JOIN customers cust ON t1.customerid = cust.customerid
ORDER BY cust.companyname




--View with additional column

CREATE VIEW OrderProductView
AS
SELECT ordd.ProductID
	,ord.orderid
	,ORD.OrderDate
	,ORD.CustomerID
	,ORDD.Discount
	,PROD.ProductName
FROM orders ord
INNER JOIN [Order Details] ORDD ON ORD.OrderID = ORDD.OrderID
INNER JOIN Products PROD ON ORDD.ProductID = PROD.ProductID


select * from OrderProductView
SELECT ord.orderid
	,ORD.OrderDate
	,ordd.UnitPrice
	,ORD.CustomerID
	,ORDD.Discount
	,PROD.ProductName
	,ordd.Quantity
FROM orders ord
INNER JOIN [Order Details] ORDD ON ORD.OrderID = ORDD.OrderID
INNER JOIN Products PROD ON ORDD.ProductID = PROD.ProductID
OPTION (MAXDOP 1)

SELECT DISTINCT opv.*
	,ordd.Quantity
	,ordd.UnitPrice
FROM OrderProductView opv
INNER JOIN [Order Details] ordd ON opv.orderid = ordd.OrderID
	AND opv.productid = ordd.ProductID


--Partition Elimination
	
set statistics io on
DECLARE @SData DATETIME2 = '1996-08-04 00:00:00.000'
	,@EData DATETIME2 = '1996-09-04 00:00:00.000'


SELECT *
FROM OrderDetails ordd
WHERE ordd.OrderDate >= @SData
	AND ordd.OrderDate <= @EData

	
SELECT *
FROM OrderDetails ordd
WHERE dateadd(d,0,ordd.OrderDate) >= cast(@SData as datetime)
	AND ordd.OrderDate <= cast(@EData as datetime)