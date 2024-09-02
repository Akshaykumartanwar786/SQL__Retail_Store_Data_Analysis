
------------------------DATA PREPARATION AND UNDERSTANDING----------------------------------

-- Q1 - What is the total number of rows in each of the 3 tables in the database?.

SELECT COUNT(*) AS [DATABASE] FROM Customer
UNION
SELECT COUNT(*) FROM prod_cat_info
UNION
SELECT COUNT(*) FROM Transactions


-- Q2 - What is the total number of transactions that have a return?.

SELECT COUNT(total_amt) AS RETURN_TRANSACTION_NO FROM Transactions
WHERE total_amt <0 ;

/* Q3 -  As you would have noticed, the dates provided across the datasets are not in a correct format.
As first steps, please convert the date variables into valid date formats before proceeding ahead.*/.

-- In new server of SSMS date convert into correct formate automatically 



/* Q4 - What is the time range of the transaction data available for analysis?
        Show the output in number of days, months, and years simultaneously in different columns?.*/

select distinct DATEDIFF(day,min(tran_date),max(tran_date)) as [days],
DATEDIFF(month, min(tran_date),max(tran_date)) as [months],
DATEDIFF(year, min(tran_date),max(tran_date)) as [years]
from Transactions


-- Q5 - Which product category does the sub-category “DIY” belong to?.

SELECT prod_cat
FROM prod_cat_info
WHERE prod_subcat = 'DIY'



----------------------------------------DATA ANALYSIS----------------------------------------------------

-- Q1 - Which channel is most frequently used for transactions?.

SELECT TOP 1 Store_type 
FROM Transactions 
GROUP BY Store_type
ORDER BY COUNT(QTY) DESC

-- Q2 - What is the count of Male and Female customers in the database?.

with m 
as (SELECT Gender, COUNT(GENDER) AS COUNT_OF_GENDER 
FROM Customer
WHERE Gender in( 'M','f')
GROUP BY Gender
),
f
as (SELECT Gender, COUNT(GENDER) AS COUNT_OF_MALE 
FROM Customer
WHERE Gender in ( select Gender from m )
GROUP BY Gender
)
select*from f

-- Q3 - From which city do we have the maximum number of customers and how many?.
SELECT TOP 1 city_code, COUNT(customer_Id) AS COUNT_CUST 
FROM Customer
GROUP BY city_code
ORDER BY COUNT(customer_Id) DESC
-------------------------------------------------------------------------------------------------------
SELECT TOP 1 city_code, COUNT(customer_Id) AS COUNT_CUST 
FROM Customer as c
join 
Transactions as t
on c.customer_Id = t.cust_id
GROUP BY city_code
ORDER BY COUNT(customer_Id) DESC 

-- Q4 - How many sub-categories are there under the Books category?.

SELECT count(prod_subcat) as count_category
FROM prod_cat_info
WHERE prod_cat = 'BOOKS'


-- Q5 - What is the maximum quantity of products ever ordered?.

SELECT TOP 1 prod_cat_code, sum(Qty) as total_qty
FROM Transactions
group by prod_cat_code
ORDER BY sum(Qty) DESC

-- Q6 - What is the net total revenue generated in categories Electronics and Books?.

SELECT distinct prod_cat, SUM(TOTAL_AMT) AS REVENUE FROM prod_cat_info AS P
JOIN
Transactions AS T
ON P.prod_sub_cat_code = T.prod_subcat_code
and 
t.prod_cat_code = p.prod_cat_code
WHERE prod_cat IN ('ELECTRONICS','BOOKS')
GROUP BY prod_cat

-- Q7 - How many customers have >10 transactions with us, excluding returns?.

SELECT COUNT(*) as no_customer FROM 
      (
        SELECT C.customer_Id, COUNT(T.transaction_id) NO_TRANS  FROM Customer AS C
        JOIN 
        Transactions AS T
        ON C.customer_Id = T.cust_id
        WHERE total_amt > 0
        GROUP BY C.customer_Id
        HAVING COUNT(T.transaction_id) > 10 
	   ) AS X

/* Q8 - What is the combined revenue earned from the “Electronics” & “Clothing” categories,
        from “Flagship stores”?.*/

SELECT Store_type, SUM(total_amt) COMBINE_REVENUE 
FROM Transactions AS T
JOIN 
prod_cat_info AS P
ON T.prod_subcat_code = P.prod_sub_cat_code
and 
t.prod_cat_code = p.prod_cat_code
WHERE P.prod_cat in ('ELECTRONICS', 'CLOTHING') and Store_type = 'flagship store' 
GROUP BY Store_type;


			
/* Q9 - What is the total revenue generated from “Male” customers in “Electronics” category?
        Output should display total revenue by product sub-category..*/

SELECT x.prod_subcat, x.REVENUE FROM (
             SELECT Gender, prod_subcat, SUM(total_amt) AS REVENUE FROM Transactions AS T
             INNER JOIN 
             prod_cat_info AS P
             ON T.prod_cat_code = P.prod_cat_code
             AND 
             T.prod_subcat_code = P.prod_sub_cat_code
             INNER JOIN 
             Customer AS C
             ON T.cust_id = C.customer_Id
             WHERE prod_cat IN ('ELECTRONICS') AND Gender = 'M' and total_amt > 0
             GROUP BY Gender, prod_subcat
			 ) AS X
			 WHERE X.Gender = 'M'

/* Q10 - What is the percentage of sales and returns by product sub-category; 
         display only the top 5 sub-categories in terms of sales?.*/

WITH SubCategorySales AS (
    SELECT prod_subcat
        ,
        SUM(CASE WHEN t.total_amt > 0 THEN t.total_amt ELSE 0 END) AS total_sales,
        SUM(CASE WHEN t.total_amt < 0 THEN t.total_amt ELSE 0 END) AS total_returns
    FROM 
        transactions as t
    JOIN 
        prod_cat_info as p 
		ON t.prod_cat_code = p.prod_cat_code
		and 
		t.prod_subcat_code = p.prod_sub_cat_code
    GROUP BY 
        prod_subcat
),
SubCategorySalesWithPercentages AS (
    SELECT 
        prod_subcat,
        total_sales,
        total_returns,
        (total_sales * 100.0 / (total_sales + total_returns)) AS sales_percentage,
        (total_returns * 100.0 / (total_sales + total_returns)) AS returns_percentage
    FROM 
        SubCategorySales
),
Top5SubCategories AS (
    SELECT 
        prod_subcat,
        total_sales,
        total_returns,
        sales_percentage,
        returns_percentage
    FROM 
        SubCategorySalesWithPercentages
    
)
SELECT 
    top 5 prod_subcat,
    total_returns,
    sales_percentage,
    returns_percentage
FROM 
    Top5SubCategories
	ORDER BY 
        total_sales DESC;


/* Q11 - For all customers aged between 25 to 35 years, 
         find what is the net total revenue generated by these consumers 
         in the last 30 days of transactions from the max transaction date available in the data?*/
with trans
as
(  select *
   from Transactions 
   where tran_date > DATEADD(day,-30,(select max(tran_date) from Transactions)) 
), age1
as 
(  select cust_id,sum(total_amt) as revenue, 
   DATEDIFF(year,c.DOB,max(tran_date)) as age 
   from Transactions as t
   join 
   Customer as c
   on t.cust_id = c.customer_Id
   where tran_date > DATEADD(day,-30,(select max(tran_date) from Transactions))  and total_amt > 0
   group by cust_id, c.DOB
   having DATEDIFF(year,c.DOB,max(tran_date)) between 25 and 35
)

select cust_id,age,revenue from age1
order by age asc


-- Q12 - Which product category has seen the max value of returns in the last 3 months of transactions?.

select x.prod_cat from (
              select top 1 prod_cat, sum(total_amt) as total_return
              from prod_cat_info as p
              join 
              Transactions as t
              on p.prod_cat_code = t.prod_cat_code
              and 
              p.prod_sub_cat_code = t.prod_subcat_code
              where tran_date > DATEADD(month,-3,(select max(tran_date) from transactions)) 
			  and total_amt < 0
              group by prod_cat
              order by total_return asc
			  ) x


-- Q13 - Which store-type sells the maximum products; by value of sales amount and by quantity sold?.

select store_type 
        from ( SELECT top 1 T.Store_type, SUM(T.total_amt) AS SALES, 
              SUM(T.Qty)AS QTY FROM prod_cat_info AS P
              INNER JOIN 
              Transactions AS T
              ON P.prod_cat_code = T.prod_cat_code
			  and 
			  p.prod_sub_cat_code = t.prod_subcat_code
              GROUP BY T.Store_type
              order by  SALES desc , Qty desc
			  ) as x 

-- Q14 - What are the categories for which average revenue is above the overall average?.

with ctg
as ( select prod_cat, avg(total_amt) as avg_revenue
     from prod_cat_info as p
     join 
     Transactions as t
	 on p.prod_cat_code = t.prod_cat_code
	 and 
	 p.prod_sub_cat_code = t.prod_subcat_code
	 group by prod_cat
	 ),
overall_avg
as ( select avg(total_amt) as overall_average
     from Transactions as t
	 join 
	 prod_cat_info as p
	 on t.prod_cat_code = p.prod_cat_code
	 and 
	 t.prod_subcat_code = p.prod_sub_cat_code
	 where prod_cat in ( select prod_cat from ctg)
	 )
select prod_cat, avg_revenue
from ctg as c
cross join
overall_avg as o
where avg_revenue > overall_average;

/* Q15 - Find the average and total revenue by each subcategory for the categories 
         which are among the top 5 categories in terms of quantity sold.. */ 

with top5
as ( select top 5 prod_cat, sum(Qty) as quantity
     from prod_cat_info as p
	 join 
	 Transactions as t
	 on p.prod_cat_code = t.prod_cat_code
	 and 
	 p.prod_sub_cat_code = t.prod_subcat_code
	 group by prod_cat
	 order by quantity desc
	 ),
sub_catt
as ( select prod_subcat, sum(total_amt) as total_revenue, avg(total_amt) as avg_revenue
     from prod_cat_info as p
	 join 
	 Transactions as t
	 on p.prod_cat_code = t.prod_cat_code
	 and 
	 p.prod_sub_cat_code = t.prod_subcat_code
	 where prod_cat in (select prod_cat from top5)
	 group by prod_subcat
	 )

select * from sub_catt	