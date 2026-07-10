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

## 02_combine_data.do status

Matches R's dataForMichael.csv on all 2212 rows and 25 columns, except the
16 rows explained by Issue 4 and 8 cells explained by Issue 5.

## 03_sampling_sequences.do status

Matches R's samplingSequences_long.csv on all 29036 rows across all 4
experiments, and on every content column (outcomeA, outcomeB, spread,
viewTime, choiceB, nPairs, isLastPair). Only difference is whichFirst and
a3Col showing blank vs "NA" text, explained by Issue 5.

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

import delimited defaults decimal columns to float on reimport regardless
of source precision. Fixed by adding the asdouble option to every import
in 02_combine_data.do and 03_sampling_sequences.do.

## Issue 4: v11 fan-out bug (accepted, not replicated)

R's join logic multiplies rows for one participant with multiple raw
submissions, producing 9 extra rows per round in R only. Not replicated
in Stata, matching R's own dedup approach used elsewhere.

## Issue 5: NA text vs blank string for absent columns (accepted, cosmetic)

When a column does not apply to an experiment (riskTaking etc for 2
prereg participants, or whichFirst/a3Col for prereg and v17 rows), R's
bind_rows/rbind fills it with NA and writes it as literal "NA" text,
while Stata leaves it blank. Both represent the same missing value, no
downstream figure script reads these columns, accepted with no fix.

## Issue 6: stray Qualtrics text row in prereg viewTimes export (accepted, worked around)

clean_prereg's raw viewTimes export intends to drop the Qualtrics
question-text row via "keep if view1 != ''", but Timing/Page-Submit
questions put descriptive text there instead of blank, so the row
survives into prereg_short_stata.csv and prereg_long_stata.csv. R is
unaffected since as.numeric() silently turns the text row to NA and
filter(!is.na()) drops it. 03_sampling_sequences.do reproduces the same
defensive handling by importing view* as string and converting with
real() before dropping missing rows, so no fix to 01_clean_raw_data.do
was needed.


