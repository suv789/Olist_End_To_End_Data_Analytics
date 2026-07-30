/*
Marketing Analytical Insights
Dataset: Olist Marketing Funnel
Purpose:
Analyze seller acquisition funnel performance, lead conversion,
revenue quality, and post-acquisition operational outcomes
to support growth and marketing strategy decisions.
*/


SET search_path TO marketing;

select * from marketing.marketing_closed_deals;
select * from marketing.marketing_qualified_leads;

-- 1. Funnel overview
-- MQLs → Closed Deals (overall conversion rate)

SELECT
    COUNT(DISTINCT m.mql_id) AS total_mqls,
    COUNT(DISTINCT c.mql_id) AS closed_mqls,
    ROUND(
        COUNT(DISTINCT c.mql_id)::NUMERIC / NULLIF(COUNT(DISTINCT m.mql_id), 0), 4) AS mql_to_close_conversion_rate
FROM marketing.marketing_qualified_leads m
LEFT JOIN marketing.marketing_closed_deals c
    ON m.mql_id = c.mql_id;

-- 2. Funnel performance by lead origin

select * from marketing.marketing_closed_deals;

select 
	COALESCE(m.origin, 'unknown_origin') as origin,
	COUNT(DISTINCT m.mql_id) as total_mqls,
	COUNT(DISTINCT c.mql_id) as closed_mqls,
	ROUND(COUNT(DISTINCT c.mql_id)::NUMERIC / NULLIF(COUNT(DISTINCT m.mql_id), 0),4) as
	conversion_rate
from marketing.marketing_qualified_leads m
left join marketing.marketing_closed_deals c
	on m.mql_id = c.mql_id
group by COALESCE(m.origin, 'unknown_origin')
order by conversion_rate desc
;

--  Note: 'unknown' is a valid CRM value; NULL origins are labeled as 'unknown_origin'

-- 3. Revenue attribution by business type
select 
	business_type,
	count(*) as sellers_closed,
	round(sum(declared_monthly_revenue), 2) as total_declared_revenue,
	round(avg(declared_monthly_revenue), 2) as avg_declared_revenue
from marketing.marketing_closed_deals
group by business_type
order by total_declared_revenue desc;


-- 4. Seller quality indicators


select 
	COALESCE(has_company :: TEXT, 'unknown')as has_company,
	COUNT(*) AS sellers,
	ROUND(AVG(declared_monthly_revenue), 2) as avg_declared_revenue
from marketing.marketing_closed_deals
group by 
	COALESCE(has_company :: TEXT, 'unknown')
order by 
	avg_declared_revenue desc;


--5. Seller geography vs revenue
SELECT
    s.seller_state,
    COUNT(*) AS sellers,
    COALESCE(
        ROUND(
            AVG(
                CASE
                    WHEN c.declared_monthly_revenue > 0 THEN c.declared_monthly_revenue ELSE NULL END), 2), 0) AS avg_revenue
FROM marketing.marketing_closed_deals c
JOIN ecommerce.olist_sellers s
    ON c.seller_id = s.seller_id
GROUP BY s.seller_state
ORDER BY avg_revenue DESC;

-- 6. Seller acquisition quality vs delivery performance

SELECT
    c.business_type,
    ROUND(
        AVG(o.order_delivered_customer_date::DATE - o.order_purchase_timestamp::DATE), 2)
  AS avg_delivery_days
FROM marketing.marketing_closed_deals c
JOIN ecommerce.olist_order_items oi
    ON c.seller_id = oi.seller_id
JOIN ecommerce.olist_orders o
    ON oi.order_id = o.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY c.business_type
ORDER BY avg_delivery_days;
