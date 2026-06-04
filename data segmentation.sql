/*Write a SQL query that groups customers into spend segments with the following output columns:
customer_key Customer identifier
first_name From dim_customers
last_name From dim_customers
total_revenue Sum of sales_amount 
spend_segment Category based on revenue 
'High Spender'    → total_revenue >= 5000
'Mid Spender'     → total_revenue >= 1000 AND < 5000
'Low Spender'     → total_revenue < 1000*/

WITH customer_details AS (
	SELECT
	s.customer_key,
	c.first_name,
	c.last_name,
	SUM(s.sales_amount) AS total_revenue
	FROM gold.fact_sales AS s
	LEFT JOIN gold.dim_customers AS c
	ON s.customer_key = c.customer_key
	WHERE s.order_date IS NOT NULL
	GROUP BY s.customer_key,
	c.first_name,
	c.last_name
)
	SELECT
	customer_key,
	first_name,
	last_name,
	total_revenue,
	CASE 
		WHEN total_revenue >= 5000 THEN 'High Spender'
		WHEN total_revenue >= 1000 AND total_revenue < 5000 THEN 'Mid spender'
		ELSE 'Low Spender'
	END AS spend_segment  
	FROM customer_details
	ORDER BY spend_segment


/*Write a SQL query that segments customers by how often they order with the following output columns:
customer_key Customer identifier
first_name From dim_customers
last_name From dim_customers
country From dim_customers
total_orders Count of distinct orders
lifespan_months Months between first and last order
engagement_segment Tier label based on rules below
Segmentation Rules:
'Champion'    → lifespan_months >= 12 AND total_orders >= 10
'Loyal'       → lifespan_months >= 6  AND total_orders >= 5
'At Risk'     → lifespan_months >= 6  AND total_orders < 5
'New'         → lifespan_months < 6*/

WITH customer_details AS (
	SELECT
	c.customer_key ,
	c.first_name,
	c.last_name,
	c.country,
	COUNT(DISTINCT s.order_number) AS total_orders,
	DATEDIFF(MONTH, MIN(s.order_date), MAX(s.order_date)) AS lifespan_months
	FROM gold.dim_customers AS c
	JOIN gold.fact_sales AS s
	ON c.customer_key = s.customer_key
	WHERE s.order_date IS NOT NULL
	GROUP BY c.customer_key ,
	c.first_name,
	c.last_name,
	c.country
)
SELECT
customer_key,
first_name,
last_name,
country,
total_orders,
lifespan_months,
CASE 
	WHEN lifespan_months >= 12 AND total_orders >= 10 THEN 'Champion'
	WHEN lifespan_months >= 6 AND total_orders >=5 THEN 'Loyal'
	WHEN lifespan_months >= 6 AND total_orders < 5 THEN 'At Risk'
	ELSE 'New'
END AS engagement_segment
FROM customer_details 
ORDER BY total_orders DESC

/*
Write a SQL query that segments products by their cost range and revenue performance with the following output columns:
product_key Product identifier
product_name From dim_products
category From dim_products
cost Product cost from dim_products
total_revenue Sum of sales_amount
total_orders Count of distinct order_number
cost_segment Label based on cost range
revenue_segment Label based on revenue performance
Cost Segmentation Rules:
'High Cost'    → cost >= 500
'Mid Cost'     → cost >= 100 AND < 500
'Low Cost'     → cost < 100
Revenue Segmentation Rules:
'High Performer'   → total_revenue >= 50000
'Mid Performer'    → total_revenue >= 10000 AND < 50000
'Low Performer'    → total_revenue < 10000*/

WITH product_details AS (
	SELECT
	p.product_key,
	p.product_name,
	p.category,
	p.cost,
	SUM(s.sales_amount) AS total_revenue,
	COUNT(DISTINCT s.order_number) AS total_orders
	FROM gold.dim_products AS p
	JOIN gold.fact_sales AS s
	ON p.product_key = s.product_key
	WHERE s.order_date IS NOT NULL
	GROUP BY 	p.product_key,
	p.product_name,
	p.category,
	p.cost
	)
	SELECT
	product_key,
	product_name,
	category,
	cost,
	total_revenue,
	total_orders,
	CASE
		WHEN cost >= 500 THEN 'High Cost'
		WHEN cost >= 100 AND cost < 500 THEN 'Mid Cost'
		ELSE 'Low Cost'
	END AS 'Cost_Segmentation',
	CASE
		WHEN total_revenue  >= 50000 THEN 'High Performer'
		WHEN total_revenue  >= 10000 AND total_revenue < 50000 THEN 'Mid Performer'
		ELSE 'Low Performer'
	END AS 'revenue_Segmentation'
	FROM product_details 
	ORDER BY total_revenue DESC

	/*
	Write a SQL query that combines both spend and engagement metrics to segment customers with the following output columns:
customer_key Customer identifier
first_name From dim_customers
last_name From dim_customers
country From dim_customers
total_revenue Sum of sales_amount
total_orders Count of distinct orders
lifespan_months Months between first and last order
spend_segment High Value / Mid Value / Low Value
engagement_segment Champion / Loyal / At Risk / New
customer_category Combined label based on both segments
Customer Category Rules:
'Star'      → spend = 'High Value'  AND engagement = 'Champion'
'Growth'    → spend = 'Mid Value'   AND engagement IN ('Loyal', 'Champion')
'Retention' → spend = 'High Value'  AND engagement = 'At Risk'
'Others'    → everything else*/
WITH customer_details AS (
	SELECT
	c.customer_key,
	c.first_name,
	c.last_name,
	c.country,
	SUM(s.sales_amount) AS total_revenue,
	COUNT(DISTINCT s.order_number) AS total_orders,
	DATEDIFF(MONTH, MIN(s.order_date), MAX(s.order_date)) AS lifespan_months
	FROM gold.dim_customers AS c
	JOIN gold.fact_sales AS s
	ON c.customer_key = s.customer_key 
	WHERE s.order_date IS NOT NULL
	GROUP BY c.customer_key,
	c.first_name,
	c.last_name,
	c.country
),
segmentation AS (
	SELECT
	customer_key,
	first_name,
	last_name,
	country,
	total_revenue,
	total_orders,
	lifespan_months,
	CASE	
		WHEN total_revenue >= 5000 THEN 'High Value'
		WHEN total_revenue >= 1000 AND total_revenue < 5000 THEN 'Mid Value'
		ELSE 'Low Value'
	END AS spend_segment,
	CASE 
		WHEN lifespan_months >= 12 AND total_orders >= 10 THEN 'Champion'
		WHEN lifespan_months >= 6 AND total_orders >=5 THEN 'Loyal'
		WHEN lifespan_months >= 6 AND total_orders < 5 THEN 'At Risk'
		ELSE 'New'
	END AS engagement_segment
	FROM customer_details 
)
SELECT
	customer_key,
	first_name,
	last_name,
	country,
	total_revenue,
	total_orders,
	lifespan_months,
	spend_segment,
	engagement_segment,
	CASE 
		WHEN spend_segment = 'High Value' AND engagement_segment = 'Champion' THEN 'Star'
		WHEN spend_segment = 'Mid Value' AND engagement_segment IN ('Loyal', 'Champion') THEN 'Growth'
		WHEN spend_segment = 'High Value' AND engagement_segment = 'At Risk' THEN 'Retention'
		ELSE 'Others'
	END AS customer_category 
FROM segmentation 
ORDER BY total_revenue DESC

/*customer_key Customer identifier
first_name From dim_customers
last_name From dim_customers
country From dim_customers
age Current age using DATEDIFF(YEAR, birthdate, GETDATE())
total_revenue Sum of sales_amount
total_orders Distinct orders
lifespan_months First to last order
spend_segment High / Mid / Low Value
engagement_segment Champion / Loyal / At Risk / New
customer_category Star / Growth / Retention / Others
age_group Young / Middle-aged / Senior
Age Group Rules:
'Young'        → age < 30
'Middle-aged'  → age >= 30 AND < 55
'Senior'       → age >= 55*/
CREATE VIEW customer_segmentation AS
WITH customer_details AS (
	SELECT
	c.customer_key,
	c.first_name,
	c.last_name,
	c.country,
	c.birthdate,
	DATEDIFF(YEAR, c.birthdate, GETDATE()) AS age,
	SUM(s.sales_amount) AS total_revenue,
	COUNT(DISTINCT s.order_number) AS total_orders,
	DATEDIFF(MONTH, MIN(s.order_date), MAX(s.order_date)) AS lifespan_months
	FROM gold.dim_customers AS c
	JOIN gold.fact_sales AS s
	ON c.customer_key = s.customer_key
	WHERE s.order_date IS NOT NULL
	GROUP BY c.customer_key,
	c.first_name,
	c.last_name,
	c.country,
	c.birthdate
),
segmenatation AS (
	SELECT
	customer_key,
	first_name,
	last_name,
	country,
	age,
	total_revenue,
	total_orders,
	lifespan_months,
	birthdate,
	CASE 
		WHEN total_revenue >= 5000 THEN 'High Value'
		WHEN total_revenue >= 1000 AND total_revenue < 5000 THEN 'Mid Value'
		ELSE 'Low Value'
	END AS spend_segment,
	CASE 
		WHEN lifespan_months >= 12 AND total_orders >= 10 THEN 'Champion'
		WHEN lifespan_months >= 6 AND total_orders >= 5 THEN 'Loyal'
		WHEN lifespan_months >= 6 AND total_orders < 5 THEN 'At Risk'
		ELSE 'New'
	END AS engagement_segment	
	FROM customer_details 
),
Categorization AS (
	SELECT
	*,
		CASE 
		WHEN spend_segment = 'High Value' AND engagement_segment = 'Champion' THEN 'Star'
		WHEN spend_segment = 'Mid Value' AND engagement_segment IN ('Loyal', 'Champion') THEN 'Growth'
		WHEN spend_segment = 'High Value' AND engagement_segment = 'At Risk' THEN 'Retention'
		ELSE 'Others'
	END AS customer_category,
	CASE 
		WHEN age < 30 THEN 'Young'
		WHEN age >= 30 AND age < 55 THEN 'Middle-aged'
		ELSE 'Senior'
	END AS age_group
	FROM segmenatation
)
SELECT
*
FROM Categorization;

/*product_key Product identifier 
product_name From dim_products
category From dim_products
cost From dim_products
total_revenue Sum of sales_amount
total_orders Distinct orders
total_customers Distinct customers
cost_segment High / Mid / Low cost
revenue_segment High / Mid / Low Performer*/

CREATE VIEW product_segmentation AS 
WITH product_details AS(
	SELECT
	p.product_key,
	p.product_name,
	p.category,
	p.cost,
	SUM(s.sales_amount) AS total_revenue,
	COUNT(DISTINCT s.order_number) AS total_orders,
	COUNT(DISTINCT s.customer_key) AS total_customers
	FROM gold.dim_products AS p
	JOIN gold.fact_sales AS s
	ON p.product_key = s.product_key
	WHERE s.order_date IS NOT NULL
	GROUP BY 
	p.product_key,
	p.product_name,
	p.category,
	p.cost
),
segment AS (
	SELECT
	product_key,
	product_name,
	category,
	cost,
	total_revenue,
	total_orders,
	total_customers,
	CASE
		WHEN cost >= 500 THEN 'High Cost'
		WHEN cost >= 100 AND cost < 500 THEN 'Mid Cost'
		ELSE 'Low Cost'
	END AS Cost_Segmentation,
	CASE
		WHEN total_revenue  >= 50000 THEN 'High Performer'
		WHEN total_revenue  >= 10000 AND total_revenue < 50000 THEN 'Mid Performer'
		ELSE 'Low Performer'
	END AS revenue_segment
	FROM product_details 
)
SELECT
*
FROM segment
ORDER BY total_revenue DESC