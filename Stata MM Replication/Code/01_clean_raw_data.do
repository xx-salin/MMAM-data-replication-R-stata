* ------- 01 clean raw data -------
* ---------------------------------
do "C:\Users\salins4\OneDrive - Aalto University\Desktop\Stata MM Replication\Code\00_setup.do"

local v5file "$RAW\Alex Imas - Michael Ungeheuer - Description Experience v5_December 20, 2023_09.23.csv"
display "`v5file'"
import delimited "`v5file'", clear varnames(nonames) case(preserve) bindquote(strict) stringcols(_all)


* --- rename needed columns by position (positions verified against the actual file) ---
rename v1 StartDate
rename v4 duration
rename v35 id
rename v311 desc_choice_r1_DO
rename v350 desc_choice_r1_DO_1
rename v372 desc_choice_r2_DO
rename v411 desc_choice_r2_DO_1
rename v312 desc_choice_str_r1
rename v351 desc_choice_str_r1_1
rename v373 desc_choice_str_r2
rename v412 desc_choice_str_r2_1
rename v317 beliefs_r1_1_1
rename v333 beliefs_r1_1_1_1
rename v318 beliefs_r1_1_2
rename v334 beliefs_r1_1_2_1
rename v320 beliefs_alt1_r1_1
rename v336 beliefs_alt1_r1_1_1
rename v321 beliefs_alt1_r1_2
rename v337 beliefs_alt1_r1_2_1
rename v322 beliefs_alt1_r1_3
rename v338 beliefs_alt1_r1_3_1
rename v323 beliefs_alt2_r1_1
rename v339 beliefs_alt2_r1_1_1
rename v324 beliefs_alt2_r1_2
rename v340 beliefs_alt2_r1_2_1
rename v325 beliefs_alt2_r1_3
rename v341 beliefs_alt2_r1_3_1
rename v378 beliefs_r2_1_1
rename v394 beliefs_r2_1_1_1
rename v379 beliefs_r2_1_2
rename v395 beliefs_r2_1_2_1
rename v381 beliefs_alt1_r2_1
rename v397 beliefs_alt1_r2_1_1
rename v382 beliefs_alt1_r2_2
rename v398 beliefs_alt1_r2_2_1
rename v383 beliefs_alt1_r2_3
rename v399 beliefs_alt1_r2_3_1
rename v384 beliefs_alt2_r2_1
rename v400 beliefs_alt2_r2_1_1
rename v385 beliefs_alt2_r2_2
rename v401 beliefs_alt2_r2_2_1
rename v386 beliefs_alt2_r2_3
rename v402 beliefs_alt2_r2_3_1
rename v416 riskTaking
rename v417 statKnow
rename v418 regretExAnte
rename v419 regretExPost
rename v425 bonus_payment
rename v432 cond_beliefs_choice_order
rename v433 rand_long_short_order
rename v439 choiceB_r1
rename v442 choiceB_r2


* protect id from later width-truncation to missing
recast strL id, force

* --- keep only what we need ---
keep StartDate duration id desc_choice_r1_DO desc_choice_r1_DO_1 desc_choice_r2_DO desc_choice_r2_DO_1 desc_choice_str_r1 desc_choice_str_r1_1 desc_choice_str_r2 desc_choice_str_r2_1 beliefs_* riskTaking statKnow regretExAnte regretExPost bonus_payment cond_beliefs_choice_order rand_long_short_order choiceB_r1 choiceB_r2

* --- filter to real response rows: id must be a genuine 24-char lowercase hex Prolific id ---
keep if regexm(id, "^[0-9a-f]{24}$") & id != "000000000000000000000000"

describe
count
list id StartDate duration riskTaking statKnow choiceB_r1 choiceB_r2 in 1/3, clean

*=============================================================
* Belief-pasting / choice-strength coalescing
*=============================================================
foreach v of varlist beliefs_r1_1_1 beliefs_r1_1_1_1 beliefs_r1_1_2 beliefs_r1_1_2_1 ///
    beliefs_alt1_r1_1 beliefs_alt1_r1_1_1 beliefs_alt1_r1_2 beliefs_alt1_r1_2_1 ///
    beliefs_alt1_r1_3 beliefs_alt1_r1_3_1 beliefs_alt2_r1_1 beliefs_alt2_r1_1_1 ///
    beliefs_alt2_r1_2 beliefs_alt2_r1_2_1 beliefs_alt2_r1_3 beliefs_alt2_r1_3_1 ///
    beliefs_r2_1_1 beliefs_r2_1_1_1 beliefs_r2_1_2 beliefs_r2_1_2_1 ///
    beliefs_alt1_r2_1 beliefs_alt1_r2_1_1 beliefs_alt1_r2_2 beliefs_alt1_r2_2_1 ///
    beliefs_alt1_r2_3 beliefs_alt1_r2_3_1 beliefs_alt2_r2_1 beliefs_alt2_r2_1_1 ///
    beliefs_alt2_r2_2 beliefs_alt2_r2_2_1 beliefs_alt2_r2_3 beliefs_alt2_r2_3_1 ///
    desc_choice_str_r1 desc_choice_str_r1_1 desc_choice_str_r2 desc_choice_str_r2_1 {
    destring `v', replace force
}

capture program drop coalesce_pair
program define coalesce_pair
    args out a b
    gen double `out' = `a' if missing(`b')
    replace `out' = `b' if missing(`a') & !missing(`b')
    count if !missing(`a') & !missing(`b')
    if r(N) > 0 {
        di as error "WARNING: `out' has `r(N)' rows where both `a' and `b' are non-missing (collision — R would set these to NA)"
    }
end

coalesce_pair r1_beliefA  beliefs_r1_1_1      beliefs_r1_1_1_1
coalesce_pair r1_beliefB  beliefs_r1_1_2      beliefs_r1_1_2_1
coalesce_pair r1_beliefA_below beliefs_alt1_r1_1 beliefs_alt1_r1_1_1
coalesce_pair r1_beliefA_equal beliefs_alt1_r1_2 beliefs_alt1_r1_2_1
coalesce_pair r1_beliefA_above beliefs_alt1_r1_3 beliefs_alt1_r1_3_1
coalesce_pair r1_beliefB_below beliefs_alt2_r1_1 beliefs_alt2_r1_1_1
coalesce_pair r1_beliefB_equal beliefs_alt2_r1_2 beliefs_alt2_r1_2_1
coalesce_pair r1_beliefB_above beliefs_alt2_r1_3 beliefs_alt2_r1_3_1
coalesce_pair r1_choice_str    desc_choice_str_r1 desc_choice_str_r1_1

coalesce_pair r2_beliefA  beliefs_r2_1_1      beliefs_r2_1_1_1
coalesce_pair r2_beliefB  beliefs_r2_1_2      beliefs_r2_1_2_1
coalesce_pair r2_beliefA_below beliefs_alt1_r2_1 beliefs_alt1_r2_1_1
coalesce_pair r2_beliefA_equal beliefs_alt1_r2_2 beliefs_alt1_r2_2_1
coalesce_pair r2_beliefA_above beliefs_alt1_r2_3 beliefs_alt1_r2_3_1
coalesce_pair r2_beliefB_below beliefs_alt2_r2_1 beliefs_alt2_r2_1_1
coalesce_pair r2_beliefB_equal beliefs_alt2_r2_2 beliefs_alt2_r2_2_1
coalesce_pair r2_beliefB_above beliefs_alt2_r2_3 beliefs_alt2_r2_3_1
coalesce_pair r2_choice_str    desc_choice_str_r2 desc_choice_str_r2_1

summarize r1_beliefA r1_beliefB r2_beliefA r2_beliefB r1_choice_str r2_choice_str
describe id
count if missing(id)
list id r1_beliefA r1_beliefB r2_beliefA r2_beliefB in 1/5, clean



* --- whichFirst: mirrors R's case_when on str_ends(DO, "A"/"B") ---
gen whichFirst_r1 = ""
replace whichFirst_r1 = "B" if substr(desc_choice_r1_DO_1, -1, 1) == "A"
replace whichFirst_r1 = "A" if whichFirst_r1 == "" & substr(desc_choice_r1_DO_1, -1, 1) == "B"
replace whichFirst_r1 = "B" if whichFirst_r1 == "" & substr(desc_choice_r1_DO, -1, 1) == "A"
replace whichFirst_r1 = "A" if whichFirst_r1 == "" & substr(desc_choice_r1_DO, -1, 1) == "B"

gen whichFirst_r2 = ""
replace whichFirst_r2 = "B" if substr(desc_choice_r2_DO_1, -1, 1) == "A"
replace whichFirst_r2 = "A" if whichFirst_r2 == "" & substr(desc_choice_r2_DO_1, -1, 1) == "B"
replace whichFirst_r2 = "B" if whichFirst_r2 == "" & substr(desc_choice_r2_DO, -1, 1) == "A"
replace whichFirst_r2 = "A" if whichFirst_r2 == "" & substr(desc_choice_r2_DO, -1, 1) == "B"

* --- choiceB: destring, then R's `as.numeric(choiceB) - 1` ---
destring choiceB_r1, replace force
destring choiceB_r2, replace force
gen choiceB_r1_final = choiceB_r1 - 1
gen choiceB_r2_final = choiceB_r2 - 1

list id whichFirst_r1 choiceB_r1_final in 1/5, clean


* --- destring remaining numeric-looking columns still held as string ---
destring riskTaking statKnow regretExAnte regretExPost duration, replace force

* --- build round 1 block with canonical column names ---
tempfile round1 round2

preserve
    gen round = 1
    gen short = (rand_long_short_order == "short_first")
    rename whichFirst_r1 whichFirst
    rename choiceB_r1_final choiceB
    rename r1_beliefA beliefA
    rename r1_beliefB beliefB
    rename r1_beliefA_below beliefA_below
    rename r1_beliefA_equal beliefA_equal
    rename r1_beliefA_above beliefA_above
    rename r1_beliefB_below beliefB_below
    rename r1_beliefB_equal beliefB_equal
    rename r1_beliefB_above beliefB_above
    rename r1_choice_str choiceStr
    keep id bonus_payment choiceB cond_beliefs_choice_order riskTaking statKnow regretExAnte regretExPost duration beliefA beliefB beliefA_below beliefA_equal beliefA_above beliefB_below beliefB_equal beliefB_above choiceStr whichFirst short round
    save `round1'
restore

preserve
    gen round = 2
    gen short = (rand_long_short_order != "short_first")
    rename whichFirst_r2 whichFirst
    rename choiceB_r2_final choiceB
    rename r2_beliefA beliefA
    rename r2_beliefB beliefB
    rename r2_beliefA_below beliefA_below
    rename r2_beliefA_equal beliefA_equal
    rename r2_beliefA_above beliefA_above
    rename r2_beliefB_below beliefB_below
    rename r2_beliefB_equal beliefB_equal
    rename r2_beliefB_above beliefB_above
    rename r2_choice_str choiceStr
    keep id bonus_payment choiceB cond_beliefs_choice_order riskTaking statKnow regretExAnte regretExPost duration beliefA beliefB beliefA_below beliefA_equal beliefA_above beliefB_below beliefB_equal beliefB_above choiceStr whichFirst short round
    save `round2'
restore

use `round1', clear
append using `round2'

* --- na.omit() equivalent: drop any row missing on any analysis column ---
egen nmiss = rowmiss(bonus_payment choiceB cond_beliefs_choice_order riskTaking statKnow regretExAnte regretExPost duration beliefA beliefB beliefA_below beliefA_equal beliefA_above beliefB_below beliefB_equal beliefB_above choiceStr whichFirst short round)
drop if nmiss > 0
drop nmiss

count
sort round id
list id round choiceB beliefA beliefB whichFirst in 1/5, clean



* --- import Prolific demographics (position-based) ---
tempfile prolific

preserve
    import delimited "$PROLIFIC\v5Prolific_1.csv", clear varnames(nonames) case(preserve) bindquote(strict) stringcols(_all)
    drop if _n == 1
    rename v1 id
    rename v2 age
    rename v3 sex
    rename v4 student
    recast str24 id
    tempfile p1
    save `p1'

    import delimited "$PROLIFIC\v5Prolific_2.csv", clear varnames(nonames) case(preserve) bindquote(strict) stringcols(_all)
    drop if _n == 1
    rename v1 id
    rename v2 age
    rename v3 sex
    rename v4 student
    recast str24 id
    append using `p1'
    save `prolific'
restore

* --- narrow id back to fixed width now that it's safely clean, so merge can use it as a key ---
recast str24 id

* --- join prolific onto the round1+round2 stack (mirrors inner_join(id)) ---
merge m:1 id using `prolific', keep(match) nogenerate

* --- write_clean(): drop revoked consent, stamp df label ---
drop if student == "CONSENT_REVOKED"
gen df = "v5"

count
sort round id
list id round choiceB beliefA beliefB whichFirst student age sex in 1/5, clean

* --- Export V5
export delimited using "$CLEAN\v5_stata.csv", replace
