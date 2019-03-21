--a.  Using Sales.Orders, Sum of Unit by month and Year
--Note: I didn't see a way to sum units from sales.orders so I joined orderlines in order to sum a total quantity of units.
SELECT SUM(L.Quantity) Units, MONTH(O.OrderDate) "month", Year(O.OrderDate) "year"
FROM Sales.Orders O
INNER JOIN Sales.Orderlines L
ON O.OrderID = L.OrderID
GROUP BY Year(O.OrderDate), MONTH(O.OrderDate)
ORDER BY 3,2;


--b.  Using Sales.Order & Sales.Customers, the DeliveryCityID with the highest Revenue
--Note: I didn't see anything to use as revunue in the 2 mentioned tables so I joined on CustomerTransactions
SELECT DeliveryCityID, Revenue
FROM
(
SELECT C.DeliveryCityID, SUM(CT.TransactionAmount) Revenue,
RANK() OVER ( ORDER BY SUM(CT.TransactionAmount) DESC) AS Rnk
FROM Sales.Customers C
INNER JOIN Sales.Orders O
ON C.CustomerID = O.CustomerID
INNER JOIN Sales.CustomerTransactions CT
ON CT.CustomerID = O.CustomerID
GROUP BY C.DeliveryCityID
) AS Ranking
WHERE Ranking.Rnk = 1;


--c.  Using Sales.Order & Sales.Customers, the DeliveryCityID with the 3 highest Revenue
SELECT DeliveryCityID, Revenue 
FROM
(
SELECT C.DeliveryCityID, SUM(CT.TransactionAmount) Revenue,
RANK() OVER ( ORDER BY SUM(CT.TransactionAmount) DESC) AS Rnk
FROM Sales.Customers C
INNER JOIN Sales.Orders O
ON C.CustomerID = O.CustomerID
INNER JOIN Sales.CustomerTransactions CT
ON CT.CustomerID = O.CustomerID
GROUP BY C.DeliveryCityID
) AS Ranking
WHERE Ranking.Rnk <=3;


--d.  Using Sales.Order & Sales.Customers, bin the orders in high frequency, medium frequency and Low frequency buyers.
--Note: Frequency rating 1 = high, 2 = med, 3 = low
SELECT C.CustomerID, COUNT(O.OrderID) "Num of Orders",NTILE(3) OVER (ORDER BY COUNT(O.OrderID) DESC) AS "Frequency Rating"
FROM Sales.Customers C
INNER JOIN Sales.Orders O
ON C.CustomerID = O.CustomerID
GROUP BY C.CustomerID;

--e.  Using Sales.Order & Sales.Order.Line, calculate the sales by day with and without Taxes
SELECT O.OrderDate, SUM((L.UnitPrice * L.Quantity)) AS "Before Taxes", SUM(CONVERT(DECIMAL(10,2),(L.UnitPrice * L.Quantity * L.TaxRate))) AS "After Taxes"
FROM Sales.Orders O
INNER JOIN Sales.OrderLines L
ON O.OrderID = L.OrderID
GROUP BY O.OrderDate
ORDER BY O.OrderDate;

--f.  Using Sales.Order & Warehouse.PackageTypes, calculate the average spend per customer
--Note: Didn't use Warehouse.PackageTypes bc it didn't have any information to help the calc of avg spend per cust
SELECT O.CustomerId,CONVERT(DECIMAL(10,2),(SUM((L.UnitPrice * L.Quantity * L.TaxRate)))/COUNT(L.OrderId)) AS "Average Order Spend"
FROM Sales.Orders O
INNER JOIN Sales.OrderLines L
ON O.OrderID = L.OrderID
GROUP BY O.CustomerId
ORDER BY 2 DESC;

--g.  Using Sales.Customer & Sales.Order, provide a dataset showing the best 3 and worst 3 average spend for customers who opened the account in the lat year
--Note: there aren't any accounts open in the past year so I omitted that part
SELECT CustomerID, AccountOpenedDate, AvgOrderSpend
FROM
(
SELECT O.CustomerId,C.AccountOpenedDate,
CONVERT(DECIMAL(10,2),(SUM((L.UnitPrice * L.Quantity * L.TaxRate)))/COUNT(L.OrderId)) AS AvgOrderSpend,
RANK() OVER ( ORDER BY CONVERT(DECIMAL(10,2),(SUM((L.UnitPrice * L.Quantity * L.TaxRate)))/COUNT(L.OrderId)) DESC) AS TopThree,
RANK() OVER ( ORDER BY CONVERT(DECIMAL(10,2),(SUM((L.UnitPrice * L.Quantity * L.TaxRate)))/COUNT(L.OrderId))) AS BottomThree
FROM Sales.Orders O
INNER JOIN Sales.OrderLines L
ON O.OrderID = L.OrderID
INNER JOIN Sales.Customers C
ON C.CustomerID = O.CustomerID
GROUP BY O.CustomerId, AccountOpenedDate
) Ranking
WHERE TopThree <= 3
OR BottomThree <=3
ORDER BY 3 DESC;

--h.  Using Sales.CustomerTransactions find the product that consitently has the most OutstandingBalance
SELECT StockItemName
FROM
(
SELECT W.StockItemID, COUNT(T.StockItemID) AS Total,W.StockItemName, C.OutstandingBalance,
ROW_NUMBER() OVER ( ORDER BY C.OutstandingBalance DESC, COUNT(T.StockItemID)  DESC) AS Rnk
FROM Warehouse.StockItems W
INNER JOIN Warehouse.StockItemTransactions T
ON W.StockItemID = T.StockItemID
INNER JOIN Sales.CustomerTransactions C
ON C.CustomerID = T.CustomerID
WHERE C.OutstandingBalance > 0
GROUP BY W.StockItemID, W.StockItemName, C.OutstandingBalance
) TopItems
WHERE TopItems.Rnk = 1;

--i.  Develope a "Risk" & "Likability" metric based on how many Special Deals a customer had. This is an open ended question. Please feel free to expand on the tables used
-- It doesn't seem like there is enough data to create this metric. The Special Deals table has 2 values and below are my checks to see if anything is useful
--all StockItemIds are NULL
SELECT DISTINCT StockItemID from Sales.SpecialDeals;

--thought I'd check to see if any of the stockitemnames match what's in the specialdeals table and using the query below, none match
SELECT *
FROM Warehouse.StockItems
WHERE StockItemName LIKE '%USB Wingtip%' OR StockItemName LIKE '%USB Tailspin%'


--j.  Generate a query that sleect a random number of customers (3-10) and a random number of products (3-10) and create a cartician product of the two

--k.  Using Invoice and Sales.Order find a customer rank the slowest to highest OrderDate to InvoiceDate
--NOTE: Unsure to use RANK() or DENSE_RANK()
SELECT S.CustomerID, S.OrderDate,I.InvoiceDate,
RANK() OVER ( ORDER BY S.OrderDate, InvoiceDate) AS Rank
FROM Sales.Orders S
INNER JOIN Sales.Invoices I
ON S.CustomerID = I.CustomerID;

--l.  Using Sales.Orders, provide a cumulitive sum of quantities by month
SELECT DISTINCT YEAR(OrderDate) AS OrderYear, MONTH(OrderDate) AS OrderMonth, 
SUM(L.Quantity) OVER(PARTITION BY YEAR(OrderDate), MONTH(OrderDate) ORDER BY YEAR(OrderDate), MONTH(OrderDate)) AS MonthlyQuantities,
SUM(L.Quantity) OVER(PARTITION BY YEAR(OrderDate) ORDER BY MONTH(OrderDate)) AS CumulativeMonthly
FROM Sales.Orders O
INNER JOIN Sales.Orderlines L
ON O.OrderID = L.OrderID
ORDER BY YEAR(OrderDate), MONTH(OrderDate)


--m.  Using Sales.Orders, provide a Running Average of quantities by month
SELECT DISTINCT YEAR(OrderDate) AS OrderYear, MONTH(OrderDate) AS OrderMonth, 
AVG(L.Quantity) OVER(PARTITION BY YEAR(OrderDate), MONTH(OrderDate) ORDER BY YEAR(OrderDate), MONTH(OrderDate)) AS MonthlyAverages,
AVG(L.Quantity) OVER(PARTITION BY YEAR(OrderDate) ORDER BY MONTH(OrderDate)) AS RunningMonthlyAverage
FROM Sales.Orders O
INNER JOIN Sales.Orderlines L
ON O.OrderID = L.OrderID
ORDER BY YEAR(OrderDate), MONTH(OrderDate)


--Provide the SQL statement to add a user with read access
CREATE USER NewUser WITH PASSWORD = 'Testing2019!';
GRANT SELECT TO NewUser;

--Provide a query that provides all tables in the database
SELECT * 
FROM information_schema.TABLES
WHERE TABLE_CATALOG ='WideWorldImporters-Standard'

