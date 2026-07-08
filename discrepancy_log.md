## v11 — Family 1 duplicate submission fan-out (2026-07-08)

**R behavior:** `clean_two_round_paste()` builds an `orders` table separately
from the main data and joins it back via `inner_join(id)`. For participants
with duplicate raw submissions (id `f11f54084b0ccb5363ba25f7`, 3 submissions),
this creates a 3x3=9-row cartesian fan-out instead of 3 rows.

**Effect:** R's v11.csv contains 134 rows; a faithful 1-row-per-submission
cleaning would produce ~122 rows (18 vs 6 for the affected participant).

**Resolution:** Stata pipeline deduplicates raw submissions by id (keep
first) immediately after import, before the paste-pair logic runs. This
matches the deduplication R already does explicitly in `clean_interference()`
(family 3, v21/v27) but omits in `clean_two_round_paste()` (family 1).

**Decision:** Treated as an R bug, not replicated. Stata output for v11 will
differ from R's v11.csv by design (~122 vs 134 rows). Affects only
participants with duplicate raw survey submissions — check v5/v13/v17/v24/
v21/v27/prereg for the same issue before assuming this is isolated to v11.
