/*
Normalize and load marketing funnel data from staging into analytical tables.
*/

INSERT INTO marketing.marketing_qualified_leads(

	mql_id,
	first_contact_date,
	landing_page_id,
	origin
)
SELECT 
	mql_id,
	first_contact_date :: DATE,
	landing_page_id,
	origin
FROM marketing.marketing_qualified_leads_staging;


INSERT INTO marketing.marketing_closed_deals(

	mql_id,
	seller_id,
	sdr_id,
	sr_id,
	won_date,
	business_segment,
    business_type,
    lead_type,
    lead_behaviour_profile,
    has_company,
    has_gtin,
    average_stock,
    declared_product_catalog_size,
    declared_monthly_revenue
)
SELECT 
	mql_id,
	seller_id,
	sdr_id,
	sr_id,
	won_date :: DATE,
	business_segment,
	business_type,
	lead_type,
	lead_behaviour_profile,

	CASE
		WHEN LOWER(has_company) IN ('true', 'yes', '1') THEN TRUE
		WHEN LOWER(has_company) IN ('false', 'no', '0') THEN FALSE
		ELSE NULL
	END AS has_company,

	CASE
		WHEN LOWER(has_gtin) IN ('true', 'yes', '1') THEN TRUE
		WHEN LOWER(has_gtin) IN ('false', 'no', '0') THEN FALSE
		ELSE NULL
	END AS has_gtin,

	average_stock,
	NULLIF(declared_product_catalog_size, '') :: NUMERIC,
	NULLIF(declared_monthly_revenue, '') :: NUMERIC
FROM marketing.marketing_closed_deals_staging;


-- I observed a data inserting error when data insert from the staging table to analytics table.
-- we also notice that some seller id not present in the ecomerce.olist_sellers table.
-- that using for the foreign key here in the marketing_closed_deals table.
-- so I decided that it will best to handle this type problem Drop the foreign key constraint.

select * from ecommerce.olist_sellers where seller_id = 'bbb7d7893a450660432ea6652310ebb7';

SELECT DISTINCT m.seller_id
FROM marketing.marketing_closed_deals_staging m
LEFT JOIN ecommerce.olist_sellers s
       ON m.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

-- find the foreign key constraint name
SELECT conname
FROM pg_constraint
WHERE conrelid = 'marketing.marketing_closed_deals'::regclass;

-- delete the constraint 
ALTER TABLE marketing.marketing_closed_deals
DROP CONSTRAINT marketing_closed_deals_seller_id_fkey;
