/*Write a SQL query showing each category's share of total revenue with the following output columns:
category Product category from dim_products
total_revenue Total revenue for that category
overall_revenue Grand total revenue across ALL categories
pct_of_total Category revenue as % of overall, rounded to 2 decimals*/

WITH product_details AS (
    SELECT
        p.category,
        SUM(s.sales_amount) AS total_revenue
    FROM gold.fact_sales AS s
    JOIN gold.dim_products AS p
        ON s.product_key = p.product_key
    WHERE s.order_date IS NOT NULL
    GROUP BY p.category
)
SELECT
    category,
    total_revenue,
    SUM(total_revenue) OVER() AS overall_revenue,
    ROUND(total_revenue / NULLIF(SUM(total_revenue) OVER(), 0) * 100, 2) AS pct_of_total
FROM product_details
ORDER BY pct_of_total DESC

/*Write a SQL query showing each country's share of total revenue with the following output columns:
country Customer country from dim_customers
total_revenue Total revenue for that country
total_customers Distinct customers from that country
overall_revenue Grand total revenue across ALL countries
pct_of_total Country revenue as % of overall, rounded to 2 decimals
revenue_rank DENSE_RANK() — 1 = highest revenue country*/

WITH customer_analysis AS (
    SELECT
    c.country,
    SUM(s.sales_amount) AS total_revenue,
    COUNT(DISTINCT c.customer_key) AS total_customers
    FROM gold.fact_sales AS s
    JOIN gold.dim_customers AS c
    ON s.customer_key = c.customer_key
    WHERE s.order_date IS NOT NULL
    GROUP BY c.country
),
revenue_analysis AS (
    SELECT
    country,
    total_revenue,
    total_customers,
    SUM(total_revenue) OVER() AS overall_revenue,
    ROUND(total_revenue * 100 / NULLIF(SUM(total_revenue) OVER(),0) , 2) AS pct_of_total,
    DENSE_RANK() OVER(ORDER BY total_revenue DESC) AS revenue_rank
    FROM customer_analysis
)
SELECT
*
FROM revenue_analysis 
ORDER BY pct_of_total DESC


/*Write a SQL query showing revenue breakdown at both category and subcategory level with the following output columns:
category Product category subcategory Product subcategory
total_revenue Revenue for that subcategory
pct_of_total Subcategory revenue as % of ALL revenue — rounded to 2 decimals
pct_of_category Subcategory revenue as % of its own category — rounded to 2 decimals*/

WITH product_details AS (
    SELECT
    p.category,
    p.subcategory,
    SUM(s.sales_amount) AS total_revenue
    FROM gold.fact_sales AS s
    JOIN  gold.dim_products AS p
    ON s.product_key = p.product_key
    WHERE s.order_date IS NOT NULL
    GROUP BY p.category,
    p.subcategory
)
SELECT 
category,
subcategory,
total_revenue,
ROUND(total_revenue * 100.0 / NULLIF(SUM(total_revenue) OVER(), 0), 2) AS pct_of_total,
ROUND(total_revenue * 100.0 / NULLIF(SUM(total_revenue) OVER(PARTITION BY category), 0), 2) AS pct_of_category
FROM product_details
ORDER BY category, pct_of_category DESC

/*Write a SQL query showing each category's revenue share within each country with the following output columns:
country Customer country from dim_customers 
category Product category from dim_products 
total_revenue Revenue for that country + category combination
pct_of_country Category revenue as % of its own country's total
pct_of_total Category+country revenue as % of all revenue*/

WITH product_details AS(
    SELECT
    c.country,
    p.category,
    SUM(s.sales_amount) AS total_revenue
    FROM gold.fact_sales AS s
    JOIN gold.dim_customers AS c
    ON s.customer_key = c.customer_key
    JOIN gold.dim_products AS p
    ON s.product_key = p.product_key
    WHERE s.order_date IS NOT NULL
    GROUP BY c.country,
    p.category
)
SELECT
country,
category,
total_revenue,
CAST(total_revenue * 100/ NULLIF(SUM(total_revenue) OVER(PARTITION BY country), 0) AS DECIMAL(10,2)) AS pct_of_country,
CAST(total_revenue * 100/ NULLIF(SUM(total_revenue) OVER(), 0) AS DECIMAL(10,2)) AS pct_of_total
FROM product_details 
ORDER BY country, pct_of_country DESC

/*Write a SQL query building a complete part-to-whole report with the following output columns:
category Product category subcategory Product subcategory
country Customer country 
total_revenue Revenue for that combination
total_orders Distinct orders for that combination
pct_of_total% of grand total revenue
pct_of_category% within its own category
pct_of_country% within its own country
revenue_rank_overall DENSE_RANK() by revenue — global
revenue_rank_in_category DENSE_RANK() by revenue — within category*/

CREATE VIEW part_to_whole AS
WITH product_details AS(
    SELECT
    p.category,
    p.subcategory,
    c.country,
    SUM(s.sales_amount) AS total_revenue,
    COUNT(DISTINCT s.order_number) AS total_orders
    FROM gold.fact_sales AS s
    JOIN gold.dim_customers AS c
    ON s.customer_key = c.customer_key
    JOIN gold.dim_products AS p
    ON s.product_key = p.product_key
    WHERE s.order_date IS NOT NULL
    GROUP BY p.category,
    p.subcategory,c.country
   ),
   percentage_analysis AS (
       SELECT
       category,
       subcategory,
       country,
       total_revenue,
       total_orders,
       CAST(total_revenue *100.0/ NULLIF(SUM(total_revenue) OVER(), 0)AS DECIMAL(10,2)) AS pct_of_total,
       CAST(total_revenue *100.0/ NULLIF(SUM(total_revenue) OVER(PARTITION BY category), 0)AS DECIMAL(10,2)) AS pct_of_category,
       CAST(total_revenue *100.0/ NULLIF(SUM(total_revenue) OVER(PARTITION BY country), 0)AS DECIMAL(10,2)) AS pct_of_country
       FROM product_details 
   )

SELECT
* ,
DENSE_RANK() OVER(ORDER BY total_revenue DESC) AS revenue_rank_overall,
DENSE_RANK() OVER(PARTITION BY category ORDER BY total_revenue DESC) AS revenue_rank_in_category
FROM percentage_analysis
ORDER BY category, country, pct_of_country DESC  