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

### 2. What is the difference between estimated and actual delivery?
This helps measure delivery accuracy and customer experience.
The query returns delays or early deliveries for every order.
```
select 
    order_id, 
    order_delivered_customer_date, 
    order_estimated_delivery_date,
    (order_delivered_customer_date - order_estimated_delivery_date) as estimate_and_actual_diff
from olist_orders;
```

### 3. How many orders were delivered late?
Late deliveries directly impact customer satisfaction.
This query counts all orders delivered after the estimated delivery date.
```
select count(order_id)
from olist_orders
where order_delivered_customer_date > order_estimated_delivery_date;
```

### 4. How long do deliveries actually take vs estimates?

This query prepares delivery duration metrics used for SLA and delay analysis.
It computes actual delivery days and compares them with estimated delivery timelines.
```
select
    order_id,
    order_purchase_timestamp,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    (order_delivered_customer_date - order_purchase_timestamp) as actual_delivery_days,
    (order_estimated_delivery_date - order_purchase_timestamp) as estimated_delivery_days
from olist_orders
where order_delivered_customer_date is not null;
```

### 5. Which sellers have the best delivery performance?
This identifies sellers who ship quickly, helping improve marketplace quality.
The query calculates average shipping time between approval and carrier pickup.
```
select 
    oi.seller_id,
    date_trunc('second', avg(o.order_delivered_carrier_date - o.order_approved_at)) as avg_shipping_days
from olist_orders o
join olist_order_items oi
    on o.order_id = oi.order_id
where o.order_delivered_carrier_date is not null
  and o.order_approved_at is not null
  and o.order_delivered_carrier_date >= o.order_approved_at
group by oi.seller_id
order by avg_shipping_days;
```

### 6. Which sellers have the worst delivery delays?
Slow sellers impact overall marketplace ratings and logistics cost.
This query lists sellers with the longest average shipping duration.
```
select 
    oi.seller_id,
    date_trunc('second', avg(o.order_delivered_carrier_date - o.order_approved_at)) as avg_shipping_days
from olist_orders o
join olist_order_items oi
    on o.order_id = oi.order_id
where o.order_delivered_carrier_date is not null
  and o.order_approved_at is not null
  and o.order_delivered_carrier_date >= o.order_approved_at
group by oi.seller_id
order by avg_shipping_days desc;
```

### 7. Which states experience the slowest deliveries?
Delivery time varies by geography due to distance and logistics capacity.
This query calculates average delivery times per state.
```
select 
    c.customer_state, 
    date_trunc('second', avg(o.order_delivered_customer_date - o.order_purchase_timestamp)) 
        as avg_delivery_days
from olist_customers c
left join olist_orders o
    on o.customer_id = c.customer_id
where o.order_delivered_customer_date is not null
group by c.customer_state
order by avg_delivery_days desc;
```

### 8. What is the distribution of delivery times per category?
Some product types take longer to prepare or ship.
This query analyzes delivery speed across product categories.
```
select 
    p.product_category_name,
    date_trunc('second', avg(o.order_delivered_customer_date - o.order_purchase_timestamp))
        as avg_delivery_duration
from olist_orders o
join olist_order_items oi 
    on o.order_id = oi.order_id
join olist_products p
    on p.product_id = oi.product_id
where o.order_delivered_customer_date is not null
group by p.product_category_name
order by avg_delivery_duration;
```

## C. Product & Category Analytics

### 1. Which product categories sell the most units?

Understanding unit sales by category helps businesses identify popular product segments.
This query counts the number of items sold per category and ranks them from highest to lowest.
```
select 
    p.product_category_name,
    pct.product_category_name_english,
    count(*) as units_sold
from olist_order_items oi
join olist_products p
    on oi.product_id = p.product_id
left join product_category_name_translation pct
    on p.product_category_name = pct.product_category_name
group by p.product_category_name, pct.product_category_name_english
order by units_sold desc;
```






















































