USE olist;
SELECT COUNT(*) FROM customers;
SELECT COUNT(*) FROM order_items;
SELECT COUNT(*) FROM order_payments;
SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM product_category_translation;
SELECT COUNT(*) FROM products;
SELECT * FROM customers LIMIT 10;
DESCRIBE customers;
SELECT * FROM order_items LIMIT 10;
DESCRIBE order_items;
SELECT * FROM order_payments LIMIT 10;
DESCRIBE order_payments;
SELECT * FROM orders LIMIT 10;
DESCRIBE orders;
SELECT * FROM product_category_translation LIMIT 10;
DESCRIBE product_category_translation;
SELECT * FROM products LIMIT 10;
DESCRIBE products;
# CHECKING DUPLICATES
SELECT customer_id,COUNT(*) as cnt
FROM customers
GROUP BY customer_id
HAVING COUNT(*) >1;
SELECT order_id, order_item_id, COUNT(*) AS cnt
FROM order_items
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;
SELECT order_id, COUNT(*) AS cnt
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;
SELECT product_id, COUNT(*) AS cnt
FROM products
GROUP BY product_id
HAVING COUNT(*) > 1;
SELECT ï»¿product_category_name, COUNT(*) AS cnt
FROM product_category_translation
GROUP BY ï»¿product_category_name
HAVING COUNT(*) > 1;
SELECT order_id, payment_sequential, COUNT(*) AS cnt
FROM order_payments
GROUP BY order_id, payment_sequential
HAVING COUNT(*) > 1;
#MISSING VALUES
SELECT SUM(customer_id IS NULL) AS missing_customer_id,
       SUM(customer_unique_id IS NULL) AS missing_customer_unique_id,
       SUM(customer_zip_code_prefix IS NULL) AS missing_zip_code,
	   SUM(customer_city IS NULL) AS missing_city,
       SUM(customer_state IS NULL) AS missing_state
FROM customers;
SELECT SUM(order_id IS NULL) AS missing_order_id,
       SUM(order_item_id IS NULL) AS missing_order_item_id,
       SUM(product_id IS NULL) AS missing_product_id,
       SUM(seller_id IS NULL) AS missing_seller_id,
       SUM(shipping_limit_date IS NULL) AS missing_shipping_limit_date,
       SUM(price IS NULL) AS missing_price,
       SUM(freight_value IS NULL) AS missing_freight_value
FROM order_items;
SELECT SUM(order_id IS NULL) AS missing_order_id,
       SUM(payment_sequential IS NULL) AS missing_payment_sequential,
       SUM(payment_type IS NULL) AS missing_payment_type,
       SUM(payment_installments IS NULL) AS missing_payment_installments,
       SUM(payment_value IS NULL) AS missing_payment_value
FROM order_payments;
SELECT SUM(order_id IS NULL) AS missing_order_id,
       SUM(customer_id IS NULL) AS missing_customer_id,
       SUM(order_status IS NULL) AS missing_order_status,
       SUM(order_purchase_timestamp IS NULL) AS missing_order_purchase_timestamp,
       SUM(order_approved_at IS NULL) AS missing_order_approved_at,
       SUM(order_delivered_carrier_date IS NULL) AS missing_order_delivered_carrier_date,
       SUM(order_delivered_customer_date IS NULL) AS missing_order_delivered_customer_date,
       SUM(order_estimated_delivery_date IS NULL) AS missing_order_estimated_delivery_date
FROM orders;
SELECT SUM(ï»¿product_category_name IS NULL) AS missing_product_category_name,
       SUM(product_category_name_english IS NULL) AS missing_product_category_name_english
FROM product_category_translation;
SELECT SUM(product_id IS NULL) AS missing_product_id,
       SUM(product_category_name IS NULL) AS missing_product_category_name,
       SUM(product_name_lenght IS NULL) AS missing_product_name_lenght,
       SUM(product_description_lenght IS NULL) AS missing_product_description_lenght,
       SUM(product_photos_qty IS NULL) AS missing_product_photos_qty,
       SUM(product_weight_g IS NULL) AS missing_product_weight_g,
       SUM(product_length_cm IS NULL) AS missing_product_length_cm,
       SUM(product_height_cm IS NULL) AS missing_product_height_cm,
       SUM(product_width_cm IS NULL) AS missing_product_width_cm
FROM products;
SELECT COUNT(*) AS 	total_records,
       ROUND(SUM(product_category_name IS NULL) *100.0/COUNT(*),2) AS missing_category_percentage,
       ROUND(SUM(product_weight_g IS NULL)*100.0/COUNT(*),2) AS missing_weigh_percentage
FROM products;
SELECT COUNT(*) AS records_missing_all_four
FROM products
WHERE product_category_name IS NULL
  AND product_name_lenght IS NULL
  AND product_description_lenght IS NULL
  AND product_photos_qty IS NULL; 
SELECT *
FROM products
WHERE product_category_name IS NULL
LIMIT 10;
-- During data quality assessment of the products table, I identified 610 missing values in product category, product name length,
--  product description length and product photo quantity columns.  
-- Additionally,two records contained missing physical dimension information, including weight, length, height and width. 
-- Further investigation is required to determine whether these missing values overlap and how they may affect product-level analysis.
ALTER TABLE product_category_translation
RENAME COLUMN `ï»¿product_category_name` TO product_category_name;
DESCRIBE customers;
DESCRIBE orders;
SELECT MAX(CHAR_LENGTH(customer_id))
FROM customers;
SELECT MAX(CHAR_LENGTH(customer_id))
FROM orders;
SELECT MAX(CHAR_LENGTH(order_id))
FROM order_items;
SELECT MAX(CHAR_LENGTH(product_id))
FROM products;

ALTER TABLE customers MODIFY customer_id VARCHAR(50) NOT NULL;
ALTER TABLE customers ADD PRIMARY KEY (customer_id);

ALTER TABLE orders MODIFY customer_id VARCHAR(50) NOT NULL;
ALTER TABLE orders MODIFY order_id    VARCHAR(50) NOT NULL;
ALTER TABLE orders ADD PRIMARY KEY (order_id);

ALTER TABLE orders
ADD CONSTRAINT fk_orders_customers
FOREIGN KEY (customer_id) REFERENCES customers(customer_id);

ALTER TABLE products MODIFY product_id VARCHAR(50) NOT NULL;
ALTER TABLE products ADD PRIMARY KEY (product_id);

ALTER TABLE order_items MODIFY order_id      VARCHAR(50) NOT NULL;
ALTER TABLE order_items MODIFY order_item_id INT NOT NULL;
ALTER TABLE order_items ADD PRIMARY KEY (order_id, order_item_id);

ALTER TABLE order_items
ADD CONSTRAINT fk_order_items_orders
FOREIGN KEY (order_id) REFERENCES orders(order_id);

CREATE INDEX idx_items_pid ON order_items(product_id(32));
CREATE INDEX idx_pay_oid   ON order_payments(order_id(32));
DROP TABLE IF EXISTS orders_clean;

CREATE TABLE orders_clean AS
SELECT
  order_id,
  customer_id,
  order_status,
  STR_TO_DATE(NULLIF(order_purchase_timestamp,''), '%Y-%m-%d %H:%i:%s')      AS purchase_ts,
  STR_TO_DATE(NULLIF(order_approved_at,''), '%Y-%m-%d %H:%i:%s')             AS approved_ts,
  STR_TO_DATE(NULLIF(order_delivered_customer_date,''), '%Y-%m-%d %H:%i:%s') AS delivered_ts,
  STR_TO_DATE(NULLIF(order_estimated_delivery_date,''), '%Y-%m-%d %H:%i:%s') AS estimated_ts
FROM orders;
CREATE INDEX idx_oc_oid ON orders_clean(order_id);
SELECT MIN(purchase_ts) AS first_order, MAX(purchase_ts) AS last_order FROM orders_clean;
#KPI
#1. Total customers :
SELECT COUNT(DISTINCT customer_unique_id) AS TOTAL_CUSTOMER
FROM customers;
#2. Total Orders:
SELECT COUNT(DISTINCT order_id) AS TOTAL_ORDERS
FROM orders;
#3. Total Products:
SELECT COUNT(DISTINCT product_id) AS TOTAL_PRODUCTS
FROM products;
#4.Total sales revenue :
SELECT ROUND(SUM(price) ,2)AS Total_Sales_Revenue 
FROM order_items;
#5.Total freight revenue :
SELECT ROUND(SUM(freight_value) ,2) AS Total_Freight_Revenue
FROM order_items;
#6.Average product price :
SELECT ROUND(AVG(price),2) AS Average_Product_Price
FROM order_items;
#7.Total payment value :
SELECT ROUND(SUM(payment_value),2) AS Total_Payment_Value
FROM order_payments;
# 8.Order status distribution:
SELECT order_status,COUNT(*) AS total_orders_status
FROM orders
GROUP BY order_status
ORDER BY total_orders_status DESC;
#Business Question:
#1.What is the total revenue generated each month?
SELECT
  DATE_FORMAT(o.purchase_ts, '%Y-%m') AS month,
  COUNT(DISTINCT o.order_id)   AS orders,
  ROUND(SUM(oi.price), 2) AS revenue
FROM orders_clean o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY month
ORDER BY month;
#2.Which month generated the highest revenue?
SELECT
  DATE_FORMAT(o.purchase_ts, '%Y-%m') AS month,
  ROUND(SUM(oi.price), 2)  AS revenue
FROM orders_clean o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY month
ORDER BY revenue DESC
LIMIT 1;
#3.Top 10 categories by revenue?
SELECT
  COALESCE(t.product_category_name_english, 'unknown') AS category,
  COUNT(DISTINCT oi.order_id)AS orders,
  COUNT(*)     AS units_sold,
  ROUND(SUM(oi.price), 2)  AS revenue
FROM order_items oi
JOIN orders_clean o ON oi.order_id = o.order_id
JOIN products p    ON oi.product_id = p.product_id
LEFT JOIN product_category_translation t
       ON p.product_category_name = t.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY category
ORDER BY revenue DESC
LIMIT 10;
#4.Top 10 best-selling products (by units sold)
SELECT
  oi.product_id,
  COALESCE(t.product_category_name_english, 'unknown') AS category,
  COUNT(*)  AS units_sold,
  ROUND(SUM(oi.price), 2)  AS revenue
FROM order_items oi
JOIN orders_clean o ON oi.order_id = o.order_id
JOIN products p     ON oi.product_id = p.product_id
LEFT JOIN product_category_translation t
       ON p.product_category_name = t.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY oi.product_id, category
ORDER BY units_sold DESC
LIMIT 10;
#5.Average price by category
SELECT
  COALESCE(t.product_category_name_english, 'unknown') AS category,
  COUNT(*) AS units_sold,
  ROUND(AVG(oi.price), 2) AS avg_price,
  ROUND(MIN(oi.price), 2) AS min_price,
  ROUND(MAX(oi.price), 2)  AS max_price
FROM order_items oi
JOIN orders_clean o ON oi.order_id = o.order_id
JOIN products p     ON oi.product_id = p.product_id
LEFT JOIN product_category_translation t
       ON p.product_category_name = t.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY category
ORDER BY avg_price DESC;

 