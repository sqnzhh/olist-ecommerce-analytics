-- Top categories by revenue with share, avg price and review score
WITH cat AS (
    SELECT COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category,
           oi.order_id, oi.price
    FROM order_items oi
    JOIN orders_clean oc USING (order_id)
    LEFT JOIN products p USING (product_id)
    LEFT JOIN category_translation t USING (product_category_name)
    WHERE oc.order_status = 'delivered'
),
rev AS (
    SELECT order_id, AVG(review_score) AS review_score FROM order_reviews GROUP BY 1
)
SELECT category,
       COUNT(DISTINCT order_id)                                   AS orders,
       ROUND(SUM(price), 0)                                       AS revenue,
       ROUND(100.0 * SUM(price) / SUM(SUM(price)) OVER (), 1)     AS revenue_share_pct,
       ROUND(AVG(price), 1)                                       AS avg_item_price,
       ROUND(AVG(rev.review_score), 2)                            AS avg_review
FROM cat LEFT JOIN rev USING (order_id)
GROUP BY category
ORDER BY revenue DESC
LIMIT 10;
