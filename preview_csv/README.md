# Preview CSVs — convenience only (NOT the modeling data)

These three files are a **30-customer sample from the shared demo cohort**
(the first 30 customers of its `plaid_synth_shard_00.ndjson.gz`), pre-flattened
so you can open them in a spreadsheet and see the shape of the data before you
write any code.

- `preview_transactions.csv` — one row per transaction (mind the Plaid sign
  convention: a **positive** `amount` is an OUTFLOW).
- `preview_accounts.csv` — one row per account, balances unnested.
- `preview_liabilities.csv` — long form; one row per credit / student /
  mortgage liability.

**You must still build your features from the JSON shards.** Flattening the
nested bundles is the Stage 1 skill that transfers to Stage 2; these previews
cover only 30 customers out of the 25,000 in your release and exist purely for
eyeballing. The Stage 1 starter ships a `flatten_tx()` helper that produces
files like these for any bundle you choose (see also
`starter_code/example_data/` — one customer shown as JSON and CSV side by side).

**Note:** this preview comes from the shared demo cohort — its `customer_id`s
are *not* in your team's release. It shows the shape of the data only.
