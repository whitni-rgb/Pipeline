# example_data — one customer, shown both ways (JSON and CSV)

This folder shows what the project's data looks like, using ONE customer
(`cu_00001`) from the shared demo cohort. The synthetic release your team
receives in Stage 2 contains thousands of customers in **exactly this shape**
(one JSON bundle per customer, 500 bundles per gzipped shard file), and your
Stage 1 pipeline should persist each Plaid Sandbox persona as a bundle of this
same shape — so use this file as your target.

| File | What it is |
|---|---|
| `example_bundle.json` | One complete customer bundle, pretty-printed: `{customer_id, item, identity, accounts, transactions, liabilities}` — the nested JSON exactly as an aggregator like Plaid returns it. This is what one line of a release shard contains. |
| `example_transactions_flat.csv` | The SAME customer's transactions flattened to a table: one row per transaction. This is what your Stage 1 `flatten_tx()` should produce. |
| `example_accounts_flat.csv` | The same customer's accounts flattened: one row per account, balances unnested. |
| `example_liabilities_flat.csv` | The same customer's liabilities flattened: one row per liability (this customer has one credit card; some customers have none — that absence is data, not an error). |

Three things to notice while you have it open:

1. **The sign convention.** Find the payroll rows in the transactions CSV:
   `amount` is NEGATIVE for money coming in. Plaid reports outflows as
   positive. Sum raw amounts as "income" and you will compute negative income.
2. **Nesting.** In the JSON, `personal_finance_category` is an object inside
   each transaction, and `balances` is an object inside each account. The CSVs
   exist because flattening that nesting is the Stage 1 skill.
3. **The data is imperfect on purpose.** This very customer contains a handful
   of near-duplicate transactions (same account, amount and name within a day —
   a pending-then-posted artifact). Finding and handling such pathologies is
   part of the graded work (Handout, Appendix A.2).

One difference from your Stage 1 output: release bundles carry an `item` block
(institution metadata added by the generator); your Sandbox bundles need not.
The demo customer's ids do not appear in any team's release.
