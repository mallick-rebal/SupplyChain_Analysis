# Findings — Analyze stage (q01–q17)

Format: **finding → $ impact → recommendation**. All figures exclude canceled and suspected-fraud orders unless stated.
Source queries are in `Analyze/sql/`. Run any of them with `python Analyze/run_query.py <file> --csv`.

## Fulfillment & SLA (q01–q06)

**1. Lateness is driven by shipping mode, not by market or region** (q01, q02, q03)
- Every market and region is late on roughly 55–60% of items. For a given shipping mode, late % is almost identical in all five markets (e.g. Second Class 79–80% everywhere).
- The worst country × category combinations (min. 100 items) reach ~69% late vs a ~57% average. That gap is modest and based on small groups, so no single country or product stands out.
- **$ impact:** $18.1M of $31.6M net revenue (57%) is tied to late items.
- **Recommendation:** fix the problem at shipping-mode level. Region-by-region fixes won't move the numbers.

**2. The promised shipping days (SLA) are unrealistic for First and Second Class** (q04, q05)
- First Class promises 1 day and takes exactly 2 days on every item. This is a property of the dataset (no variation at all), so it reads as "the 1-day SLA is unachievable", not "First Class fails every delivery".
- Second Class promises 2 days; only ~20% of items arrive in 2 days, the rest take 3–6 days.
- Standard Class is spread evenly from 2 to 6 days against a 4-day promise, so it averages out close to on time.
- The day counts that 90% of items actually meet: Same Day 1, First Class 2, Second Class 6, Standard Class 6.
- **Recommendation:** reset the customer promise to what operations can deliver (First Class 2 days, Second Class up to 6), or invest to make the current promise achievable.

**3. Delays are flat over three years** (q06)
- Average delay per mode barely moves from Jan 2015 to Sep 2017 (Second Class ~2 days late every month, Standard Class ~0).
- **Recommendation:** treat this as a structural SLA issue, not a temporary disruption.

## Profitability (q07–q10)

**4. Margin is steady at ~12% across all markets** (q07)
- Net revenue $31.6M, profit $3.8M, margin 12.0% (matches `control_totals.json`).
- Fan Shop is the largest profit contributor in every market. Book Shop and Discs Shop have the weakest margins (as low as 1.9%), but they are small.

**5. Loss-making items wipe out about half of the profit** (q08)
- About 1 in 5 items (18.7%) is sold at a loss. Profitable items earn $7.5M; loss-making items lose $3.7M, leaving $3.8M net profit.
- The top 10 products account for most of the losses; the Field & Stream gun safe alone is $693K (19% of all losses).
- **Recommendation:** review pricing and cost on the top loss-making products first.
- **Data note:** some products sit in unexpected categories (e.g. the gun safe under "Fishing"). This comes from the source data and should be checked before using category-level results in the deck.

**6. Discounts are not what drives the losses** (q09)
- Margin stays at ~12% and the share of loss-making items stays at ~19% across every discount band from 0% to 25%.
- **Recommendation:** look at product cost and pricing, not discount policy, to explain the losses.

**7. Premium shipping carries most of the risk** (q10)
- First and Second Class together hold $9.8M of revenue tied to late items, from customers who paid for faster delivery.
- Overall, $2.1M of the $3.8M profit comes from late orders.
- **Recommendation:** prioritise fixing First and Second Class, where customers pay more and are most likely to be let down.

## Product performance (q11–q13)

**8. A handful of products carry the business** (q13)
- 8 of 118 products (7%) make about 80% of net revenue. The top product, the Field & Stream gun safe, alone makes 19%.
- **Recommendation:** fulfillment fixes and stock planning should start with these 8 "A-class" products.

**9. The biggest sellers are "volume drivers", not stars** (q11)
- Splitting products at the median of units sold and margin: the 30 "volume driver" products (high volume, below-median margin) bring in $21.9M of $31.6M revenue.
- Margins are tightly packed (mostly 10–15%), so the quadrant separates products more by volume than by margin.
- **Recommendation:** small price or cost improvements on the volume drivers move the most money.

**10. The same products win in every market** (q12)
- The gun safe is the #1 profit product in all five markets, and the top 3 are nearly identical everywhere. The bottom products are small, low-volume items with near-zero or negative profit.
- **Recommendation:** no market-specific product strategy is needed; a single product focus list works for all markets.

## Demand trends (q14–q16)

**11. Revenue was flat in 2016 and grew in 2017** (q14, q15)
- Comparing each month with the same month a year earlier: 2016 was within about ±2% of 2015, while Feb–Sep 2017 grew 2–12% year over year (Sep 2017 +12.5%).
- The low-coverage months (Oct 2017 – Jan 2018) are excluded, so the thin late-2017 data does not create a false decline.

**12. There is almost no seasonality** (q16)
- Every month sits within about ±3% of an average month, except February (index 92.5), which is mostly explained by February having fewer days.
- **Recommendation:** capacity planning does not need big seasonal adjustments; keep staffing level through the year.

## Operations priority (q17)

**13. Where operations should look first** (q17)
- Priority score per market × category (min. 100 items) = 40% late rate + 35% revenue at risk + 25% volume, each converted to a percentile score first so no single measure dominates through scale. Weights sit at the top of the query and can be changed.
- Top 5: Europe Fishing, Europe Men's Footwear, LATAM Camping & Hiking, Europe Cleats, LATAM Indoor/Outdoor Games.
- Europe Fishing ranks #1: high late rate (59%), the 2nd-highest revenue at risk (~$979K) and high volume.
- **Caveat:** late rates only range from about 50% to 61% across segments, so the late-rate percentile spreads out fairly small real differences. The ranking is a starting point for investigation, not a verdict.
- **Recommendation:** start operational reviews with the top-ranked segments, and combine with Finding 2: fixing First and Second Class promises lifts every segment at once.

## Data caveats
- This is a synthetic dataset. Several patterns (perfectly even day distributions, First Class always +1 day, flat margins) are too regular for real operations. Findings should be presented as what this data shows, not as real-world benchmarks.
- Oct 2017 – Jan 2018 is excluded from trend analysis (`is_low_coverage_period`): only 2 markets and 31 products.
