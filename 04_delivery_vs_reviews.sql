-- Does late delivery hurt customer satisfaction?
WITH delivered AS (
    SELECT oc.order_id,
           oc.customer_state,
           DATE_DIFF('day', oc.purchased_at, oc.delivered_at) AS delivery_days,
           CASE WHEN oc.delivered_at > oc.estimated_at + INTERVAL 1 DAY THEN 'late' ELSE 'on_time' END AS delivery_status
    FROM orders_clean oc
    WHERE oc.order_status = 'delivered' AND oc.delivered_at IS NOT NULL
),
reviews AS (   -- one review per order (latest)
    SELECT order_id, review_score
    FROM order_reviews
    QUALIFY ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY review_answer_timestamp DESC) = 1
)
SELECT d.order_id, d.customer_state, d.delivery_days, d.delivery_status, r.review_score
FROM delivered d
JOIN reviews r USING (order_id);
