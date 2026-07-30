
COPY ecommerce.olist_customers
FROM 'C:\SQL DATA\olist_customers.csv'
DELIMITER ','
CSV HEADER;

COPY ecommerce.olist_orders
FROM 'C:\SQL DATA\olist_orders_dataset.csv'
DELIMITER ','
CSV HEADER;

COPY ecommerce.olist_order_items
FROM 'C:\SQL DATA\olist_order_items_dataset.csv'
DELIMITER ','
CSV HEADER;


COPY ecommerce.olist_products
FROM 'C:\SQL DATA\olist_products_dataset.csv'
DELIMITER ','
CSV HEADER;

COPY ecommerce.olist_sellers
FROM 'C:\SQL DATA\olist_sellers_dataset.csv'
DELIMITER ','
CSV HEADER;

COPY ecommerce.olist_order_payments
FROM 'C:\SQL DATA\olist_order_payments_dataset.csv'
DELIMITER ','
CSV HEADER;

COPY ecommerce.olist_geolocation
FROM 'C:\SQL DATA\olist_geolocation_dataset.csv'
DELIMITER ','
CSV HEADER;

COPY ecommerce.olist_order_reviews
(
    review_id,  -- we took only necessary column from the dataset
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp
)
FROM 'C:\SQL DATA\olist_order_reviews_dataset.csv'
DELIMITER ','
CSV HEADER;

COPY ecommerce.product_category_name_translation
FROM 'C:\SQL DATA\product_category_name_translation.csv'
DELIMITER ','
CSV HEADER;



