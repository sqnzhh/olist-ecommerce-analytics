-- Monthly KPIs: orders, GMV, AOV, unique buyers, MoM growth
WITH monthly AS (
    SELECT DATE_TRUNC('month', oc.purchased_at)        AS month,
           COUNT(DISTINCT oc.order_id)                  AS orders,
           COUNT(DISTINCT oc.customer_unique_id)        AS buyers,
           SUM(r.items_value)                           AS gmv
    FROM orders_clean oc
    JOIN order_revenue r USING (order_id)
    WHERE oc.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY 1
)
SELECT month,
       orders,
       buyers,
       ROUND(gmv, 0)                                             AS gmv,
       ROUND(gmv / orders, 2)                                    AS aov,
       ROUND(100.0 * (gmv / LAG(gmv) OVER (ORDER BY month) - 1), 1) AS gmv_mom_pct
FROM monthly
ORDER BY month;
