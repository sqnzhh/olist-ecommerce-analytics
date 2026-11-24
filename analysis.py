"""Olist e-commerce analytics: runs the SQL in /sql on DuckDB, builds charts, runs a hypothesis test."""
from pathlib import Path
import duckdb
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import seaborn as sns
from scipy import stats

ROOT = Path(__file__).parent
DATA, SQL, CHARTS = ROOT / "data", ROOT / "sql", ROOT / "charts"
CHARTS.mkdir(exist_ok=True)
sns.set_theme(style="whitegrid")

con = duckdb.connect()
tables = {
    "orders": "olist_orders_dataset", "order_items": "olist_order_items_dataset",
    "customers": "olist_customers_dataset", "order_reviews": "olist_order_reviews_dataset",
    "payments": "olist_order_payments_dataset", "products": "olist_products_dataset",
    "category_translation": "product_category_name_translation",
}
for name, file in tables.items():
    con.execute(f"CREATE TABLE {name} AS SELECT * FROM read_csv_auto('{DATA / file}.csv', header=true)")
con.execute((SQL / "00_views.sql").read_text())

def q(file):
    return con.execute((SQL / file).read_text()).df()

# 1. Monthly KPIs
kpi = q("01_monthly_kpis.sql")
print("\n=== Monthly KPIs ===\n", kpi.to_string(index=False))
fig, ax = plt.subplots(figsize=(10, 4))
ax.plot(kpi["month"], kpi["gmv"] / 1e6, marker="o")
ax.set_title("Monthly GMV (BRL, millions)"); ax.set_ylabel("GMV, M BRL")
fig.tight_layout(); fig.savefig(CHARTS / "01_monthly_gmv.png", dpi=120); plt.close(fig)

# 2. Cohort retention
coh = q("02_cohort_retention.sql")
pivot = coh.pivot(index="cohort_month", columns="month_number", values="retention_pct")
pivot.index = pd.to_datetime(pivot.index).strftime("%Y-%m")
heat = pivot.loc[:, 1:12]
fig, ax = plt.subplots(figsize=(12, 7))
sns.heatmap(heat, annot=True, fmt=".2f", cmap="Blues", cbar_kws={"label": "% of cohort"}, ax=ax)
ax.set_title("Repeat-purchase retention by monthly cohort (%), months 1–12")
ax.set_xlabel("Months since first purchase"); ax.set_ylabel("Cohort")
fig.tight_layout(); fig.savefig(CHARTS / "02_cohort_retention.png", dpi=120); plt.close(fig)
cohort_sizes = coh[coh.month_number == 0]["customers"].sum()
repeaters = con.execute("""
    SELECT COUNT(*) FILTER (WHERE n > 1) * 100.0 / COUNT(*) FROM (
      SELECT customer_unique_id, COUNT(DISTINCT order_id) n FROM orders_clean
      WHERE order_status NOT IN ('canceled','unavailable') GROUP BY 1)""").fetchone()[0]
m1 = heat[1].mean()
print(f"\n=== Retention ===\nCustomers: {cohort_sizes}, repeat buyers: {repeaters:.2f}%, avg month-1 retention: {m1:.2f}%")

# 3. RFM
rfm = q("03_rfm_segments.sql")
print("\n=== RFM segments ===\n", rfm.to_string(index=False))
fig, ax = plt.subplots(figsize=(9, 4))
r = rfm.sort_values("share_revenue_pct")
ax.barh(r["segment"], r["share_customers_pct"], label="% customers", alpha=.6)
ax.barh(r["segment"], r["share_revenue_pct"], label="% revenue", height=.4)
ax.set_title("RFM segments: share of customers vs share of revenue"); ax.legend()
fig.tight_layout(); fig.savefig(CHARTS / "03_rfm_segments.png", dpi=120); plt.close(fig)

# 4. Delivery delays vs reviews + hypothesis test
dr = q("04_delivery_vs_reviews.sql")
summary = dr.groupby("delivery_status").agg(
    orders=("order_id", "count"), avg_review=("review_score", "mean"),
    share_1_2_stars=("review_score", lambda s: (s <= 2).mean() * 100),
    avg_delivery_days=("delivery_days", "mean")).round(2)
print("\n=== Delivery vs reviews ===\n", summary)
late, on_time = dr.loc[dr.delivery_status == "late", "review_score"], dr.loc[dr.delivery_status == "on_time", "review_score"]
u = stats.mannwhitneyu(late, on_time, alternative="less")
# two-proportion z-test on share of negative reviews
from statsmodels.stats.proportion import proportions_ztest
neg = [(late <= 2).sum(), (on_time <= 2).sum()]; n = [len(late), len(on_time)]
z, pz = proportions_ztest(neg, n)
print(f"Mann-Whitney U p-value: {u.pvalue:.2e}; z-test negative-review share: z={z:.1f}, p={pz:.2e}")
late_share = len(late) / len(dr) * 100
print(f"Late deliveries: {late_share:.1f}% of delivered orders")
fig, ax = plt.subplots(figsize=(7, 4))
dist = (dr.groupby("delivery_status")["review_score"].value_counts(normalize=True)
          .mul(100).rename("pct").reset_index())
sns.barplot(data=dist, x="review_score", y="pct", hue="delivery_status", ax=ax)
ax.set_title("Review score distribution: late vs on-time delivery"); ax.set_ylabel("% of orders")
fig.tight_layout(); fig.savefig(CHARTS / "04_delivery_vs_reviews.png", dpi=120); plt.close(fig)
state = (dr.groupby("customer_state").agg(orders=("order_id", "count"),
         late_pct=("delivery_status", lambda s: (s == "late").mean() * 100),
         avg_days=("delivery_days", "mean")).query("orders >= 500")
         .sort_values("late_pct", ascending=False).round(1))
print("\n=== Late share by state (>=500 orders) ===\n", state.head(5), "\n...\n", state.tail(3))

# 5. Categories
cat = q("05_categories.sql")
print("\n=== Top categories ===\n", cat.to_string(index=False))
