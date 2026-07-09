## Family 4 (prereg) — verified

Exact match against R output: **1561/1561 rows, all 25 columns**, after two
rounds of fixes below. Confirms the condition-gated belief logic, the 3-way
`unite()` triples, and the `na.omit()` string/numeric distinction.

### riskTaking/statKnow/regretExAnte/regretExPost — string vs numeric na.omit() mismatch (fixed)

**Cause:** R's `clean_prereg()` never numeric-casts `riskTaking`, `statKnow`,
`regretExAnte`, or `regretExPost` anywhere in the pipeline — they remain
character strings throughout. Blank values are literal `""`, not R's `NA`,
so `na.omit()` never drops a row for these fields being empty. The Stata
port initially `destring`'d these fields before the na.omit-equivalent
check, converting blanks to Stata missing (`.`) and incorrectly dropping
otherwise-complete rows.

**Caught by:** Row-count mismatch (1559 vs R's 1561). Diffing by
`(id, round)` key found 2 missing participants
(`3c0bcef877f961712412be38`, `d3c7191d61a4723da4c37fe7`), both with blank
`Q22/Q25/Q24/Q23` in the raw data but otherwise complete responses.
Confirmed both rows exist in R's own `prereg.csv` output with blank
`riskTaking`, proving R's `na.omit()` genuinely does not check these
fields.

**Resolution:** Removed `riskTaking statKnow regretExAnte regretExPost`
from the `destring` call and from the `rowmiss()` na.omit-equivalent check
in `clean_prereg`. These fields now pass through as plain strings — blank
stays blank, matching R exactly.

**Open question:** This same latent issue may exist in Families 1–3
(`clean_family1`/`2`/`3` all destring and na.omit-check these same four
fields). It didn't surface there only because no participant in those
smaller experiments happened to complete the main task while skipping
these specific survey questions. **Not yet checked** — needs verification
against the v5/v13/v11/v17/v24/v21/v27 raw files before ruling out.

---

## Summary table (01_clean_raw_data.do)

| File | Family | Status | Notes |
|---|---|---|---|
| v5 | 1 | ✅ Exact match | |
| v13 | 1 | ✅ Exact match | |
| v11 | 1 | ✅ Verified, documented deviation | 118 vs 134 rows — R's fan-out bug not replicated |
| v17 | 2 | ✅ Exact match | |
| v24 | 2 | ✅ Exact match | |
| v21 | 3 | ✅ Exact match | |
| v27 (trials + IDs) | 3 | ✅ Exact match | |
| prereg | 4 | ✅ Exact match | 1561/1561 rows |

**Remaining for 01_clean_raw_data.do:**
- View-time (short/long) and sampling-order (round1/round2) exports for
  `clean_prereg` — deferred while verifying the trial-level file
- Check v5/v13/v11/v17/v24/v21/v27 raw files for the same blank-survey-
  question pattern as the prereg fix above
