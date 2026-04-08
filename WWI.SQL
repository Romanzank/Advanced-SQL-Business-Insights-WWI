--*Q1 Calculate Yearly Income, Linear Projection, and YoY Growth Rate:
with cte1
as(
select year(si.InvoiceDate) year, sum(sil.ExtendedPrice-TaxAmount) as IncomePerYear,
DATEDIFF(MONTH, DATEFROMPARTS(YEAR(si.InvoiceDate), 1, 1),  
DATEFROMPARTS(YEAR(si.InvoiceDate), MONTH(MAX(si.InvoiceDate)), 1)) + 1 AS MonthsInYear
from Sales.InvoiceLines sil join sales.Invoices si
on sil.InvoiceID = si.InvoiceID
group by year(si.InvoiceDate))
select *, (12.0/ MonthsInYear) * IncomePerYear as YearlyLinearIncome,
((IncomePerYear * (12.0 / MonthsInYear) -
LAG(IncomePerYear * (12.0 / MonthsInYear)) OVER (ORDER BY [Year]))
/ NULLIF(LAG(IncomePerYear * (12.0 / MonthsInYear)) OVER (ORDER BY [Year]),0)) * 100
AS GrowthRatePercent
from cte1
order by year

--*Q2 Identify Top 5 Customers by Revenue for each Year and Quarter:
with cte1
as(
select year(si.InvoiceDate) as Year, DATEPART(QUARTER, si.InvoiceDate) AS Quarter,
si.CustomerID, sc.CustomerName, sum(sil.ExtendedPrice- sil.TaxAmount) as IncomePerYear 
from Sales.InvoiceLines sil join sales.Invoices si
on sil.InvoiceID = si.InvoiceID join sales.Customers sc 
on sc.CustomerID = si.CustomerID
group by year(si.InvoiceDate) , DATEPART(QUARTER, si.InvoiceDate),
si.CustomerID, sc.CustomerName),
cte2 as (
select *, DENSE_RANK() over ( partition by c.year, c.quarter
order by c.incomeperyear desc, c.customerid) as DNR
from cte1 c)
select *
from cte2 c
where DNR<= 5 
order by Year, Quarter, DNR

--*Q3 List Top 10 Most Profitable Stock Items:
with cte1
as(
select sil.StockItemID, si.StockItemName as StockItemName,
sum(sil.ExtendedPrice-sil.TaxAmount) as TotalProfit
from sales.InvoiceLines sil join Warehouse.StockItems si
on si.StockItemID = sil.StockItemID
group by sil.StockItemID, si.StockItemName)
select top 10 *
from cte1
order by TotalProfit desc

--*Q4 Rank Products by Nominal Profit Margin and Retail Price:
select ROW_NUMBER() over(order by (RecommendedRetailPrice - UnitPrice) desc) RN,
StockItemID, StockItemName, UnitPrice, RecommendedRetailPrice,(RecommendedRetailPrice - UnitPrice) as NominalProfit,
dense_rank() over( order by (RecommendedRetailPrice - UnitPrice) desc) 
as DNR
from Warehouse.StockItems
where ValidTo > getdate()

--*Q5 Consolidate Product Details by Supplier using STRING_AGG:
select cast(si.SupplierID  as nvarchar) + '-' + ps.SupplierName as SupplierDetailes,
STRING_AGG(concat(si.StockItemID, ' ', si.StockItemName), '/,' ) as ProductDetails
from Purchasing.Suppliers ps join Warehouse.StockItems si
on ps.SupplierID = si.SupplierID
group by cast(si.SupplierID as nvarchar) + '-' + ps.SupplierName, si.SupplierID

--*Q6 Identify Top 5 Customers by Total Spend and their Geographical Location:
with cte1
as(
select c.CustomerID, ac.CityName, acs.CountryName, acs.Continent, acs.Region,
sum(sil.ExtendedPrice) as TotalSpent
from Sales.InvoiceLines sil join sales.Invoices si
on sil.InvoiceID = si.InvoiceID
join Sales.Customers c on c.CustomerID = si.CustomerID
join Application.Cities ac on ac.CityID = c.PostalCityID
join Application.StateProvinces sp on sp.StateProvinceID = ac.StateProvinceID
join Application.Countries acs on acs.CountryID = sp.CountryID
group by c.CustomerID, ac.CityName, acs.CountryName, acs.Continent, acs.Region)
select top 5*
from cte1
order by TotalSpent desc 

--*Q7 Monthly Sales Report with Cumulative Totals and Annual Sub-totals (Rollup):
with cte1
as(
select year(si.InvoiceDate) as OrderYear,
month(si.InvoiceDate) as OrderMonth,
sum(sil.ExtendedPrice - sil.TaxAmount) as MonthlyTotal
from Sales.InvoiceLines sil join sales.Invoices si
on sil.InvoiceID = si.InvoiceID
group by year(si.InvoiceDate), month(si.InvoiceDate)),

cte2 as (
select orderyear, OrderMonth ,MonthlyTotal, sum(MonthlyTotal) 
over(partition by orderyear order by ordermonth ) as CumulativeTotal
from cte1)

select OrderYear , ISNULL(cast (OrderMonth as varchar(15)),'GrandTotal') OrderMonth, 
sum(MonthlyTotal) as MonthlyTotal, max(CumulativeTotal) as CumulativeTotal
from cte2
group by rollup(orderyear, OrderMonth)
having OrderYear is not null
order by OrderYear, CASE WHEN OrderMonth IS NULL THEN 13 ELSE OrderMonth END

--*Q8 Pivot Table showing Number of Orders by Month and Year (2013-2016):
with cte1 as(
select year(invoicedate) OrderYear, month(InvoiceDate) as OrderMonth, count(InvoiceID) as NumOfOrders
from sales.Invoices 
group by year(invoicedate), month(InvoiceDate))

select * 
from cte1
pivot(
sum(NumOfOrders)
for orderyear in ([2013],[2014],[2015],[2016])
) as PVT
order by ordermonth

--*Q9 Customer Churn Analysis - Flagging Potential Churn based on Order Intervals:
with cte1 as(
 select sc.CustomerID, sc.CustomerName,si.InvoiceDate as OrderDate,
 lag(si.InvoiceDate) 
 over(partition by sc.customerid order by max(si.InvoiceDate)) as PreOrderDate
 from Sales.Customers SC join sales.Invoices SI
 on sc.CustomerID = si.CustomerID
 group by  sc.CustomerID, sc.CustomerName,si.InvoiceDate ),

 cte2 as (
 select CustomerID,CustomerName, OrderDate,PreOrderDate,datediff(dd, PreOrderDate, Orderdate) as DaysSinceLastOrder
 from cte1
 where OrderDate is not null),

cte3 as(
select CustomerID, CustomerName, OrderDate,PreOrderDate,DaysSinceLastOrder,
avg(DaysSinceLastOrder) over(partition by customerid) as AvgDaysBetweenOrders
from cte2)

select *, case when ( DaysSinceLastOrder *2)> AvgDaysBetweenOrders then 'Potential Churn' 
else 'ACTIVE' end as CusCheck
from cte3
order by CustomerID,OrderDate, CustomerName,DaysSinceLastOrder, CUSCHECK 


--*Q10 Customer Category Distribution and Market Share Factor:  
with cte1 as (
select CustomerCategoryName, COUNT(distinct CustomerName) as CustomerCOUNT
from (select  scc.CustomerCategoryName,
case when sc.CustomerName like 'Tailspin%' then  'Tailspin'
when sc.CustomerName like 'Wingtip%' then 'Wingtip'
else sc.CustomerName
end as CustomerName
from Sales.Customers sc join Sales.CustomerCategories scc
on sc.CustomerCategoryID =scc.CustomerCategoryID ) c
group by CustomerCategoryName),

cte2 as(select CustomerCategoryName, CustomerCOUNT, SUM(CustomerCOUNT) over () as TotalCustCount
from cte1)

select CustomerCategoryName, CustomerCOUNT, TotalCustCount, 
FORMAT(CAST(CustomerCOUNT as float)/CAST(TotalCustCount as float), 'P') as DistributionFactor
from cte2
order by CustomerCategoryName
