# Limitations & Notes

This article documents known limitations of the SELMA API and the selmaR
package’s EFTS calculation so you can plan around them.

## EFTS Reporting Accuracy

[`selma_efts_report()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_efts_report.md)
produces a **pro-rata approximation** of EFTS by distributing each
component’s EFTS across calendar months proportionally to its duration.
This is useful for internal planning but will not exactly match official
TEC figures. Key reasons:

- **Pro-rata is an approximation** — EFTS are allocated proportionally
  by calendar days. The official TEC calculation may use different rules
  for partial months, start/end boundaries, or rounding.
- **Funding category mapping** — The package uses the `compenrsource`
  and `compenrfundingcategory` fields as-is from SELMA. If these are
  miscategorised in SELMA, the report inherits those errors.
- **Cross-credit detection** — Enrolments where all funded components
  sum to zero EFTS are excluded as cross-credits. This heuristic may not
  catch all cases.
- **Withdrawal date handling** — Withdrawn enrolments (`WR`, `WS`) are
  included using their original component dates. The actual funded
  period may differ depending on when the withdrawal was processed.

For official reporting, always validate against SELMA’s built-in reports
and TEC guidance.

## Known API Limitations

These are constraints of the SELMA REST API itself, not the selmaR
package:

- **No created/modified dates on components** — The
  `enrolment_components` endpoint does not include `createddate` or
  `updateddate` fields, making delta/incremental sync impossible for
  components. You must fetch the full dataset each time.
- **No bulk or delta sync** — There is no way to request “records
  changed since date X” for any endpoint. Every fetch pulls the full
  dataset.
- **No webhooks** — SELMA does not push change notifications. You must
  poll the API on a schedule.
- **Non-paginated intake enrolments** — The `/app/intake_enrolments`
  endpoint returns the entire response in a single JSON payload (no
  Hydra pagination). For intakes with many enrolments, this can be a
  large response.
- **Inconsistent ID naming** — Different endpoints use different names
  for the same concept (e.g. `id` vs `intakeid` vs `progid`). selmaR
  normalises these with `clean_names()` but the original naming is a
  source of confusion.
- **Undocumented rate limits** — The API does not publish rate limit
  headers. If you experience `429` or `503` errors, increase the delay
  between requests.
- **Token expiry** — Bearer tokens expire without warning. If you get a
  `401` error mid-fetch, re-authenticate with
  [`selma_connect()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_connect.md).

## Working Around These Limitations

- **Use caching** — Set `cache = TRUE` on fetch functions to avoid
  re-downloading data during interactive analysis sessions.
- **Schedule fetches** — Run a nightly or hourly script that refreshes
  your cached data, so your analysis always works from a recent
  snapshot.
- **Validate EFTS** — Cross-check
  [`selma_efts_report()`](https://pcstrategyandopsco.github.io/selmaR/reference/selma_efts_report.md)
  output against SELMA’s built-in funding report at least once per
  quarter.
