# E-commerce Product Analytics (Olist, Brazil)

End-to-end SQL + Python analysis of ~96K orders from Olist, a Brazilian marketplace (public dataset, Jan 2017 – Aug 2018).
**Questions:** How is the business growing? Do customers come back? Which customers bring revenue? What drives bad reviews?

**Stack:** SQL (DuckDB, PostgreSQL-style syntax: CTEs, window functions, `QUALIFY`), Python (Pandas, SciPy, statsmodels), Matplotlib/Seaborn.

## Project structure
```
sql/00_views.sql               base views: clean orders, order revenue
sql/01_monthly_kpis.sql        orders, GMV, AOV, buyers, MoM growth (LAG)
sql/02_cohort_retention.sql    monthly cohorts, repeat-purchase retention (FIRST_VALUE)
sql/03_rfm_segments.sql        RFM segmentation (NTILE)
sql/04_delivery_vs_reviews.sql late vs on-time delivery joined with reviews (ROW_NUMBER/QUALIFY)
sql/05_categories.sql          top categories by revenue
analysis.py                    runs the SQL, builds charts, runs hypothesis tests
```
Run: `bash download_data.sh && pip install -r requirements.txt && python analysis.py`

## Key findings
1. **Growth.** Monthly GMV grew from ~0.12M BRL (Jan 2017) to ~0.84–0.99M BRL in 2018; the peak was Nov 2017 (Black Friday, +52% MoM). Growth plateaued in 2018, while AOV stayed stable at ~125–153 BRL.
2. **Retention is the main weakness.** Only **3.0%** of 94.7K customers made a second purchase; average month-1 repeat rate is **~0.5%**. The business depends almost entirely on new customer acquisition.
3. **RFM.** Repeat buyers (Loyal + At Risk) are only ~3% of customers and ~5.5% of revenue, but spend more per customer (~255–264 BRL vs ~93 for low-value one-timers). One-time high-value customers (24% of customers) bring **38%** of revenue: the best target for a reactivation campaign.
4. **Late delivery destroys satisfaction.** 6.7% of delivered orders arrived later than promised. Their average review is **2.27 vs 4.29** for on-time orders, and **62%** of them got 1–2 stars (vs 9%). The difference is statistically significant (Mann–Whitney U and two-proportion z-test, p < 0.001).
5. **Logistics by region.** Late-delivery share ranges from ~4% (SP, PR, MG) to 12–17% (RJ, BA, CE, MA): north-east states need better delivery estimates or carriers.

## Recommendations
- Make delivery-date accuracy a top KPI: pad estimates in high-risk states and alert sellers who ship late.
- Launch a second-purchase program (post-delivery coupon, reminders) for one-time high-value customers; measure it with an A/B test.
- Track monthly repeat rate and cohort retention as core metrics alongside GMV.

## Charts
`charts/01_monthly_gmv.png`, `charts/02_cohort_retention.png`, `charts/03_rfm_segments.png`, `charts/04_delivery_vs_reviews.png`

_Note: delivery is "late" if it arrived more than 1 day after the estimated date. Retention is measured on `customer_unique_id`._
