/*
E-commerce Data Validation Checks
Dataset: Olist Brazilian E-Commerce
Purpose: Validate data integrity, completeness, and logical consistency
before analytical use.
*/

SET search_path to ecommerce;

/* 
   OLIST CUSTOMERS 
   Dataset: olist_customers_dataset.csv
   Table: olist_customers
   Purpose: Basic quality checks before analysis
*/

-- Total row count
select 
	count(*) 
from ecommerce.olist_customers;


-- Null value checks 
SELECT 
	 SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS cutomers_id_null,
	 SUM(CASE WHEN customer_unique_id IS NULL THEN 1 ELSE 0 END) AS customer_unique_id_null,
	 SUM(CASE WHEN customer_zip_code_prefix IS NULL THEN 1 ELSE 0 END) AS customer_zip_code_null,
	 SUM(CASE WHEN customer_city IS NULL THEN 1 ELSE 0 END) AS customer_city_null,
	 SUM(CASE WHEN customer_state IS NULL THEN 1 ELSE 0 END) AS customer_state_null
FROM ecommerce.olist_customers;

/* DUPLICATE CHECK USING CUSTOMER_ID 
(Customer can have multiple orders, so duplicates ARE expected.We DO NOT delete them.) */

SELECT 
	customer_id,
	count(*) as occurenceces
FROM ecommerce.olist_customers
GROUP BY customer_id
HAVING count(*) > 1 ;

-- Unique city and state count
SELECT 
	 COUNT(DISTINCT customer_city) as unique_cities,
	 COUNT(DISTINCT customer_state) as unique_states
FROM ecommerce.olist_customers;

-- CHECK For invalid state code (must be in 2 letters)
SELECT 
	customer_state
FROM ecommerce.olist_customers
WHERE LENGTH(customer_state) > 2;

-- Check for City name that starting with numbers
SELECT 
	customer_city
FROM ecommerce.olist_customers
WHERE customer_city IS NULL
	OR customer_city = ''
	OR customer_city ~ '^[0-9]' -- starts with digits
	OR customer_city ~ '[0-9]$' -- ends with digits
	OR customer_city ~ '[[:alpha:]]+[0-9]+' -- letters followed by digits
	OR customer_city ~ '[0-9]+[[:alpha:]]+' -- digits followed by letters
	OR customer_city ~ '[^[:alpha:]À-ÿ 0-9\-'']' -- invalid characters
	OR customer_city ~ '^\s' -- leading whitespace
	OR customer_city ~ '\s$' -- tralling whitespace
	;

-- 
/*
    OLIST ORDERS 
    Dataset: olist_orders_dataset.csv
    Table: olist_orders
    Purpose: Validate timestamps, missing values, and logical consistency
*/

SELECT 
	* 
FROM ecommerce.olist_orders;

-- Total row count
select count(*) from ecommerce.olist_orders;

-- Null value checks per column
SELECT 
	SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS order_id_nulls,
	SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS customer_id_nulls,
	SUM(CASE WHEN order_status IS NULL THEN 1 ELSE 0 END) AS order_status_nulls,
	SUM(CASE WHEN order_purchase_timestamp IS NULL THEN 1 ELSE 0 END) AS order_purchase_timestamp_nulls,
	SUM(CASE WHEN order_approved_at IS NULL THEN 1 ELSE 0 END) AS order_approved_at_nulls,
	SUM(CASE WHEN order_delivered_carrier_date IS NULL THEN 1 ELSE 0 END) AS carrier_date_nulls,
    SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS delivered_date_nulls,
    SUM(CASE WHEN order_estimated_delivery_date IS NULL THEN 1 ELSE 0 END) AS estimated_date_nulls
FROM ecommerce.olist_orders;

/* 
Interpretation:
	- Missing order_approved_at: customer placed the order but payment approval delayed.
	- Missing delivery dates: common for canceld or undelivered order.
	- Missing carrier data : shipment never handed to carrier.
*/

-- check for duplicate order id
SELECT 
	 order_id,
	 count(*) as occurrences
FROM ecommerce.olist_orders
GROUP BY order_id
HAVING count(*) > 1;

-- Timestamps logic checks - these identify impossible or suspicious dates

-- a. Approval date before purchase date -> Invalid
SELECT 
	*
FROM ecommerce.olist_orders
WHERE order_approved_at < order_purchase_timestamp;

-- b. customer delivery earlier than approval -> Invalid (can be manged based on cliend requirement)
SELECT
	*
FROM ecommerce.olist_orders
WHERE order_delivered_carrier_date < order_approved_at;

-- c. Delivered AFTER estimated deliver -> late deliveries

SELECT *
FROM ecommerce.olist_orders
WHERE order_delivered_customer_date > order_estimated_delivery_date;
	
-- d. Delivered BEFORE the carrier even received the package -> INVALID 
SELECT *
FROM ecommerce.olist_orders
WHERE order_delivered_customer_date < order_delivered_carrier_date;

-- STAUS Consistency check
-- Orders marked as "delivered" but missing delivered date 

SELECT 
	*
FROM ecommerce.olist_orders
WHERE
	 order_status = 'delivered'
AND  order_delivered_customer_date IS NULL;


-- Orders marked as "canceled" but have delivery date (impossible)

SELECT 
	* 
FROM ecommerce.olist_orders
WHERE
	order_status = 'canceled'
AND order_delivered_customer_date IS NOT NULL;


/*
    OLIST ORDER ITEMS
    Dataset: olist_order_items_dataset.csv
    Table: olist_order_items
    Purpose: Validate product-level order details, shipping dates, and pricing integrity
*/

-- Total row count

SELECT count(*) FROM ecommerce.olist_order_items;



-- Null value checks
SELECT
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS order_id_nulls,
    SUM(CASE WHEN order_item_id IS NULL THEN 1 ELSE 0 END) AS order_item_id_nulls,
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS product_id_nulls,
    SUM(CASE WHEN seller_id IS NULL THEN 1 ELSE 0 END) AS seller_id_nulls,
    SUM(CASE WHEN shipping_limit_date IS NULL THEN 1 ELSE 0 END) AS shipping_limit_nulls,
    SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) AS price_nulls,
    SUM(CASE WHEN freight_value IS NULL THEN 1 ELSE 0 END) AS freight_nulls
FROM ecommerce.olist_order_items;


/*
 Interpretation:
 - NULL for price and freight_value should not happen; flag for quality check.
 - Missing shipping_limit_date indicates missing SLA.
*/



-- check for duplicates (order_id and order_item_id must be UNIQUE)

SELECT
	order_id,
	order_item_id,
	count(*) as occurrences
FROM ecommerce.olist_order_items
GROUP BY 
	order_id,
	order_item_id
HAVING count(*) > 1;

-- PRICE CHECKS

-- Zero or nagative prices, freight values

SELECT * 
FROM ecommerce.olist_order_items 
WHERE price <= 0 or freight_value <= 0;


-- SHIPPING LIMIT Consistency
-- shipping_limit_date should be After order purchase date

SELECT oi.* , o.order_purchase_timestamp
FROM ecommerce.olist_order_items oi
JOIN ecommerce.olist_orders o
ON oi.order_id = o.order_id
WHERE oi.shipping_limit_date < o.order_purchase_timestamp;

-- PRICE vs FREIGHT sanity check
-- Freight price should not exceed product price except rare cases

SELECT * 
FROM ecommerce.olist_order_items
WHERE freight_value > price;


-- Product Repeat Purchase check 

SELECT 
	product_id,
	count(*) as total_items_sold
FROM ecommerce.olist_order_items
GROUP BY 
	product_id
ORDER BY total_items_sold DESC;

/* 
DATA QUALITY SUMMARY 
1. No NULL prices or freight values -> Good data quality
2. No duplicate (order_id + order_item_id) combinations -> Good
3. 4,124 rows where freight_value > price:
      - Legit scenario due to logistics cost > item cost
      - To be treated as outliers only in pricing visualizations
4. Checked for repeated purchased product
*/

--------

/*
    OLIST PRODUCTS
    Dataset: olist_products_dataset.csv
    Table: olist_products
    Purpose: Validate product metadata (dimensions, weight, category, and missing values)
*/

-- Total row count
SELECT COUNT(*)
FROM ecommerce.olist_products;

-- Null value checks
SELECT
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS product_id_nulls,
    SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) AS category_nulls,
    SUM(CASE WHEN product_name_length IS NULL THEN 1 ELSE 0 END) AS category_name_length_nulls,
    SUM(CASE WHEN product_description_length IS NULL THEN 1 ELSE 0 END) AS description_length_nulls,
    SUM(CASE WHEN product_photos_qty IS NULL THEN 1 ELSE 0 END) AS photos_nulls,
    SUM(CASE WHEN product_weight_g IS NULL THEN 1 ELSE 0 END) AS weight_nulls,
    SUM(CASE WHEN product_length_cm IS NULL THEN 1 ELSE 0 END) AS length_nulls,
    SUM(CASE WHEN product_height_cm IS NULL THEN 1 ELSE 0 END) AS height_nulls,
    SUM(CASE WHEN product_width_cm IS NULL THEN 1 ELSE 0 END) AS width_nulls
FROM ecommerce.olist_products;


/*
 Interpretation:
 - Many products in the original Olist dataset are missing dimensions.
 - product_category_name is often NULL which will later be handled during the analysis.
*/


-- check for duplicate product id (Should never happen)
SELECT
	product_id,
	count(*) as occurrences
FROM 
	ecommerce.olist_products
GROUP BY 
	product_id
HAVING count(*) > 1;

-- Validate Dimensions

-- Weight issues

SELECT * 
FROM ecommerce.olist_products
WHERE product_weight_g <= 0;

-- Product Dimension too small or zero
SELECT *
FROM ecommerce.olist_products
WHERE 
	product_height_cm <= 0 
	OR product_width_cm <= 0
	OR product_length_cm <= 0;

-- CHECK FOR EXTREAM OUTLIERS

-- Very heavy items (possible data error)
SELECT *
FROM ecommerce.olist_products
WHERE product_weight_g > 30000; -- weight 30kg unusal for Olist items

-- Very large boxes (flag for review)

SELECT * 
FROM ecommerce.olist_products
WHERE 
	product_height_cm > 200
	OR product_width_cm > 200
	OR product_length_cm > 200;


-- PRODUCT CATEGORY INTEGRITY		

-- unknown categories
SELECT *
FROM ecommerce.olist_products
WHERE product_category_name IS NULL;

-- product with extremely short name
SELECT *
FROM ecommerce.olist_products
WHERE product_name_length < 10;

-- products with no photos

SELECT *
FROM ecommerce.olist_products
WHERE product_photos_qty = 0;


/* COMMON NOTES:
   - Do NOT delete rows even if dimensions are missing -> analysis requires them.
   - Instead, we will document missing values and handle during analysis.
*/



/* 
    OLIST SELLERS
    Dataset: olist_sellers_dataset.csv
    Table: olist_sellers
    Purpose: Validate seller attributes & geographical consistency
*/

-- Total row count
SELECT COUNT(*)
FROM ecommerce.olist_sellers;

-- NULL Value Checks
SELECT
    SUM(CASE WHEN seller_id IS NULL THEN 1 ELSE 0 END) AS seller_id_nulls,
    SUM(CASE WHEN seller_zip_code_prefix IS NULL THEN 1 ELSE 0 END) AS zip_code_nulls,
    SUM(CASE WHEN seller_city IS NULL THEN 1 ELSE 0 END) AS city_nulls,
    SUM(CASE WHEN seller_state IS NULL THEN 1 ELSE 0 END) AS state_nulls
FROM ecommerce.olist_sellers;



/*
 Interpretation:
 - seller_id should NEVER be null.
 - Missing state or city would make location-based analysis inaccurate.
*/

-- check for duplicate seller id 
SELECT 
	seller_id,
	count(*) AS occurrences
FROM ecommerce.olist_sellers
GROUP BY 
	seller_id
HAVING count(*) > 1;

-- Unique city and State count
SELECT
    COUNT(DISTINCT seller_city) AS unique_cities,
    COUNT(DISTINCT seller_state) AS unique_states
FROM ecommerce.olist_sellers;


--  INVALID STATE CODES (must be 2-letter codes)
SELECT 
	seller_state
FROM ecommerce.olist_sellers
WHERE LENGTH(seller_state) > 2;


-- Check for city name with numbers
SELECT * 
FROM ecommerce.olist_sellers
WHERE seller_city ~ '^[0-9]';


/* 
    OLIST ORDER PAYMENTS
    Dataset: olist_order_payments_dataset.csv
    Table: olist_order_payments
    Purpose: Validate payment information, amounts, and logical consistency
*/

-- Total row count

SELECT COUNT(*) as total_rows FROM ecommerce.olist_order_payments;


-- NULL Value checks

SELECT
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS order_id_nulls,
    SUM(CASE WHEN payment_sequential IS NULL THEN 1 ELSE 0 END) AS payment_seq_nulls,
    SUM(CASE WHEN payment_type IS NULL THEN 1 ELSE 0 END) AS payment_type_nulls,
    SUM(CASE WHEN payment_installments IS NULL THEN 1 ELSE 0 END) AS installments_nulls,
    SUM(CASE WHEN payment_value IS NULL THEN 1 ELSE 0 END) AS payment_value_nulls
FROM ecommerce.olist_order_payments;


/*
 Interpretation:
 - payment_value should never be NULL.
 - payment_type must always exist (credit card, boleto, voucher, etc.).
*/

-- DUPLICATE CHECKS - combination (order_id + payment_sequential) must be unique
SELECT 
	order_id,
	payment_sequential,
	COUNT(*) AS occurences
FROM ecommerce.olist_order_payments
GROUP BY 
	order_id,
	payment_sequential
HAVING COUNT(*) > 1;

-- Invalid Payment Values
-- Zero or nagative payment method


SELECT * 
FROM ecommerce.olist_order_payments
WHERE payment_value <= 0 ;

-- Very high payment value (optional outlier detection)

SELECT * 
FROM ecommerce.olist_order_payments
WHERE payment_value > 5000;

--  Installments check
-- Nagative installment (invalid)

SELECT * 
FROM ecommerce.olist_order_payments
WHERE payment_installments < 0;

-- Zero installments but payment_value > 0 -> might indicate cash payment

SELECT *
FROM ecommerce.olist_order_payments
WHERE payment_installments = 0 AND payment_type IN ('boleto', 'voucher', 'debit_card');


-- payment type quality check
-- List all payments type
SELECT DISTINCT payment_type
FROM ecommerce.olist_order_payments; 

-- Strange payment type should not happen
SELECT * 
FROM ecommerce.olist_order_payments
WHERE payment_type NOT IN ('credit_card', 'boleto', 'voucher', 'debit_card', 'not_defined');

--  MULTIPLE PAYMENTS PER ORDER CHECK
-- Some orders are paid in multiple transactions -> VALID behavior

SELECT order_id, COUNT(*) AS no_of_payments, SUM(payment_value) AS total_paid
FROM ecommerce.olist_order_payments
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY no_of_payments DESC;



/* 
    OLIST GEOLOCATION
    Dataset: olist_geolocation_dataset.csv
    Table: olist_geolocation
    Purpose: Validate geographic consistency (city/state), 
             coordinate ranges and ZIP code quality.
*/

-- 1.  Total row count
SELECT count(*)
FROM ecommerce.olist_geolocation;


-- 2. Null value Checks
SELECT
    SUM(CASE WHEN geolocation_zip_code_prefix IS NULL THEN 1 ELSE 0 END) AS zip_nulls,
    SUM(CASE WHEN geolocation_lat IS NULL THEN 1 ELSE 0 END) AS lat_nulls,
    SUM(CASE WHEN geolocation_lng IS NULL THEN 1 ELSE 0 END) AS lng_nulls,
    SUM(CASE WHEN geolocation_city IS NULL THEN 1 ELSE 0 END) AS city_nulls,
    SUM(CASE WHEN geolocation_state IS NULL THEN 1 ELSE 0 END) AS state_nulls
FROM ecommerce.olist_geolocation;


/*
 Interpretation:
 - Nulls in coordinates -> unusable for mapping.
 - Null city/state -> poor geographic classification.
 - But no nulls found for this dataset
*/

-- 3. Check for city name that only number -> (invalid)

SELECT *
FROM ecommerce.olist_geolocation
WHERE geolocation_city ~ '^[0-9]+$';


-- 4. LATITUDE / LONGITUDE RANGE VALIDATION
-- Brazil latitude range approx:  -34 to +5
-- Brazil longitude range approx: -74 to -34

select * from ecommerce.olist_geolocation
where geolocation_lat NOT BETWEEN -34 AND 5
   OR geolocation_lng NOT BETWEEN -74 AND -34;

/*
 Interpretation:
 - Any results here are invalid coordinates (outside Brazil), so it was flagged.
*/

-- 5. CHECK FOR MULIPLE ZIP–CITY–STATE–COORDINATE ROWS

SELECT 
	geolocation_zip_code_prefix,
	geolocation_city,
	geolocation_state,
	count(*) AS occurrences
FROM ecommerce.olist_geolocation
GROUP BY 1, 2, 3
HAVING count(*) > 1;

/*
 Interpretation:
 - These are not duplicates because Olist dataset stores multiple coordinate points per ZIP prefix.
 - These are NOT errors - they represent many samples per region.
*/

-- 6. STATE code validation

SELECT *
FROM  ecommerce.olist_geolocation
WHERE LENGTH(geolocation_state) != 2;

/*
 Interpretation:
 - State codes should always be 2 letters (SP, RJ, MG, …).
*/


/* 
    OLIST ORDER REVIEWS
    Dataset: olist_order_reviews_dataset.csv
    Table: olist_order_reviews
    Purpose: Validate review scores, timestamps, missing values,
             and logical relationships with orders.
*/

-- 1. total row count
SELECT * FROM ecommerce.olist_order_reviews;


-- 2. Null value check 
SELECT 
	SUM(CASE WHEN review_id IS NULL THEN 1 ELSE 0 END) AS review_id_null,
	SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS order_id_nulls,
    SUM(CASE WHEN review_score IS NULL THEN 1 ELSE 0 END) AS score_nulls,
    SUM(CASE WHEN review_comment_title IS NULL THEN 1 ELSE 0 END) AS title_nulls,
    SUM(CASE WHEN review_comment_message IS NULL THEN 1 ELSE 0 END) AS message_nulls,
    SUM(CASE WHEN review_creation_date IS NULL THEN 1 ELSE 0 END) AS creation_nulls,
    SUM(CASE WHEN review_answer_timestamp IS NULL THEN 1 ELSE 0 END) AS answer_nulls
FROM ecommerce.olist_order_reviews;

/* Interpretation:
   - Titles/messages being NULL is NORMAL (customers often leave no text).
   - Missing creation/answer timestamps = suspicious -> should be investigated.
*/

-- 3. Duplicate check for review_id
SELECT 
	review_id,
	count(*) as occurrences
FROM
	ecommerce.olist_order_reviews
GROUP BY
	review_id
HAVING count(*) > 1;

/*
 Interpretation:
   - Each order should ideally have ONE review.
   - Duplicate reviews = noisy records.
   - We DO NOT delete them
*/

-- 4.  VALIDATE REVIEW SCORE RANGE (must be 1 to 5)

SELECT * 
FROM ecommerce.olist_order_reviews
WHERE 
	review_score NOT BETWEEN 1 AND 5;

-- 5 . TIMESTAMP CONSISTENCY CHECKS
-- A. Review created BEFORE the order was placed -> INVALID

SELECT 
	r.*,
	o.order_purchase_timestamp
FROM ecommerce.olist_order_reviews as r
JOIN ecommerce.olist_orders as o
ON r.order_id = o.order_id
WHERE r.review_creation_date < o.order_purchase_timestamp;

-- B. Review created Befor the product was delivered --> SUSPICIOUS
SELECT 
	r.*,
	o.order_delivered_customer_date
FROM ecommerce.olist_order_reviews as r
JOIN ecommerce.olist_orders as o
ON r.order_id = o.order_id
WHERE o.order_delivered_customer_date IS NULL
	AND r.review_creation_date < o.order_delivered_customer_date;

-- C. Review answer timestamp BEFORE customer created review -> INVALID

SELECT *
FROM ecommerce.olist_order_reviews
WHERE review_answer_timestamp < review_creation_date;

-- 6 LENGTH Checks for Comment
-- Extremly short reviews

SELECT * 
FROM ecommerce.olist_order_reviews
WHERE 
	review_comment_message IS NOT NULL 
AND LENGTH(review_comment_message) < 5;


-- -- Extremely long reviews (spam-like)
SELECT *
FROM ecommerce.olist_order_reviews
WHERE LENGTH(review_comment_message) > 500;

-- 7. MATCH REVIEWS WITH ORDERS (missing order_id problems)

SELECT *
FROM ecommerce.olist_order_reviews
WHERE order_id NOT IN (SELECT order_id FROM ecommerce.olist_orders);

/* 
DATA QUALITY SUMMARY (after checks)

- 789 duplicate review_id values found (expected, because customers may update reviews)
- 74 reviews created BEFORE the order date -> timestamp errors (flag only, do NOT delete)
- No missing mandatory fields found
*/




/* 
    PRODUCT CATEGORY NAME TRANSLATION
    Dataset: product_category_name_translation.csv
    Table: product_category_name_translation
    Purpose: Validate mapping quality between Portuguese -> English category names.
*/


-- Total Row Count
SELECT COUNT(*) AS total_rows
FROM ecommerce.product_category_name_translation;


-- 2. NULL VALUE CHECKS
SELECT
    SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) AS portuguese_name_nulls,
    SUM(CASE WHEN product_category_name_english IS NULL THEN 1 ELSE 0 END) AS english_name_nulls
FROM ecommerce.product_category_name_translation;

-- 3. DUPLICATE CHECKS
-- Portuguese category names must be UNIQUE
SELECT product_category_name, COUNT(*) AS occurrences
FROM ecommerce.product_category_name_translation
GROUP BY product_category_name
HAVING COUNT(*) > 1;

/* 
 Interpretation:
   - Duplicates mean multiple English translations -> should not exist.
*/


-- 4. CHECK FOR INVALID CHARACTERS (numbers, symbols)

SELECT *
FROM ecommerce.product_category_name_translation
WHERE product_category_name ~ '[0-9]';


SELECT *
FROM ecommerce.product_category_name_translation
WHERE product_category_name_english ~ '[0-9]';

/*
 Interpretation:
   - Category names should be text-only, rarely include numbers.
*/


-- 5. CHECK FOR LEADING / TRAILING SPACES
SELECT *
FROM ecommerce.product_category_name_translation
WHERE product_category_name LIKE ' %'
   OR product_category_name LIKE '% '
   OR product_category_name_english LIKE ' %'
   OR product_category_name_english LIKE '% ';


 -- 6. CHECK CATEGORY NAMES NOT PRESENT IN PRODUCTS TABLE
-- (important for validating joins)

SELECT DISTINCT pct.product_category_name
FROM ecommerce.olist_products as p
LEFT JOIN ecommerce.product_category_name_translation as pct
ON p.product_category_name = pct.product_category_name
WHERE pct.product_category_name IS NULL;

-- 7. CHECK FOR MISSING TRANSLATION FOR CATEGORIES IN PRODUCTS TABLE
SELECT DISTINCT p.product_category_name
FROM ecommerce.olist_products p
LEFT JOIN ecommerce.product_category_name_translation pct
  ON p.product_category_name = pct.product_category_name
WHERE pct.product_category_name IS NULL;

/*
 Interpretation:
   - These are categories that appear in the products dataset but do NOT exist in the translation table.
*/


/*  SUMMARY
   - No duplicates found in translation table.
   - Some categories in the products table do not exist here (normal).
   - No action should be taken unless building a strict dictionary.
*/

