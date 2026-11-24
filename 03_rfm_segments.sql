-- RFM segmentation (snapshot date = day after the last order in the window)
WITH base AS (
    SELECT oc.customer_unique_id,
           MAX(oc.purchased_at)         AS last_order,
           COUNT(DISTINCT oc.order_id)  AS frequency,
           SUM(r.items_value)           AS monetary
    FROM orders_clean oc
    JOIN order_revenue r USING (order_id)
    WHERE oc.order_status = 'delivered'
    GROUP BY 1
),
scored AS (
    SELECT *,
           DATE_DIFF('day', last_order, (SELECT MAX(last_order) FROM base) + INTERVAL 1 DAY) AS recency_days,
           NTILE(4) OVER (ORDER BY last_order)   AS r_score,   -- 4 = most recent
           CASE WHEN frequency >= 3 THEN 3 WHEN frequency = 2 THEN 2 ELSE 1 END AS f_score,
           NTILE(4) OVER (ORDER BY monetary)     AS m_score
    FROM base
),
segmented AS (
    SELECT *,
           CASE
               WHEN f_score >= 2 AND r_score >= 3              THEN 'Loyal'
               WHEN f_score >= 2 AND r_score <= 2              THEN 'At Risk (repeat buyers)'
               WHEN f_score = 1 AND r_score = 4 AND m_score >= 3 THEN 'New high-value'
               WHEN f_score = 1 AND r_score = 4                THEN 'New'
               WHEN f_score = 1 AND r_score >= 2 AND m_score >= 3 THEN 'One-time high-value'
               ELSE 'One-time low-value / lapsed'
           END AS segment
    FROM scored
)
SELECT segment,
       COUNT(*)                                   AS customers,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS share_customers_pct,
       ROUND(SUM(monetary), 0)                    AS revenue,
       ROUND(100.0 * SUM(monetary) / SUM(SUM(monetary)) OVER (), 1) AS share_revenue_pct,
       ROUND(AVG(recency_days), 0)                AS avg_recency_days,
       ROUND(AVG(frequency), 2)                   AS avg_orders,
       ROUND(AVG(monetary), 0)                    AS avg_spend
FROM segmented
GROUP BY segment
ORDER BY revenue DESC;
