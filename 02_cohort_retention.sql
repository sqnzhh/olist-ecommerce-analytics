-- Monthly cohort retention: share of customers who buy again N months after their first order
WITH purchases AS (
    SELECT customer_unique_id,
           DATE_TRUNC('month', purchased_at) AS order_month
    FROM orders_clean
    WHERE order_status NOT IN ('canceled', 'unavailable')
),
first_purchase AS (
    SELECT customer_unique_id, MIN(order_month) AS cohort_month
    FROM purchases
    GROUP BY 1
),
activity AS (
    SELECT DISTINCT f.cohort_month,
           p.customer_unique_id,
           DATE_DIFF('month', f.cohort_month, p.order_month) AS month_number
    FROM purchases p
    JOIN first_purchase f USING (customer_unique_id)
)
SELECT cohort_month,
       month_number,
       COUNT(*) AS customers,
       ROUND(100.0 * COUNT(*) / FIRST_VALUE(COUNT(*)) OVER (
             PARTITION BY cohort_month ORDER BY month_number), 2) AS retention_pct
FROM activity
GROUP BY cohort_month, month_number
ORDER BY cohort_month, month_number;
