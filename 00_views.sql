-- Base views: complete months only (Jan 2017 – Aug 2018), delivered orders with revenue
CREATE OR REPLACE VIEW orders_clean AS
SELECT o.order_id,
       c.customer_unique_id,
       c.customer_state,
       o.order_status,
       CAST(o.order_purchase_timestamp AS TIMESTAMP)        AS purchased_at,
       CAST(o.order_delivered_customer_date AS TIMESTAMP)   AS delivered_at,
       CAST(o.order_estimated_delivery_date AS TIMESTAMP)   AS estimated_at
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE CAST(o.order_purchase_timestamp AS TIMESTAMP) >= '2017-01-01'
  AND CAST(o.order_purchase_timestamp AS TIMESTAMP) <  '2018-09-01';

CREATE OR REPLACE VIEW order_revenue AS
SELECT order_id,
       SUM(price)         AS items_value,
       SUM(freight_value) AS freight_value,
       COUNT(*)           AS n_items
FROM order_items
GROUP BY order_id;
