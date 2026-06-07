# SQL Data Analytics Project

A hands-on SQL analytics project using the **DataWithBaraa Gold Layer dataset** to practice real-world data analysis techniques in **SQL Server**. Built through a structured challenge-based learning approach — write the query, get scored, improve.

---

## Table of Contents
- [Project Overview](#project-overview)
- [Dataset](#dataset)
- [Database Schema](#database-schema)
- [How to Set Up](#how-to-set-up)
- [Analysis Modules](#analysis-modules)
- [Key SQL Concepts Covered](#key-sql-concepts-covered)
- [Golden Rules Learned](#golden-rules-learned)
- [Project Scores](#project-scores)
- [Author](#author)

---

## Project Overview

This project applies SQL to a real retail dataset across five analytics types:

| Module | Business Question | File |
|--------|-----------------|------|
| Change Over Time | How has revenue trended month by month and year by year? | `01_change_over_time.sql` |
| Cumulative Analysis | What are the running totals and YTD performance? | `02_cumulative_analysis.sql` |
| Performance Analysis | Who are the top/bottom customers and products? | `03_performance_analysis.sql` |
| Part to Whole | What % of total revenue does each category/country contribute? | `04_part_to_whole.sql` |
| Data Segmentation | How do we group customers and products into meaningful tiers? | `05_data_segmentation.sql` |

---

## Dataset

**Source:** [DataWithBaraa — SQL Data Analytics Project](https://github.com/DataWithBaraa/sql-data-analytics-project)

| Metric | Value |
|--------|-------|
| Total Revenue | ~$29.35 million |
| Total Transactions | ~60,000+ |
| Date Range | 2010 – 2014 |
| Unique Customers | 18,000+ |
| Unique Products | 500+ |

---

## Database Schema

Star schema with three tables in the `gold` schema:

```
gold.fact_sales          gold.dim_customers       gold.dim_products
-----------------        ------------------       -----------------
order_number             customer_key (PK)        product_key (PK)
product_key (FK)    -->  customer_id              product_id
customer_key (FK)   -->  first_name               product_name
order_date               last_name                category
shipping_date            country                  subcategory
due_date                 city                     cost
sales_amount             birthdate                product_line
quantity                 gender                   start_date
price                    create_date
```

---

## How to Set Up

### Step 1 — Clone the original dataset
```bash
git clone https://github.com/DataWithBaraa/sql-data-analytics-project.git
```

### Step 2 — Run warehouse scripts in SSMS
```
1. scripts/bronze/   → loads raw data
2. scripts/silver/   → cleans and transforms
3. scripts/gold/     → creates the final star schema
```

### Step 3 — Verify tables exist
```sql
SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'gold';
-- Expected: fact_sales, dim_customers, dim_products
```

### Step 4 — Run analysis scripts
Open any `.sql` file and run it in SSMS against your database.

---

## Analysis Modules

### Module 1 — Change Over Time
**File:** `01_change_over_time.sql`

Explores revenue trends across time dimensions:
- Yearly and monthly revenue trends
- Year-over-Year (YoY) comparison using `LAG()`
- Weekday analysis — best days for revenue
- 3-month rolling average
- Final view: `gold.report_change_over_time`

```sql
SELECT * FROM gold.report_change_over_time
ORDER BY order_year, order_month;
```

---

### Module 2 — Cumulative Analysis
**File:** `02_cumulative_analysis.sql`

Builds running totals and YTD metrics:
- Monthly running total for all 4 metrics
- Yearly reset cumulative (YTD) using `PARTITION BY`
- Cumulative by product category
- Cumulative % of total

---

### Module 3 — Performance Analysis
**File:** `03_performance_analysis.sql`

Ranks and benchmarks customers and products:
- Top 10 and Bottom 10 customers and products using `DENSE_RANK()`
- Customer and product performance vs average using `AVG() OVER()`
- Final report with VIP / Regular / New customer segments

---

### Module 4 — Part to Whole
**File:** `04_part_to_whole.sql`

Calculates revenue share across dimensions:
- Revenue % by product category
- Revenue % by country
- Nested % — subcategory within category
- Multi-dimension: country + category breakdown
- Final report with overall + within-group percentages

---

### Module 5 — Data Segmentation
**File:** `05_data_segmentation.sql`

Groups customers and products into meaningful tiers:

**Customer Segments:**
| Segment | Rule |
|---------|------|
| High Value | Revenue ≥ $5,000 |
| Mid Value | Revenue ≥ $1,000 |
| Champion | Lifespan ≥ 12 months AND orders ≥ 10 |
| Loyal | Lifespan ≥ 6 months AND orders ≥ 5 |
| Star | High Value + Champion |
| VIP | Top 10 by revenue |

**Product Segments:**
| Segment | Rule |
|---------|------|
| High Cost | Cost ≥ $500 |
| High Performer | Revenue ≥ $50,000 |

**Final Views:**
```sql
SELECT * FROM gold.report_customers_segmentation ORDER BY total_revenue DESC;
SELECT * FROM gold.report_products_segmentation ORDER BY total_revenue DESC;
```

---

## Key SQL Concepts Covered

| Concept | Modules Used |
|---------|-------------|
| `YEAR()`, `MONTH()`, `DATENAME()`, `DATEPART()` | 1 |
| `LAG()` window function | 1 |
| `SUM() OVER()` running total | 2 |
| `PARTITION BY` for grouped windows | 2, 3, 4 |
| `ROWS BETWEEN ... PRECEDING AND CURRENT ROW` | 1, 2 |
| `DENSE_RANK()` | 3, 4 |
| `AVG() OVER()` global and partitioned | 3 |
| `CAST(AS DECIMAL(10,2))` | 4 |
| `NULLIF()` safe division | 1, 2, 3, 4, 5 |
| `CASE WHEN` multi-condition | 5 |
| `DATEDIFF()` date calculations | 1, 5 |
| `UNION ALL` | 3 |
| `CREATE VIEW` | 1, 5 |
| CTEs (multiple chained) | All modules |
| 3-table JOINs | All modules |

---

## Golden Rules Learned

### 1. Always `COUNT(DISTINCT col)` for entities
```sql
-- Wrong — counts all rows
COUNT(order_number)
-- Correct — counts unique orders
COUNT(DISTINCT order_number)
```

### 2. Always `* 100.0` for percentages
```sql
-- Wrong — integer division gives 0
revenue * 100 / total
-- Correct — forces decimal math
revenue * 100.0 / total
```

### 3. Always `CAST(AS DECIMAL(10,2))` for output
```sql
-- Wrong — shows 12 trailing decimals
ROUND(value, 2)
-- Correct — clean 2 decimal output
CAST(value AS DECIMAL(10,2))
```

### 4. Window ORDER BY must be chronological — year first
```sql
-- Wrong — groups all Januaries across years together
AVG(revenue) OVER (ORDER BY order_month, order_year ...)
-- Correct — truly moves forward in time
AVG(revenue) OVER (ORDER BY order_year, order_month ...)
```

### 5. No `ORDER BY` inside SQL Server views
```sql
-- Wrong — throws SQL Server error
CREATE VIEW my_view AS SELECT * FROM table ORDER BY date;
-- Correct — apply ORDER BY when querying the view
SELECT * FROM my_view ORDER BY date;
```

### 6. Always `NULLIF(denominator, 0)` on every division
```sql
-- Safe division pattern
revenue / NULLIF(total_orders, 0)
```

---

## Project Scores

| Module | Avg Score | Key Lesson |
|--------|-----------|------------|
| 1 - Change Over Time | 8.1 / 10 | Window ORDER BY must be chronological |
| 2 - Cumulative Analysis | 8.5 / 10 | SUM() not COUNT() for running totals |
| 3 - Performance Analysis | 9.4 / 10 | DENSE_RANK() + AVG() OVER() |
| 4 - Part to Whole | 8.4 / 10 | * 100.0 + CAST for clean percentages |
| 5 - Data Segmentation | 7.3 / 10 | Unique aliases + correct column refs |
| **Overall** | **8.3 / 10** | Consistent intermediate-level SQL |

---

## Author

**kush18KL**
GitHub: [https://github.com/kush18KL](https://github.com/kush18KL)

Dataset credit: [DataWithBaraa](https://github.com/DataWithBaraa/sql-data-analytics-project)
