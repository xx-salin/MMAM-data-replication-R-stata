# Discrepancy Log — R → Stata Replication (01_clean_raw_data)

Tracks divergences between the original R cleaning pipeline and the Stata
port, per experiment/family. Updated as each stage is verified.

---

## Family 1 (v5, v13, v11) — verified

**v5, v13:** Exact match against R output. All rows, all columns,
byte-for-byte on numeric values.

**v11:** Deliberate deviation — see entry below.

### v11 — duplicate-submission cartesian fan-out (not replicated)

**R behavior:** `clean_two_round_paste()` builds a separate `orders` table
from the same raw data and joins it back via `inner_join(id)`. R's own
`clean_interference()` (Family 3) explicitly deduplicates raw submissions
first (`distinct(id, .keep_all = TRUE)`), but `clean_two_round_paste()`
(Family 1) omits this step.

**Effect:** For any participant with duplicate raw survey submissions, the
`id`-only join produces a cartesian fan-out (N submissions × N submissions =
N² rows) instead of N rows. Confirmed in v11 for id
`f11f54084b0ccb5363ba25f7`: 3 raw submissions → 9 rows per round in R's
output (18 total) instead of the correct 3 rows per round (6 total).

**Resolution:** Stata pipeline deduplicates raw submissions by `id`
immediately after import (keeping the first submission in original file
order), before any downstream joins. This matches the dedup approach R
already uses explicitly in Family 3.

**Decision:** Treated as an R bug, not replicated. R's `v11.csv` = 134 rows;
Stata's output = 118 rows. The 16-row gap is fully and exclusively
attributable to this one participant (confirmed via row-by-row diff — every
other row matches R exactly). No other Family 1/2/3 experiment shows this
issue (checked v5, v13, v17, v24, v21, v27 — all clean of duplicate
submissions).

---

## Cross-family — non-stable sort during dedup (fixed)

**Cause:** The dedup step (`sort id` / `by id: keep if _n==1`) initially used
a plain `sort id`, which is **not guaranteed stable** in Stata — ties on
`id` can be reordered arbitrarily. For participants with duplicate
submissions, this meant "keep first" did not reliably mean "keep the first
submission in the original raw file," causing silent value swaps (wrong
`bonus_payment`, `duration`, `whichFirst`, etc. — different fields from
different submissions).

**Caught by:** v21 diff showed one participant (`ab1a50a2887eb2cdcf9fcd20`,
2 raw submissions) with `bonus_payment`, `cond_beliefs_choice_order`,
`duration`, and `whichFirst` all mismatched against R, despite the row
count being correct.

**Resolution:** Added an explicit row-order variable before sorting, in all
three family programs:
```stata
gen long _orig_order = _n
sort id _orig_order
by id: keep if _n == 1
drop _orig_order
```
This guarantees "first" means first-in-original-file-order, matching R's
row-order-dependent join/distinct behavior. Applied to Family 1
(`clean_family1`), Family 2 (`clean_family2`), and Family 3
(`clean_family3`).

**Status:** Resolved. Confirmed no residual effect on v5/v13/v17/v24 (no
duplicate submitters present, so this bug was latent but harmless there).

---

## Family 2 (v17, v24) — verified

Exact match against R output for both experiments, including the 11
(v17) / 3 (v24) view-time columns and the sampling-order array. No
duplicate-submission issue in either file.

---

## Family 3 (v21, v27) — verified

**v21, v27 (trials + IDs):** Exact match against R output after the two
fixes below.

### float32 vs double precision on view-time columns (fixed)

**Cause:** Stata's `destring` converts to the smallest numeric type that
fits the data — `float` (32-bit, ~7 significant digits) — by default. R
stores all numeric columns as `double` (64-bit). View-time values (e.g.
`21.738`) lost precision at the 6th significant digit under float32,
producing values like `21.738001` or `9.8479996`.

**Why `recast double` alone didn't fix it:** `recast` only widens the
storage *type* after the value is already in memory — it cannot recover
precision already rounded away during `destring`. The rounding happens at
`destring` time, not at storage time.

**Resolution:** Replaced `destring` for the view-time columns with a direct
double-precision parse, avoiding the float round-trip entirely:
```stata
foreach v of varlist viewBlue1-viewBlue11 viewOrange1-viewOrange11 {
    gen double _tmp_`v' = real(`v')
    drop `v'
    rename _tmp_`v' `v'
}
```
The row-wise Blue/Orange coalesce step (`gen view1 = ...`) was also changed
to `gen double` to preserve precision through to final export.

**Status:** Resolved. Verified exact match (max abs diff = 0) against R
reference for both v21 and v27.

Not needed in Family 1/2 — their numeric fields didn't carry enough decimal
precision to expose float32 rounding error.

---

## Summary table

| File | Family | Status | Notes |
|---|---|---|---|
| v5 | 1 | ✅ Exact match | |
| v13 | 1 | ✅ Exact match | |
| v11 | 1 | ✅ Verified, documented deviation | 118 vs 134 rows — R's fan-out bug not replicated |
| v17 | 2 | ✅ Exact match | |
| v24 | 2 | ✅ Exact match | |
| v21 | 3 | ✅ Exact match | |
| v27 (trials + IDs) | 3 | ✅ Exact match | |
| prereg | 4 | ⏳ Not yet started | |
