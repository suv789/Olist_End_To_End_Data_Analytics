# Ecommerce Analytical Insights
## Olist Brazilian E-Commerce Dataset - SQL Analysis

This document presents the business analysis and analytical insights derived from the Olist Brazilian E-commerce dataset.
The analysis is performed after data quality validation and star schema modeling, with each section answering a concrete
business question using SQL.


### How to read this analysis

Each section answers a specific business question using SQL.
The queries are written for analytical exploration, not data cleaning.
All metrics are derived from validated analytical tables following a star schema design.

## A. Customer & Geography Analysis

### 1. Which states have the highest number of customers?
Understanding customer distribution helps identify high-demand regions and target markets.
This query counts distinct customers per state and ranks states based on customer volume.
```
select customer_state, count(distinct customer_unique_id) as occurrences
from olist_customers
group by customer_state
order by occurrences desc;
```

### 2. Which cities generate the most orders?

This helps determine which cities drive the most sales, useful for logistics and regional marketing.
The query joins customers with orders and aggregates order counts by city.
```
select c.customer_city, count(o.order_id) as order_count
from olist_customers  c
join olist_orders o
    on c.customer_id = o.customer_id
group by c.customer_city 
order by order_count desc;
```

### 3. What % of customers return for repeat purchases?

Repeat customers are crucial for long-term revenue.
This query identifies how many unique customers placed more than one order and calculates their percentage.
```
with order_counts as (
    select customer_unique_id, count(order_id) as order_count
    from olist_orders o
    join olist_customers c
        on c.customer_id = o.customer_id
    group by customer_unique_id	
)
select 
    round(count(case when order_count > 1 then 1 end) * 100.00 / count(*), 2) 
        as repeat_customer_percentage
from order_counts;
```

### 4. What is the average number of orders per customer?

This metric helps estimate customer purchasing behavior and engagement.
The query calculates the average number of orders grouped by customer.
```
select round(avg(order_count), 2) as avg_no_of_orders
from (
    select customer_id, count(order_id) as order_count 
    from olist_orders 
    group by customer_id
) s;
```

### 5. Which states contribute the highest revenue?

Identifying revenue-heavy regions helps prioritize supply chain and delivery resources.
The query aggregates total item prices across orders by customer state.
```
select c.customer_state, sum(oi.price) as total_revenue
from olist_customers  c
join olist_orders o
    on c.customer_id = o.customer_id
join olist_order_items oi
    on o.order_id = oi.order_id
group by c.customer_state
order by total_revenue desc;
```

### 6. Top 10 highest spending customers (Customer Lifetime Value)

CLV helps businesses understand their most valuable customers.
This query sums total spending per customer and returns the top 10.
```
select c.customer_unique_id, sum(oi.price) as customer_spending
from olist_customers  c
join olist_orders o
    on c.customer_id = o.customer_id
join olist_order_items oi
    on o.order_id = oi.order_id
group by c.customer_unique_id
order by customer_spending desc
limit 10;
```

## B. Order & Logistics Performance

### 1. What is the average time from purchase to delivery?

Delivery time is a key metric for logistics efficiency.
This query computes the average duration between order placement and delivery.
```
select 
    date_trunc('day', avg(order_delivered_customer_date - order_purchase_timestamp)) as avg_days
from olist_orders;
```












































