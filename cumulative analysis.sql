--CUMULATIVE ANALYSIS 

/*Write a SQL query that shows monthly revenue with a running cumulative total with the following output columns:
order_year Year extracted from order_date 
order_month Month number (1–12)
total_revenue Revenue for that month 
cumulative_revenue Running total of revenue from the very first month up to current row*/

WITH monthly_revenue AS (
SELECT 
YEAR(s.order_date) AS order_year,
MONTH(s.order_date) AS order_month,
SUM(s.sales_amount) AS total_revenue
FROM gold.fact_sales AS s
WHERE s.order_date IS NOT NULL
GROUP BY YEAR(s.order_date), MONTH(s.order_date))

SELECT
order_year,
order_month,
total_revenue,
SUM(total_revenue) OVER(ORDER BY order_year, order_month) AS cumulative_revenue
FROM monthly_revenue
ORDER BY order_year, order_month

/*Extend your previous query to show running totals for all 4 metrics with the following output columns:
order_year Year extracted from order_date
order_month Month number (1–12)
total_revenue Revenue for that month
total_orders Distinct orders for that month
total_customers Distinct customers for that month
total_quantity Sum of quantity for that month
cumulative_revenue Running total of revenue
cumulative_orders Running total of orders 
cumulative_customers Running total of customers
cumulative_quantity Running total of quantity*/

WITH monthly_revenue AS (
SELECT
YEAR(s.order_date) AS order_year,
MONTH(s.order_date) AS order_month,
SUM(s.sales_amount) AS total_revenue,
COUNT(DISTINCT s.order_number) AS total_orders,
COUNT(DISTINCT s.customer_key) AS total_customers,
SUM(s.quantity) AS total_quantity
FROM gold.fact_sales AS s
WHERE s.order_date IS NOT NULL
GROUP BY YEAR(s.order_date), MONTH(s.order_date)
)

SELECT
order_year,
order_month,
total_revenue,
total_orders,
total_customers,
total_quantity,
SUM(total_revenue) OVER(ORDER BY order_year, order_month) AS cumulative_revenue,
SUM(total_orders) OVER(ORDER BY order_year, order_month) AS cumulative_orders,
SUM(total_customers) OVER(ORDER BY order_year, order_month) AS cumulative_customers,
SUM(total_quantity) OVER(ORDER BY order_year, order_month) AS cumulative_quantity
FROM monthly_revenue
ORDER BY order_year, order_month

/*Write a SQL query that shows monthly revenue with two cumulative columns — one that runs forever, and one that resets every January:
order_year Year extracted from order_date 
order_month Month number (1–12)
total_revenue Revenue for that month 
cumulative_revenue Running total from the very beginning never resets
cumulative_revenue_yearly Running total that resets to 0 at the start of each year*/

WITH monthly_revenue AS (
SELECT
YEAR(s.order_date) AS order_year,
MONTH(s.order_date) AS order_month,
SUM(s.sales_amount) AS total_revenue
FROM gold.fact_sales AS s
WHERE s.order_date IS NOT NULL
GROUP BY YEAR(s.order_date), MONTH(s.order_date)
)

SELECT
order_year,
order_month,
total_revenue,
SUM(total_revenue) OVER(ORDER BY order_year, order_month) AS cumulative_revenue,
SUM(total_revenue) OVER(PARTITION BY order_year ORDER BY order_month) AS cumulative_revenue_yearly
FROM monthly_revenue
ORDER BY order_year, order_month


/*Write a SQL query that shows cumulative revenue broken down by product category with the following output columns:
category Product category from dim_products 
order_year Year extracted from order_date
order_month Month number (1–12)
total_revenue Revenue for that category that month
cumulative_revenue Running total of revenue per category resets for each category*/


WITH monthly_category_analysis AS(
SELECT
YEAR(s.order_date) AS order_year,
MONTH(s.order_date) AS order_month,
SUM(s.sales_amount) AS total_revenue,
p.category AS category
FROM gold.fact_sales AS s
INNER JOIN gold.dim_products AS p
ON s.product_key = p.product_key
WHERE s.order_date IS NOT NULL
GROUP BY YEAR(s.order_date), MONTH(s.order_date), p.category
)
SELECT
order_year,
order_month,
total_revenue,
category,
SUM(total_revenue) OVER(PARTITION BY category ORDER BY order_year, order_month) AS cumulative_revenue
FROM monthly_category_analysis 
ORDER BY order_year, order_month, category

/*🔴 Challenge 5 of 5 — Final Cumulative Report (Boss Level 🏆)
All 3 tables, multiple CTEs, cumulative % — everything combined!
Your task:
Write a SQL query that builds a complete cumulative performance report with the following output columns:
order_year Year extracted from order_date
order_month Month number (1–12)
month_name Month name (January...)
category Product category from dim_products
total_revenue Revenue for that category that month
total_orders Distinct orders that month
total_customers Distinct customers that month
cumulative_revenue Running total of revenue per category
cumulative_revenue_yearly Running total that resets every year per category
pct_of_cumulative Current month revenue as % of its category's cumulative total, rounded to 2 decimals*/

CREATE VIEW gold.cumulative_analysis_report AS
WITH monthly_analysis AS (
SELECT
YEAR(s.order_date) AS order_year,
MONTH(s.order_date) AS order_month,
DATENAME(MONTH, s.order_date) AS month_name,
p.category AS category,
SUM(s.sales_amount) AS total_revenue,
COUNT(DISTINCT s.order_number) AS total_orders,
COUNT(DISTINCT s.customer_key) AS total_customers
FROM gold.fact_sales AS s
JOIN gold.dim_products AS p
ON s.product_key = p.product_key
JOIN gold.dim_customers AS c
ON c.customer_key = s.customer_key
WHERE s.order_date IS NOT NULL
GROUP BY YEAR(s.order_date),MONTH(s.order_date),DATENAME(MONTH, s.order_date),p.category
),

revenue_analysis AS(
SELECT
order_year,
order_month,
month_name,
category,
total_revenue,
total_orders,
total_customers,
SUM(total_revenue) OVER(PARTITION BY category ORDER BY order_year, order_month) AS cumulative_revenue,
SUM(total_revenue) OVER(PARTITION BY category,order_year ORDER BY order_month) AS cumulative_revenue_yearly
FROM monthly_analysis
)
SELECT 
order_year,
order_month,
month_name,
category,
total_revenue,
total_orders,
total_customers,
cumulative_revenue,
cumulative_revenue_yearly,
ROUND(
        (total_revenue) / NULLIF(cumulative_revenue, 0)*100, 2
    ) AS pct_of_cumulative
FROM revenue_analysis
