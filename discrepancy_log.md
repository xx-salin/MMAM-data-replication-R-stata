# Discrepancy Log

Tracks intentional deviations and bugs found while porting the R data
cleaning pipeline to Stata.

## 01_clean_raw_data.do summary

| File | Family | Status | Notes |
|---|---|---|---|
| v5 | 1 | Match | |
| v13 | 1 | Match | |
| v11 | 1 | Match, documented deviation | 118 vs 134 rows, fan-out bug not replicated |
| v17 | 2 | Match | trial, view times, sampling order |
| v24 | 2 | Match | trial, view times, sampling order |
| v21 | 3 | Match | trial, view times, sampling order |
| v27 | 3 | Match | trial, view times, sampling order, IDs |
| prereg | 4 | Match | trial, view times, sampling order |

## Issue 1: riskTaking/statKnow/regretExAnte/regretExPost treated as numeric (fixed)

R never numeric-casts these fields, so blank stays blank and is never
dropped by na.omit(). Stata was destringing them first, turning blanks
into missing and wrongly dropping complete rows. Fixed by leaving them as
plain strings in all four family programs.

## Issue 2: belief columns losing precision through float32 (fixed)

Belief columns were destrung, which defaults to float and rounds values
like 33.4 to 33.400002. Fixed by parsing with real() into double instead,
in clean_family1/2/3.

## Issue 3: belief precision reintroduced on reimport (fixed)

02_combine_data.do reimported the already-fixed CSVs with import
delimited, which defaults decimal columns back to float. Fixed by adding
the asdouble option to every import in that script.

## Issue 4: v11 fan-out bug (accepted, not replicated)

R's join logic multiplies rows for one participant with multiple raw
submissions, producing 9 extra rows per round in R only. Not replicated
in Stata, matching R's own dedup approach used elsewhere.

## Issue 5: NA text vs blank string in combinedDF (accepted, cosmetic)

Two prereg participants show as blank in Stata but literal "NA" text in
R's combined output, though both sources agree blank at the prereg-file
level. Accepted as an R-side rbind() artifact with no analytical impact.

## 02_combine_data.do status

Matches R's dataForMichael.csv except for the 16 rows from Issue 4 and 8
cells from Issue 5. No other differences found.

