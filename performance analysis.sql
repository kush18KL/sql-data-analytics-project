/*Write a SQL query that ranks customers by total revenue and shows both top 10 and bottom 10 with the following output columns:
customer_key Customer identifier 
first_name From dim_customers
last_name From dim_customers
total_revenue Sum of sales_amount
revenue_rank Rank by revenue — 1 = highest
segment'Top 10' or 'Bottom 10' label*/

WITH customer_details AS (
	SELECT
	c.customer_key,
	c.first_name,
	c.last_name,
	SUM(s.sales_amount) AS total_revenue
	FROM gold.dim_customers AS c
	JOIN gold.fact_sales AS s
	ON s.customer_key = c.customer_key
	WHERE s.order_date IS NOT NULL
	GROUP BY c.customer_key, c.first_name, c.last_name
),
ranked_revenue AS (
	SELECT
	customer_key,
	first_name,
	last_name,
	total_revenue,
	DENSE_RANK() OVER(ORDER BY total_revenue DESC) AS revenue_rank,
	DENSE_RANK() OVER(ORDER BY total_revenue ASC) AS bottom_rank
	FROM customer_details
)

SELECT
customer_key,
first_name,
last_name,
total_revenue,
revenue_rank,
'Top 10' AS segment
FROM ranked_revenue
WHERE revenue_rank <= 10

UNION ALL

SELECT
customer_key,
first_name,
last_name,
total_revenue,
bottom_rank,
'Bottom 10' AS segment
FROM ranked_revenue
WHERE bottom_rank <= 10
ORDER BY segment DESC , revenue_rank ASC


/*Write a SQL query that ranks products by total revenue showing top 10 and bottom 10 with the following output columns:
product_key Product identifier 
product_name From dim_products 
category From dim_products
subcategory From dim_products
total_revenue Sum of sales_amount
total_orders Count of distinct order_number
revenue_rank Rank by revenue — 1 = highest
segment'Top 10' or 'Bottom 10' label*/

WITH product_details AS (
	SELECT
	p.product_key,
	p.product_name,
	p.category,
	p.subcategory,
	SUM(s.sales_amount) AS total_revenue,
	COUNT(DISTINCT s.order_number) AS total_orders
	FROM gold.dim_products AS p
	JOIN gold.fact_sales AS s
	ON s.product_key = p.product_key
	WHERE s.order_date IS NOT NULL
	GROUP BY p.product_key, 
	p.product_name,
	p.category,
	p.subcategory
),
ranked_revenue AS(
	SELECT
	product_key,
	product_name,
	category,
	subcategory,
	total_revenue,
	total_orders,
	DENSE_RANK() OVER(ORDER BY total_revenue DESC) AS revenue_rank,
	DENSE_RANK() OVER(ORDER BY total_revenue ASC) AS bottom_rank
	FROM product_details 
)

SELECT
	product_key,
	product_name,
	category,
	subcategory,
	total_revenue,
	total_orders,
	revenue_rank,
	'TOP 10' AS segment
FROM ranked_revenue
WHERE revenue_rank <= 10

UNION ALL

SELECT
	product_key,
	product_name,
	category,
	subcategory,
	total_revenue,
	total_orders,
	bottom_rank,
	'BOTTOM 10' AS segment
FROM ranked_revenue
WHERE bottom_rank <= 10
ORDER BY segment DESC, revenue_rank ASC

/*Write a SQL query that shows how each customer performs compared to the average customer revenue with the following output columns:
customer_key Customer identifier 
first_name From dim_customers
last_name From dim_customers
total_revenue Sum of sales_amount 
avg_revenue Average revenue across ALL customers, rounded to 2 decimals
revenue_vs_avg Difference between customer revenue and avg revenue
performance'Above Average', 'Below Average', or 'Average'*/

WITH customer_details AS (
	SELECT 
	c.customer_key,
	c.first_name,
	c.last_name,
	SUM(s.sales_amount) AS total_revenue
	FROM gold.dim_customers AS c
	JOIN gold.fact_sales AS s
	ON s.customer_key = c.customer_key
	WHERE s.order_date IS NOT NULL
	GROUP BY c.customer_key,c.first_name, c.last_name
),
revenue_avg AS (
	SELECT
	customer_key,
	first_name,
	last_name,
	total_revenue,
	ROUND(AVG(total_revenue) OVER(), 2) AS avg_revenue
	FROM customer_details 
)

SELECT
	customer_key,
	first_name,
	last_name,
	total_revenue,
	avg_revenue,
	total_revenue  - avg_revenue AS revenue_vs_avg,
	CASE	
		WHEN total_revenue > avg_revenue THEN 'Above Average'
		WHEN total_revenue < avg_revenue THEN 'Below Average'
		ELSE 'Average'
	END AS performance
FROM revenue_avg
ORDER BY total_revenue DESC

/*Write a SQL query that shows how each product performs compared to the average product revenue with the following output columns:
product_key Product identifier
product_name From dim_products
category From dim_products 
total_revenue Sum of sales_amount
total_orders Count of distinct order_number
avg_revenue_per_category Average revenue of products within the same category
revenue_vs_category_avg Difference between product revenue and its category average
performance'Above Average', 'Below Average', or 'Average'*/

WITH product_details AS (
	SELECT
	p.product_key,
	p.product_name,
	p.category,
	SUM(s.sales_amount) AS total_revenue,
	COUNT(DISTINCT s.order_number) AS total_orders
	FROM gold.dim_products AS p
	JOIN gold.fact_sales AS s
	ON p.product_key = s.product_key
	WHERE s.order_date IS NOT NULL
	GROUP BY p.product_key, p.product_name, p.category
),
product_avg   AS (
	SELECT
	product_key,
	product_name,
	category,
	total_revenue,
	total_orders,
	AVG(total_revenue) OVER(PARTITION BY category) AS avg_revenue_per_category
	FROM product_details
)

SELECT
product_key,
product_name,
category,
total_revenue,
total_orders,
avg_revenue_per_category,
total_revenue - avg_revenue_per_category AS revenue_vs_category_avg,
CASE 
	WHEN total_revenue > avg_revenue_per_category THEN 'Above Average'
	WHEN total_revenue < avg_revenue_per_category THEN 'Below Average'
	ELSE 'Average'
END AS performance
FROM product_avg  
ORDER BY category,total_revenue DESC

/*Write a SQL query that builds a complete customer performance report using all 3 tables with the following output columns:
customer_key Customer identifier
first_name From dim_customers
last_name From dim_customers
country From dim_customers
total_revenue Sum of sales_amount
total_orders Count of distinct order_number
total_products Count of distinct product_key
avg_order_value total_revenue / total_orders rounded to 2 decimals
revenue_rank DENSE_RANK() — 1 = highest revenue 
avg_revenue Global average revenue across all customers rounded to 2 decimals
performance'Above Average', 'Below Average', or 'Average'
customer_segment'VIP', 'Regular', 'New' based on rules below*/

CREATE VIEW Performance_Analysis AS
WITH customer_details AS (
	SELECT
	c.customer_key,
	c.first_name,
	c.last_name,
	c.country,
	SUM(s.sales_amount) AS total_revenue,
	COUNT(DISTINCT s.order_number) AS total_orders,
	COUNT(DISTINCT s.product_key) AS total_products
	FROM gold.fact_sales AS s
	JOIN gold.dim_products AS p
	ON s.product_key = p.product_key
	JOIN gold.dim_customers AS c
	ON c.customer_key = s.customer_key
	WHERE s.order_date IS NOT NULL
	GROUP BY c.customer_key,
	c.first_name,
	c.last_name,
	c.country
),
revenue_details AS(
	SELECT
	customer_key,
	first_name,
	last_name,
	country,
	total_revenue,
	total_orders,
	total_products,
	ROUND(total_revenue / NULLIF(total_orders,0),2)  AS  avg_order_value,
	DENSE_RANK() OVER(ORDER BY total_revenue DESC) AS revenue_rank,
	ROUND(AVG(total_revenue) OVER(),2) AS avg_revenue
	FROM customer_details
)

SELECT
	customer_key,
	first_name,
	last_name,
	country,
	total_revenue,
	total_orders,
	total_products,
	avg_order_value,
	revenue_rank,
	avg_revenue,
	CASE
		WHEN total_revenue > avg_revenue THEN 'Above Average'
		WHEN total_revenue < avg_revenue THEN 'Below Average'
		ELSE 'Average'
	END AS performance,

	CASE 
		WHEN revenue_rank <= 10 THEN 'VIP'
		WHEN total_orders <= 3 THEN 'New'
		ELSE 'Regural'
	END AS customer_segment
FROM revenue_details
 