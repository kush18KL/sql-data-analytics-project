/*Write a SQL query on gold.fact_sales that shows year-wise performance with the following output columns:
order_year The year extracted from order_date
total_revenue Sum of sales_amount 
total_orders Count of distinct order_number 
total_customers Count of distinct customer_key 
total_quantity Sum of quantity*/

SELECT
YEAR(s.order_date) AS Order_year,
SUM(s.sales_amount) AS total_revenue,
COUNT(DISTINCT s.order_number) AS total_orders,
COUNT(DISTINCT s.customer_key) AS total_customers,
SUM(s.quantity) AS total_quantity
FROM gold.fact_sales AS s
WHERE s.order_date IS NOT NULL
GROUP BY YEAR(s.order_date)
ORDER by YEAR(s.order_date)

/*Write a SQL query on gold.fact_sales that shows month-wise performance with the following output columns:
order_year Year extracted from order_date 
order_month Month as a number (1–12)
month_name Month as a name (January, February...)
total_revenue Sum of sales_amount 
total_orders Count of distinct order_number
total_customers Count of distinct customer_key*/

SELECT
YEAR(s.order_date) AS order_year,
MONTH(s.order_date) AS order_month,
DATENAME(MONTH, s.order_date) AS month_name,
SUM(s.sales_amount) AS total_revenue,
COUNT(DISTINCT s.order_number) AS total_orders,
COUNT(DISTINCT s.customer_key) AS total_customers
FROM gold.fact_sales AS s
WHERE s.order_date IS NOT NULL
GROUP BY YEAR(s.order_date), MONTH(s.order_date),DATENAME(MONTH, s.order_date)
ORDER BY YEAR(s.order_date), MONTH(s.order_date)


/*Write a SQL query that shows yearly revenue and compares each year to the previous year with the following output columns:

order_year Year extracted from order_date 
total_revenue Sum of sales_amount 
prev_year_revenue Previous year's total revenue using LAG()
yoy_change Difference between current and previous year revenue 
yoy_pct_change % change vs previous year, rounded to 2 decimals*/

SELECT 
    YEAR(s.order_date) AS order_year,
    SUM(s.sales_amount) AS total_revenue,
    LAG(SUM(s.sales_amount)) OVER (ORDER BY YEAR(s.order_date)) AS prev_year_revenue,
    SUM(s.sales_amount) - LAG(SUM(s.sales_amount)) OVER (ORDER BY YEAR(s.order_date)) AS yoy_change,
    ROUND(
        (SUM(s.sales_amount) - LAG(SUM(s.sales_amount)) OVER (ORDER BY YEAR(s.order_date))) 
        / LAG(SUM(s.sales_amount)) OVER (ORDER BY YEAR(s.order_date)) * 100, 
        2
    ) AS yoy_pct_change
FROM gold.fact_sales AS s
WHERE s.order_date IS NOT NULL
GROUP BY YEAR(s.order_date)
ORDER BY YEAR(s.order_date)

/*Write a SQL query that shows which days of the week generate the most revenue with the following output columns:
weekday_number Day of week as a number(1=Sunday, 7=Saturday)
weekday_name Day name (Monday, Tuesday...)
total_revenue Sum of sales_amount 
total_orders Count of distinct order_number 
avg_revenue_per_order Average revenue per order, rounded to 2 decimals*/

SELECT
DATEPART(WEEKDAY, s.order_date) AS weekday_number,
DATENAME(WEEKDAY, s.order_date) AS weekday_name,
SUM(s.sales_amount) AS total_revenue,
COUNT(DISTINCT s.order_number) AS total_orders,
ROUND(SUM(s.sales_amount) / COUNT(DISTINCT s.order_number), 2) AS avg_revenue_per_order
FROM gold.fact_sales AS s
WHERE s.order_date IS NOT NULL
GROUP BY DATEPART(WEEKDAY, s.order_date),
DATENAME(WEEKDAY, s.order_date)
ORDER BY weekday_number

SELECT
    DATEPART(WEEKDAY, s.order_date) AS weekday_number,
    DATENAME(WEEKDAY, s.order_date) AS weekday_name,
    SUM(s.sales_amount) AS total_revenue,
    COUNT(DISTINCT s.order_number) AS total_orders,
    ROUND(SUM(s.sales_amount) / COUNT(DISTINCT s.order_number), 2) AS avg_revenue_per_order
FROM gold.fact_sales AS s
WHERE s.order_date IS NOT NULL
GROUP BY 
    DATEPART(WEEKDAY, s.order_date),
    DATENAME(WEEKDAY, s.order_date)
ORDER BY weekday_number;


/*Write a SQL query that shows monthly revenue with a 3-month rolling average using the following output columns:
order_year Year extracted from order_date 
order_month Month number (1–12) 
total_revenue Sum of sales_amount for that month 
rolling_avg_3month Average of current month + 2 previous months, rounded to 2 decimals*/

WITH monthly_revenue AS (
select
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
ROUND(AVG(total_revenue) OVER(ORDER BY order_year, order_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS rolling_avg_3month
FROM monthly_revenue
ORDER BY order_year, order_month 

/*Write a SQL query that builds a complete monthly performance report with the following output columns:
order_year Year extracted from order_date
order_month Month number 
month_name Month name (January...)
total_revenue Sum of sales_amount 
total_orders Count of distinct order_number
total_customers Count of distinct customer_key
prev_month_revenue Previous month's revenue using LAG()
mom_change Month-over-month revenue difference
mom_pct_change MoM % change rounded to 2 decimals 
rolling_avg_3month 3-month rolling average rounded to 2 decimals
*/
CREATE VIEW gold.report_customers AS
WITH monthly_performance AS (
SELECT
YEAR(s.order_date) AS order_year,
MONTH(s.order_date) AS order_month,
DATENAME(MONTH, s.order_date) AS month_name,
SUM(s.sales_amount) AS total_revenue,
COUNT(DISTINCT s.order_number) AS total_orders,
COUNT(DISTINCT s.customer_key) AS total_customers
FROM gold.fact_sales AS s
WHERE s.order_date IS NOT NULL
GROUP BY YEAR(s.order_date),
MONTH(s.order_date), DATENAME(MONTH, s.order_date)
),

month_to_month_analysis AS (
SELECT
order_year,
order_month,
month_name,
total_revenue,
total_orders,
total_customers,
LAG(total_revenue) OVER(ORDER BY order_year, order_month) AS prev_month_revenue,
total_revenue - LAG(total_revenue) OVER(ORDER BY order_year, order_month) AS mom_change,
ROUND((total_revenue - LAG(total_revenue) OVER(ORDER BY order_year, order_month)) / 
    NULLIF(LAG(total_revenue) OVER(ORDER BY order_year, order_month), 0) * 100, 2) AS mom_pct_change,
ROUND(AVG(total_revenue) OVER(ORDER BY order_year, order_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),2) AS rolling_avg_3month
FROM monthly_performance
)
SELECT * 
FROM month_to_month_analysis
