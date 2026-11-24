#!/usr/bin/env bash
# Downloads the public Olist Brazilian e-commerce dataset into ./data
mkdir -p data && cd data
B=https://raw.githubusercontent.com/olist/work-at-olist-data/master/datasets
for f in olist_orders_dataset olist_order_items_dataset olist_customers_dataset olist_order_payments_dataset \
         olist_order_reviews_dataset olist_products_dataset product_category_name_translation olist_sellers_dataset; do
  curl -sSL -o "$f.csv" "$B/$f.csv"
done
