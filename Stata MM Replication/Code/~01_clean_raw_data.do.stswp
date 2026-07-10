



*=============================================================
* 01_clean_raw_data.do
* Run after 00_setup.do has set $ROOT $RAW $PROLIFIC $CLEAN
*=============================================================

do "00_setup.do"

*=============================================================
*        Family 1: paste-pair beliefs (v5, v13, v11)
*=============================================================

*-------------------------------------------------------------
* Helper: coalesce a pasted pair of columns into one, flagging
* any true collisions (both non-missing, R would set these NA)
*-------------------------------------------------------------
capture program drop coalesce_pair
program define coalesce_pair
    args out a b
    gen double `out' = `a' if missing(`b')
    replace `out' = `b' if missing(`a') & !missing(`b')
    count if !missing(`a') & !missing(`b')
    if r(N) > 0 {
        di as error "WARNING: `out' has `r(N)' rows where both `a' and `b' are non-missing"
    }
end

*-------------------------------------------------------------
* Helper: import + standardize one Prolific demographics file
*-------------------------------------------------------------
capture program drop load_one_prolific
program define load_one_prolific
    args fname
    import delimited "$PROLIFIC/`fname'", clear varnames(nonames) case(preserve) bindquote(strict) stringcols(_all)
    drop if _n == 1
    rename v1 id
    rename v2 age
    rename v3 sex
    rename v4 student
    recast str24 id
end

*-------------------------------------------------------------
* Main Family 1 cleaner (mirrors R's clean_two_round_paste())
*   args: rawfile output pos1(choiceB_r1) pos2(choiceB_r2) oddpos("" if none) prolifictmp
*-------------------------------------------------------------
capture program drop clean_family1
program define clean_family1
    args rawfile output pos1 pos2 oddpos prolifictmp

    import delimited "`rawfile'", clear varnames(nonames) case(preserve) bindquote(strict) stringcols(_all)

    * Dedup raw submissions by prolific_id, keeping the FIRST submission in
    * original file order (R's clean_two_round_paste omits this dedup,
    * unlike clean_interference, see discrepancy_log.md). sort id alone is
    * NOT stable in Stata, so we force a deterministic tiebreak.
    gen long _orig_order = _n
    sort v35 _orig_order
    by v35: keep if _n == 1
    drop _orig_order

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
    rename v`pos1' choiceB_r1
    rename v`pos2' choiceB_r2

    if "`oddpos'" != "" {
        rename v`oddpos' oddState
    }

    recast strL id

    local keepvars "StartDate duration id desc_choice_r1_DO desc_choice_r1_DO_1 desc_choice_r2_DO desc_choice_r2_DO_1 desc_choice_str_r1 desc_choice_str_r1_1 desc_choice_str_r2 desc_choice_str_r2_1 beliefs_* riskTaking statKnow regretExAnte regretExPost bonus_payment cond_beliefs_choice_order rand_long_short_order choiceB_r1 choiceB_r2"
    if "`oddpos'" != "" local keepvars "`keepvars' oddState"
    keep `keepvars'

    keep if regexm(id, "^[0-9a-f]{24}$") & id != "000000000000000000000000"

    * Standard fields safe to destring to float (no precision concerns)
    destring duration, replace force

    * riskTaking/statKnow/regretExAnte/regretExPost: R NEVER numeric-casts
    * these (they stay character throughout). Do NOT destring, leave as raw
    * imported string so blank "" is preserved (not Stata missing) and any
    * literal "NA" text round-trips exactly as R's read.csv()/write.csv()
    * would produce. Excluded from the nmiss check below for the same reason
    * (see Family 4 clean_prereg for the pattern this mirrors).

    * Belief + choice-strength paste-pair source columns: destring rounds to
    * float32 BEFORE coalesce_pair can widen it, permanently losing precision
    * (same issue as view times, see discrepancy_log.md). Parse to double
    * via real() instead of destring.
    foreach v of varlist beliefs_r1_1_1 beliefs_r1_1_1_1 beliefs_r1_1_2 beliefs_r1_1_2_1 ///
        beliefs_alt1_r1_1 beliefs_alt1_r1_1_1 beliefs_alt1_r1_2 beliefs_alt1_r1_2_1 ///
        beliefs_alt1_r1_3 beliefs_alt1_r1_3_1 beliefs_alt2_r1_1 beliefs_alt2_r1_1_1 ///
        beliefs_alt2_r1_2 beliefs_alt2_r1_2_1 beliefs_alt2_r1_3 beliefs_alt2_r1_3_1 ///
        beliefs_r2_1_1 beliefs_r2_1_1_1 beliefs_r2_1_2 beliefs_r2_1_2_1 ///
        beliefs_alt1_r2_1 beliefs_alt1_r2_1_1 beliefs_alt1_r2_2 beliefs_alt1_r2_2_1 ///
        beliefs_alt1_r2_3 beliefs_alt1_r2_3_1 beliefs_alt2_r2_1 beliefs_alt2_r2_1_1 ///
        beliefs_alt2_r2_2 beliefs_alt2_r2_2_1 beliefs_alt2_r2_3 beliefs_alt2_r2_3_1 ///
        desc_choice_str_r1 desc_choice_str_r1_1 desc_choice_str_r2 desc_choice_str_r2_1 {
        gen double _tmp_`v' = real(`v')
        drop `v'
        rename _tmp_`v' `v'
    }

    coalesce_pair r1_beliefA        beliefs_r1_1_1      beliefs_r1_1_1_1
    coalesce_pair r1_beliefB        beliefs_r1_1_2      beliefs_r1_1_2_1
    coalesce_pair r1_beliefA_below  beliefs_alt1_r1_1   beliefs_alt1_r1_1_1
    coalesce_pair r1_beliefA_equal  beliefs_alt1_r1_2   beliefs_alt1_r1_2_1
    coalesce_pair r1_beliefA_above  beliefs_alt1_r1_3   beliefs_alt1_r1_3_1
    coalesce_pair r1_beliefB_below  beliefs_alt2_r1_1   beliefs_alt2_r1_1_1
    coalesce_pair r1_beliefB_equal  beliefs_alt2_r1_2   beliefs_alt2_r1_2_1
    coalesce_pair r1_beliefB_above  beliefs_alt2_r1_3   beliefs_alt2_r1_3_1
    coalesce_pair r1_choice_str     desc_choice_str_r1  desc_choice_str_r1_1

    coalesce_pair r2_beliefA        beliefs_r2_1_1      beliefs_r2_1_1_1
    coalesce_pair r2_beliefB        beliefs_r2_1_2      beliefs_r2_1_2_1
    coalesce_pair r2_beliefA_below  beliefs_alt1_r2_1   beliefs_alt1_r2_1_1
    coalesce_pair r2_beliefA_equal  beliefs_alt1_r2_2   beliefs_alt1_r2_2_1
    coalesce_pair r2_beliefA_above  beliefs_alt1_r2_3   beliefs_alt1_r2_3_1
    coalesce_pair r2_beliefB_below  beliefs_alt2_r2_1   beliefs_alt2_r2_1_1
    coalesce_pair r2_beliefB_equal  beliefs_alt2_r2_2   beliefs_alt2_r2_2_1
    coalesce_pair r2_beliefB_above  beliefs_alt2_r2_3   beliefs_alt2_r2_3_1
    coalesce_pair r2_choice_str     desc_choice_str_r2  desc_choice_str_r2_1

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

    destring choiceB_r1 choiceB_r2, replace force
    gen choiceB_r1_final = choiceB_r1 - 1
    gen choiceB_r2_final = choiceB_r2 - 1

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
        local kv "id bonus_payment choiceB cond_beliefs_choice_order riskTaking statKnow regretExAnte regretExPost duration beliefA beliefB beliefA_below beliefA_equal beliefA_above beliefB_below beliefB_equal beliefB_above choiceStr whichFirst short round"
        if "`oddpos'" != "" local kv "`kv' oddState"
        keep `kv'
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
        local kv "id bonus_payment choiceB cond_beliefs_choice_order riskTaking statKnow regretExAnte regretExPost duration beliefA beliefB beliefA_below beliefA_equal beliefA_above beliefB_below beliefB_equal beliefB_above choiceStr whichFirst short round"
        if "`oddpos'" != "" local kv "`kv' oddState"
        keep `kv'
        save `round2'
    restore

    use `round1', clear
    append using `round2'

    * na.omit()-equivalent, riskTaking/statKnow/regretExAnte/regretExPost
    * deliberately excluded (see note above the destring line)
    local misscols "bonus_payment choiceB cond_beliefs_choice_order duration beliefA beliefB beliefA_below beliefA_equal beliefA_above beliefB_below beliefB_equal beliefB_above choiceStr whichFirst short round"
    if "`oddpos'" != "" local misscols "`misscols' oddState"
    egen nmiss = rowmiss(`misscols')
    drop if nmiss > 0
    drop nmiss

    recast str24 id
    merge m:1 id using "`prolifictmp'", keep(match) nogenerate

    drop if student == "CONSENT_REVOKED"
    capture drop df
    gen df = "`output'"

    export delimited using "$CLEAN/`output'_stata.csv", replace
    di as result "==== `output' complete: " _N " rows ===="
end

*-------------------------------------------------------------
* Build Prolific demographic files (per experiment)
*-------------------------------------------------------------
load_one_prolific "v5Prolific_1.csv"
tempfile v5p1
save `v5p1'
load_one_prolific "v5Prolific_2.csv"
append using `v5p1'
tempfile prolific_v5
save `prolific_v5'

load_one_prolific "v13Prolific.csv"
tempfile prolific_v13
save `prolific_v13'

load_one_prolific "v11Prolific.csv"
tempfile prolific_v11
save `prolific_v11'

*-------------------------------------------------------------
* Run Family 1
*-------------------------------------------------------------
local v5file  "$RAW\Alex Imas - Michael Ungeheuer - Description Experience v5_December 20, 2023_09.23.csv"
local v13file "$RAW\Alex Imas - Michael Ungeheuer - Description Experience v13_December 20, 2023_09.55.csv"
local v11file "$RAW\Alex Imas - Michael Ungeheuer - Description Experience v11_December 20, 2023_10.05.csv"

clean_family1 "`v5file'"  "v5"  439 442 ""    "`prolific_v5'"
clean_family1 "`v13file'" "v13" 440 443 ""    "`prolific_v13'"
clean_family1 "`v11file'" "v11" 440 443 439   "`prolific_v11'"





*=============================================================
* Family 2: one-round, single-column belief format  (v17, v24)
*=============================================================

capture program drop clean_family2
program define clean_family2
    args rawfile output p_bonus p_choicedo p_choiceb p_choicestr p_rand p_cond p_q1 p_q2 p_b1 p_b2 p_b3 p_b4 p_b5 p_b6 p_risk p_stat p_regretante p_regretpost p_sampling p_viewstart p_viewn prolifictmp

    import delimited "`rawfile'", clear varnames(nonames) case(preserve) bindquote(strict) stringcols(_all)

    * Dedup raw submissions by id, keeping first-in-file-order (see discrepancy_log.md)
    gen long _orig_order = _n
    sort v35 _orig_order
    by v35: keep if _n == 1
    drop _orig_order

    rename v1 StartDate
    rename v4 duration
    rename v35 id
    rename v`p_bonus' bonus_payment
    rename v`p_choicedo' choice_round_1_DO
    rename v`p_choiceb' choiceB_r1
    rename v`p_choicestr' choice_strength_r1
    rename v`p_rand' rand_long_short_order
    rename v`p_cond' cond_beliefs_choice_order
    rename v`p_q1' Q14_1_1
    rename v`p_q2' Q14_1_2
    rename v`p_b1' r1beliefs_alt1_1
    rename v`p_b2' r1beliefs_alt1_2
    rename v`p_b3' r1beliefs_alt1_3
    rename v`p_b4' r1beliefs_alt2_1
    rename v`p_b5' r1beliefs_alt2_2
    rename v`p_b6' r1beliefs_alt2_3
    rename v`p_risk' riskTaking
    rename v`p_stat' statKnow
    rename v`p_regretante' regretExAnte
    rename v`p_regretpost' regretExPost
    rename v`p_sampling' round1_combined_array

    local viewpos `p_viewstart'
    local viewlist ""
    forvalues i = 1/`p_viewn' {
        rename v`viewpos' view`i'
        local viewlist "`viewlist' view`i'"
        local viewpos = `viewpos' + 4
    }

    recast strL id

    keep StartDate duration id bonus_payment choice_round_1_DO choiceB_r1 choice_strength_r1 rand_long_short_order cond_beliefs_choice_order Q14_1_1 Q14_1_2 r1beliefs_alt1_1 r1beliefs_alt1_2 r1beliefs_alt1_3 r1beliefs_alt2_1 r1beliefs_alt2_2 r1beliefs_alt2_3 riskTaking statKnow regretExAnte regretExPost round1_combined_array `viewlist'

    keep if regexm(id, "^[0-9a-f]{24}$") & id != "000000000000000000000000"

    * Standard fields safe to destring to float
    destring duration choice_strength_r1 choiceB_r1, replace force

    * riskTaking/statKnow/regretExAnte/regretExPost: never numeric-cast in R —
    * leave as raw string (do not destring). Excluded from nmiss below.

    * Belief columns: parse to double via real(), not destring (avoids float32 loss).
    foreach v of varlist Q14_1_1 Q14_1_2 r1beliefs_alt1_1 r1beliefs_alt1_2 r1beliefs_alt1_3 r1beliefs_alt2_1 r1beliefs_alt2_2 r1beliefs_alt2_3 {
        gen double _tmp_`v' = real(`v')
        drop `v'
        rename _tmp_`v' `v'
    }

    rename Q14_1_1 beliefA
    rename Q14_1_2 beliefB
    rename r1beliefs_alt1_1 beliefA_below
    rename r1beliefs_alt1_2 beliefA_equal
    rename r1beliefs_alt1_3 beliefA_above
    rename r1beliefs_alt2_1 beliefB_below
    rename r1beliefs_alt2_2 beliefB_equal
    rename r1beliefs_alt2_3 beliefB_above
    rename choice_strength_r1 choiceStr

    gen whichFirst = ""
    replace whichFirst = "B" if substr(choice_round_1_DO, -1, 1) == "A"
    replace whichFirst = "A" if whichFirst == "" & substr(choice_round_1_DO, -1, 1) == "B"

    gen choiceB = choiceB_r1 - 1
    gen short = (rand_long_short_order == "short_first")
    gen round = 1

    egen nmiss = rowmiss(bonus_payment choiceB cond_beliefs_choice_order duration beliefA beliefB beliefA_below beliefA_equal beliefA_above beliefB_below beliefB_equal beliefB_above choiceStr whichFirst short round)
    drop if nmiss > 0
    drop nmiss

    recast str24 id
    merge m:1 id using "`prolifictmp'", keep(match) nogenerate

    drop if student == "CONSENT_REVOKED"
    capture drop df
    gen df = "`output'"

    preserve
        keep id bonus_payment choiceB cond_beliefs_choice_order riskTaking statKnow regretExAnte regretExPost duration beliefA beliefB beliefA_below beliefA_equal beliefA_above beliefB_below beliefB_equal beliefB_above choiceStr whichFirst short round `viewlist' rand_long_short_order age sex student df
        export delimited using "$CLEAN/`output'_stata.csv", replace
    restore

    * Separate viewTimes export (R writes this in addition to embedding
    * views in the main trial file), reuses the already-cleaned data,
    * no fresh import needed since row-filtering rules are identical.
    preserve
        keep id `viewlist' df
        export delimited using "$CLEAN/viewTimes/`output'_stata.csv", replace
    restore

    *-----------------------------------------------------------
    * Sampling order: FRESH, undeduped raw import (matches R's
    * separate read_raw(input) call for sampOrder). Same offset
    * logic as prereg/Family3: drop original rows 1-3 (Stata's
    * header-as-data artifact, question-text row, and ImportId row).
    *-----------------------------------------------------------
    preserve
        import delimited "`rawfile'", clear varnames(nonames) case(preserve) bindquote(strict) stringcols(_all)
        gen long _n_orig = _n
        drop if _n_orig <= 3
        drop _n_orig
        rename v35 id
        rename v`p_sampling' round1_combined_array
        keep id round1_combined_array
        gen df = "`output'"
        export delimited using "$CLEAN/Sampling Order/`output'_stata.csv", replace
    restore

    di as result "==== `output' complete: " _N " rows ===="
end

*-------------------------------------------------------------
* Build Prolific files + run Family 2
*-------------------------------------------------------------
tempfile prolific_v17
import delimited "$PROLIFIC\v17Prolific.csv", clear varnames(nonames) case(preserve) bindquote(strict) stringcols(_all)
drop if _n == 1
rename v1 id
rename v2 age
rename v3 sex
rename v4 student
recast str24 id
save `prolific_v17'

tempfile prolific_v24
import delimited "$PROLIFIC\v24Prolific.csv", clear varnames(nonames) case(preserve) bindquote(strict) stringcols(_all)
drop if _n == 1
rename v1 id
rename v2 age
rename v3 sex
rename v4 student
recast str24 id
save `prolific_v24'

local v17file "$RAW\Alex Imas - Michael Ungeheuer - Description Experience v17_December 20, 2023_10.10.csv"
local v24file "$RAW\Alex Imas - Michael Ungeheuer - Description Experience v24_December 26, 2023_15.45.csv"

clean_family2 "`v17file'" "v17" 440 292 457 293 450 449 294 295 297 298 299 300 301 302 431 432 433 434 454 45 11 "`prolific_v17'"
clean_family2 "`v24file'" "v24" 393 260 408 261 401 400 262 263 265 266 267 268 269 270 384 385 386 387 405 45 3  "`prolific_v24'"



*=============================================================
* Family 3: interference experiments (v21, v27)
*=============================================================

capture program drop clean_family3
program define clean_family3
    args rawfile output trials_name views_name sampling_name write_ids prolifictmp

    import delimited "`rawfile'", clear varnames(nonames) case(preserve) bindquote(strict) stringcols(_all)

    rename v1 StartDate
    rename v4 duration
    rename v35 id
    rename v469 bonus_payment
    rename v336 choice_round_1_DO
    rename v490 choiceB_r1
    rename v337 choice_strength_r1
    rename v479 rand_long_short_order
    rename v478 cond_beliefs_choice_order
    rename v338 Q14_1_1
    rename v339 Q14_1_2
    rename v341 r1beliefs_alt1_1
    rename v342 r1beliefs_alt1_2
    rename v343 r1beliefs_alt1_3
    rename v344 r1beliefs_alt2_1
    rename v345 r1beliefs_alt2_2
    rename v346 r1beliefs_alt2_3
    rename v460 riskTaking
    rename v461 statKnow
    rename v462 regretExAnte
    rename v463 regretExPost
    rename v483 round1_combined_array
    rename v486 a3Col

    local bluepos 89
    local orangepos 45
    forvalues i = 1/11 {
        rename v`bluepos' viewBlue`i'
        rename v`orangepos' viewOrange`i'
        local bluepos = `bluepos' + 4
        local orangepos = `orangepos' + 4
    }

    * Dedup raw submissions by id, keeping first-in-file-order
    * (matches R's own distinct(id, .keep_all=TRUE), but done early here)
    gen long _orig_order = _n
    sort id _orig_order
    by id: keep if _n == 1
    drop _orig_order

    recast strL id

    keep StartDate duration id bonus_payment choice_round_1_DO choiceB_r1 choice_strength_r1 rand_long_short_order cond_beliefs_choice_order Q14_1_1 Q14_1_2 r1beliefs_alt1_1 r1beliefs_alt1_2 r1beliefs_alt1_3 r1beliefs_alt2_1 r1beliefs_alt2_2 r1beliefs_alt2_3 riskTaking statKnow regretExAnte regretExPost round1_combined_array a3Col viewBlue1-viewBlue11 viewOrange1-viewOrange11

    keep if regexm(id, "^[0-9a-f]{24}$") & id != "000000000000000000000000"

    * Standard fields safe to destring to float
    destring duration choice_strength_r1 choiceB_r1, replace force

    * riskTaking/statKnow/regretExAnte/regretExPost: never numeric-cast in R —
    * leave as raw string (do not destring). Excluded from nmiss below.

    * Belief columns: parse to double via real(), not destring (avoids float32 loss).
    foreach v of varlist Q14_1_1 Q14_1_2 r1beliefs_alt1_1 r1beliefs_alt1_2 r1beliefs_alt1_3 r1beliefs_alt2_1 r1beliefs_alt2_2 r1beliefs_alt2_3 {
        gen double _tmp_`v' = real(`v')
        drop `v'
        rename _tmp_`v' `v'
    }

    * View-time columns: destring rounds to float32 BEFORE recast can widen it,
    * permanently losing precision (see discrepancy_log.md). Parse directly to
    * double via real() instead of destring, to avoid the float round-trip.
    foreach v of varlist viewBlue1-viewBlue11 viewOrange1-viewOrange11 {
        gen double _tmp_`v' = real(`v')
        drop `v'
        rename _tmp_`v' `v'
    }

    rename Q14_1_1 beliefA
    rename Q14_1_2 beliefB
    rename r1beliefs_alt1_1 beliefA_below
    rename r1beliefs_alt1_2 beliefA_equal
    rename r1beliefs_alt1_3 beliefA_above
    rename r1beliefs_alt2_1 beliefB_below
    rename r1beliefs_alt2_2 beliefB_equal
    rename r1beliefs_alt2_3 beliefB_above
    rename choice_strength_r1 choiceStr

    * whichFirst: HTML color-order detection (two-branch, no blank fallback)
    gen whichFirst = "B"
    replace whichFirst = "A" if regexm(choice_round_1_DO, "background-color: DodgerBlue.*background-color: orange")

    gen choiceB = choiceB_r1 - 1
    gen short = (rand_long_short_order == "short_first")
    gen round = 1

    * na.omit() on core columns only, BEFORE view-time coalescing, matching R's
    * order of operations. riskTaking/statKnow/regretExAnte/regretExPost
    * deliberately excluded (see note above the destring line).
    egen nmiss = rowmiss(bonus_payment choiceB cond_beliefs_choice_order duration beliefA beliefB beliefA_below beliefA_equal beliefA_above beliefB_below beliefB_equal beliefB_above choiceStr whichFirst a3Col short round)
    drop if nmiss > 0
    drop nmiss

    * coalesce Blue/Orange view blocks row-wise (equivalent to R's rbind + inner_join by id)
    forvalues i = 1/11 {
        gen double view`i' = viewBlue`i' if !missing(viewBlue`i')
        replace view`i' = viewOrange`i' if missing(view`i') & !missing(viewOrange`i')
    }
    drop viewBlue1-viewBlue11 viewOrange1-viewOrange11

    * inner_join(viewTimes) equivalent: drop participants with no view data in either block
    drop if missing(view1)

    recast str24 id
    merge m:1 id using "`prolifictmp'", keep(match) nogenerate

    drop if student == "CONSENT_REVOKED"

    * final distinct(id) safety net (no-op given early dedup, kept for parity with R)
    duplicates drop id, force

    capture drop df
    gen df = "`output'"

    preserve
        keep id bonus_payment choiceB cond_beliefs_choice_order riskTaking statKnow regretExAnte regretExPost duration beliefA beliefB beliefA_below beliefA_equal beliefA_above beliefB_below beliefB_equal beliefB_above choiceStr whichFirst a3Col short round rand_long_short_order age sex student view1 view2 view3 view4 view5 view6 view7 view8 view9 view10 view11 df
        export delimited using "$CLEAN/`trials_name'_stata.csv", replace
    restore

    preserve
        keep id view1 view2 view3 view4 view5 view6 view7 view8 view9 view10 view11 df
        export delimited using "$CLEAN/viewTimes/`views_name'_stata.csv", replace
    restore

    if "`write_ids'" == "1" {
        preserve
            keep id
            export delimited using "$CLEAN/`output'_IDs_stata.csv", replace
        restore
    }

    *-----------------------------------------------------------
    * Sampling order: FRESH, undeduped raw import (matches R's
    * separate read_raw(input) call for sampOrder, same offset
    * logic as prereg: drop the header-as-data artifact (Stata-only,
    * from varnames(nonames)), the question-text row, and the
    * ImportId row (R's read_raw()'s built-in [-2,]), then apply
    * sampOrder's own [-1,] drop, net: drop original rows 1-3.
    *-----------------------------------------------------------
    preserve
        import delimited "`rawfile'", clear varnames(nonames) case(preserve) bindquote(strict) stringcols(_all)
        gen long _n_orig = _n
        drop if _n_orig <= 3
        drop _n_orig
        rename v35 id
        rename v483 round1_combined_array
        keep id round1_combined_array
        gen df = "`output'"
        export delimited using "$CLEAN/Sampling Order/`sampling_name'_stata.csv", replace
    restore

    di as result "==== `output' complete: " _N " rows ===="
end

*-------------------------------------------------------------
* Prolific + run Family 3
*-------------------------------------------------------------
tempfile prolific_v21
import delimited "$PROLIFIC\v21Prolific.csv", clear varnames(nonames) case(preserve) bindquote(strict) stringcols(_all)
drop if _n == 1
rename v1 id
rename v2 age
rename v3 sex
rename v4 student
recast str24 id
save `prolific_v21'

tempfile prolific_v27
import delimited "$PROLIFIC\v27Prolific.csv", clear varnames(nonames) case(preserve) bindquote(strict) stringcols(_all)
drop if _n == 1
rename v1 id
rename v2 age
rename v3 sex
rename v4 student
recast str24 id
save `prolific_v27'

local v21file "$RAW\Alex Imas - Michael Ungeheuer - Description Experience v21_December 20, 2023_10.36.csv"
local v27file "$RAW\Alex Imas - Michael Ungeheuer - Description Experience v27_January 8, 2024_14.40.csv"

clean_family3 "`v21file'" "v21" "v21" "v21" "v21" "0" "`prolific_v21'"
clean_family3 "`v27file'" "v27" "v27_trials" "v27_views" "v27_sampling" "1" "`prolific_v27'"




*=============================================================
* Family 4:     pre-registered experiment (prereg)
*     unchanged: already uses real()+double for beliefs and
*       already excludes riskTaking/statKnow/regretExAnte/regretExPost
*       from its nmiss check. If your last prereg_stata.csv export
*       predates this file, re-export it before re-diffing.
*=============================================================


capture program drop coalesce_triple
program define coalesce_triple
    args out a b c
    gen str200 _tmp = `a'
    replace _tmp = `b' if _tmp == ""
    replace _tmp = `c' if _tmp == ""
    count if (`a' != "" & `b' != "") | (`a' != "" & `c' != "") | (`b' != "" & `c' != "")
    if r(N) > 0 {
        di as error "WARNING: `out' has `r(N)' rows where more than one of `a'/`b'/`c' is non-blank"
    }
    gen double `out' = real(_tmp)
    drop _tmp
end

capture program drop clean_prereg
program define clean_prereg
    args rawfile prolifictmp

    import delimited "`rawfile'", clear varnames(nonames) case(preserve) bindquote(strict) stringcols(_all)

    rename v1 StartDate
    rename v4 duration
    rename v36 id
    rename v426 bonus_payment
    rename v293 choice_round_1_DO
    rename v354 choice_round_2_DO
    rename v312 desc_choice_r1_DO
    rename v351 desc_choice_r1_DO_1
    rename v373 desc_choice_r2_DO
    rename v412 desc_choice_r2_DO_1
    rename v440 choiceB_r1
    rename v443 choiceB_r2
    rename v294 choice_strength_r1
    rename v313 desc_choice_str_r1
    rename v352 desc_choice_str_r1_1
    rename v355 choice_strength_r2
    rename v374 desc_choice_str_r2
    rename v413 desc_choice_str_r2_1
    rename v432 cond_presentation
    rename v433 cond_beliefs_choice_order
    rename v434 rand_long_short_order
    rename v295 Q14_1_1
    rename v296 Q14_1_2
    rename v356 Q81_1_1
    rename v357 Q81_1_2
    rename v318 beliefs_r1_1_1
    rename v334 beliefs_r1_1_1_1
    rename v319 beliefs_r1_1_2
    rename v335 beliefs_r1_1_2_1
    rename v379 beliefs_r2_1_1
    rename v395 beliefs_r2_1_1_1
    rename v380 beliefs_r2_1_2
    rename v396 beliefs_r2_1_2_1
    rename v321 beliefs_alt1_r1_1
    rename v322 beliefs_alt1_r1_2
    rename v323 beliefs_alt1_r1_3
    rename v337 beliefs_alt1_r1_1_1
    rename v338 beliefs_alt1_r1_2_1
    rename v339 beliefs_alt1_r1_3_1
    rename v298 r1beliefs_alt1_1
    rename v299 r1beliefs_alt1_2
    rename v300 r1beliefs_alt1_3
    rename v324 beliefs_alt2_r1_1
    rename v325 beliefs_alt2_r1_2
    rename v326 beliefs_alt2_r1_3
    rename v340 beliefs_alt2_r1_1_1
    rename v341 beliefs_alt2_r1_2_1
    rename v342 beliefs_alt2_r1_3_1
    rename v301 r1beliefs_alt2_1
    rename v302 r1beliefs_alt2_2
    rename v303 r1beliefs_alt2_3
    rename v382 beliefs_alt1_r2_1
    rename v383 beliefs_alt1_r2_2
    rename v384 beliefs_alt1_r2_3
    rename v398 beliefs_alt1_r2_1_1
    rename v399 beliefs_alt1_r2_2_1
    rename v400 beliefs_alt1_r2_3_1
    rename v359 r2beliefs_alt1_1
    rename v360 r2beliefs_alt1_2
    rename v361 r2beliefs_alt1_3
    rename v385 beliefs_alt2_r2_1
    rename v386 beliefs_alt2_r2_2
    rename v387 beliefs_alt2_r2_3
    rename v401 beliefs_alt2_r2_1_1
    rename v402 beliefs_alt2_r2_2_1
    rename v403 beliefs_alt2_r2_3_1
    rename v362 r2beliefs_alt2_1
    rename v363 r2beliefs_alt2_2
    rename v364 r2beliefs_alt2_3
    rename v417 riskTaking
    rename v418 statKnow
    rename v419 regretExAnte
    rename v420 regretExPost
    rename v438 round1_combined_array
    rename v439 round2_combined_array

    * dedup raw submissions by id, stable (first-in-file-order)
    gen long _orig_order = _n
    sort id _orig_order
    by id: keep if _n == 1
    drop _orig_order

    recast strL id
    keep if regexm(id, "^[0-9a-f]{24}$") & id != "000000000000000000000000"

    * riskTaking/statKnow/regretExAnte/regretExPost are NEVER numeric-cast by R
    * anywhere in clean_prereg(), they stay character strings, so blank ("")
    * values are not R's NA and never trigger na.omit() drops. Destringing them
    * here would incorrectly convert blanks to Stata missing and wrongly drop
    * otherwise-complete rows (see discrepancy_log.md). Leave them as strings.
    destring duration choiceB_r1 choiceB_r2, replace force

    * whichFirst: 3-tier DO priority chain (sampling DO, then description DO x2)
    gen whichFirst_r1 = ""
    replace whichFirst_r1 = "B" if substr(choice_round_1_DO, -1, 1) == "A"
    replace whichFirst_r1 = "A" if whichFirst_r1 == "" & substr(choice_round_1_DO, -1, 1) == "B"
    replace whichFirst_r1 = "B" if whichFirst_r1 == "" & substr(desc_choice_r1_DO, -1, 1) == "A"
    replace whichFirst_r1 = "A" if whichFirst_r1 == "" & substr(desc_choice_r1_DO, -1, 1) == "B"
    replace whichFirst_r1 = "B" if whichFirst_r1 == "" & substr(desc_choice_r1_DO_1, -1, 1) == "A"
    replace whichFirst_r1 = "A" if whichFirst_r1 == "" & substr(desc_choice_r1_DO_1, -1, 1) == "B"

    gen whichFirst_r2 = ""
    replace whichFirst_r2 = "B" if substr(choice_round_2_DO, -1, 1) == "A"
    replace whichFirst_r2 = "A" if whichFirst_r2 == "" & substr(choice_round_2_DO, -1, 1) == "B"
    replace whichFirst_r2 = "B" if whichFirst_r2 == "" & substr(desc_choice_r2_DO, -1, 1) == "A"
    replace whichFirst_r2 = "A" if whichFirst_r2 == "" & substr(desc_choice_r2_DO, -1, 1) == "B"
    replace whichFirst_r2 = "B" if whichFirst_r2 == "" & substr(desc_choice_r2_DO_1, -1, 1) == "A"
    replace whichFirst_r2 = "A" if whichFirst_r2 == "" & substr(desc_choice_r2_DO_1, -1, 1) == "B"

    * beliefA/B: condition-gated (NOT a blind coalesce, mirrors R's case_when exactly)
    gen double r1_beliefA = .
    replace r1_beliefA = real(Q14_1_1) if cond_presentation == "sampling_noiseless"
    replace r1_beliefA = real(beliefs_r1_1_1) if cond_presentation == "description_noiseless" & cond_beliefs_choice_order == "choice_first"
    replace r1_beliefA = real(beliefs_r1_1_1_1) if cond_presentation == "description_noiseless" & cond_beliefs_choice_order == "beliefs_first"

    gen double r1_beliefB = .
    replace r1_beliefB = real(Q14_1_2) if cond_presentation == "sampling_noiseless"
    replace r1_beliefB = real(beliefs_r1_1_2) if cond_presentation == "description_noiseless" & cond_beliefs_choice_order == "choice_first"
    replace r1_beliefB = real(beliefs_r1_1_2_1) if cond_presentation == "description_noiseless" & cond_beliefs_choice_order == "beliefs_first"

    gen double r2_beliefA = .
    replace r2_beliefA = real(Q81_1_1) if cond_presentation == "sampling_noiseless"
    replace r2_beliefA = real(beliefs_r2_1_1) if cond_presentation == "description_noiseless" & cond_beliefs_choice_order == "choice_first"
    replace r2_beliefA = real(beliefs_r2_1_1_1) if cond_presentation == "description_noiseless" & cond_beliefs_choice_order == "beliefs_first"

    gen double r2_beliefB = .
    replace r2_beliefB = real(Q81_1_2) if cond_presentation == "sampling_noiseless"
    replace r2_beliefB = real(beliefs_r2_1_2) if cond_presentation == "description_noiseless" & cond_beliefs_choice_order == "choice_first"
    replace r2_beliefB = real(beliefs_r2_1_2_1) if cond_presentation == "description_noiseless" & cond_beliefs_choice_order == "beliefs_first"

    * alt-belief triples: blind 3-way concat (mirrors R's unite(), no condition gating)
    coalesce_triple r1_beliefA_below beliefs_alt1_r1_1   beliefs_alt1_r1_1_1   r1beliefs_alt1_1
    coalesce_triple r1_beliefA_equal beliefs_alt1_r1_2   beliefs_alt1_r1_2_1   r1beliefs_alt1_2
    coalesce_triple r1_beliefA_above beliefs_alt1_r1_3   beliefs_alt1_r1_3_1   r1beliefs_alt1_3
    coalesce_triple r1_beliefB_below beliefs_alt2_r1_1   beliefs_alt2_r1_1_1   r1beliefs_alt2_1
    coalesce_triple r1_beliefB_equal beliefs_alt2_r1_2   beliefs_alt2_r1_2_1   r1beliefs_alt2_2
    coalesce_triple r1_beliefB_above beliefs_alt2_r1_3   beliefs_alt2_r1_3_1   r1beliefs_alt2_3

    coalesce_triple r2_beliefA_below beliefs_alt1_r2_1   beliefs_alt1_r2_1_1   r2beliefs_alt1_1
    coalesce_triple r2_beliefA_equal beliefs_alt1_r2_2   beliefs_alt1_r2_2_1   r2beliefs_alt1_2
    coalesce_triple r2_beliefA_above beliefs_alt1_r2_3   beliefs_alt1_r2_3_1   r2beliefs_alt1_3
    coalesce_triple r2_beliefB_below beliefs_alt2_r2_1   beliefs_alt2_r2_1_1   r2beliefs_alt2_1
    coalesce_triple r2_beliefB_equal beliefs_alt2_r2_2   beliefs_alt2_r2_2_1   r2beliefs_alt2_2
    coalesce_triple r2_beliefB_above beliefs_alt2_r2_3   beliefs_alt2_r2_3_1   r2beliefs_alt2_3

    * choiceStr: blind 3-way concat (mirrors R's paste0, no condition gating)
    coalesce_triple r1_choice_str choice_strength_r1 desc_choice_str_r1 desc_choice_str_r1_1
    coalesce_triple r2_choice_str choice_strength_r2 desc_choice_str_r2 desc_choice_str_r2_1

    gen choiceB_r1_final = choiceB_r1 - 1
    gen choiceB_r2_final = choiceB_r2 - 1

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
        keep id choiceB cond_presentation cond_beliefs_choice_order riskTaking statKnow regretExAnte regretExPost duration beliefA beliefB beliefA_below beliefA_equal beliefA_above beliefB_below beliefB_equal beliefB_above choiceStr whichFirst short round
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
        keep id choiceB cond_presentation cond_beliefs_choice_order riskTaking statKnow regretExAnte regretExPost duration beliefA beliefB beliefA_below beliefA_equal beliefA_above beliefB_below beliefB_equal beliefB_above choiceStr whichFirst short round
        save `round2'
    restore

    use `round1', clear
    append using `round2'

    * na.omit()-equivalent, riskTaking/statKnow/regretExAnte/regretExPost
    * deliberately excluded (see note above the destring line)
    egen nmiss = rowmiss(choiceB cond_presentation cond_beliefs_choice_order duration beliefA beliefB beliefA_below beliefA_equal beliefA_above beliefB_below beliefB_equal beliefB_above choiceStr whichFirst short round)
    drop if nmiss > 0
    drop nmiss

    recast str24 id
    merge m:1 id using "`prolifictmp'", keep(match) nogenerate

    drop if student == "CONSENT_REVOKED"
    capture drop df
    gen df = "prereg"

    export delimited using "$CLEAN/prereg_stata.csv", replace
    di as result "==== prereg trial-level complete: " _N " rows ===="

    *-----------------------------------------------------------
    * View times + sampling order: built from a FRESH, UNDEDUPED
    * raw import (matches R's read_raw(input) called separately for
    * each of these, no id-regex filter, no dedup, unlike the main
    * trial-level cleaning above).
    *-----------------------------------------------------------
	
	preserve
        import delimited "`rawfile'", clear varnames(nonames) case(preserve) bindquote(strict) stringcols(_all)
        gen long _n_orig = _n
        drop if inlist(_n_orig, 1, 3)
        drop _n_orig
        rename v36 id

        local viewpos 46
        forvalues i = 1/11 {
            rename v`viewpos' view`i'
            local viewpos = `viewpos' + 4
        }
        keep id view1 view2 view3 view4 view5 view6 view7 view8 view9 view10 view11
        keep if view1 != ""
        gen cond_presentation = "sampling_noiseless"
        gen short = 1
        gen df = "prereg"
        export delimited using "$CLEAN/viewTimes/prereg_short_stata.csv", replace
    restore

    preserve
        import delimited "`rawfile'", clear varnames(nonames) case(preserve) bindquote(strict) stringcols(_all)
        gen long _n_orig = _n
        drop if inlist(_n_orig, 1, 3)
        drop _n_orig
        rename v36 id

        local viewpos 90
        local viewlist ""
        forvalues i = 1/51 {
            rename v`viewpos' view`i'
            local viewlist "`viewlist' view`i'"
            local viewpos = `viewpos' + 4
        }
        keep id `viewlist'
        keep if view1 != ""
        gen cond_presentation = "sampling_noiseless"
        gen short = 0
        gen df = "prereg"
        export delimited using "$CLEAN/viewTimes/prereg_long_stata.csv", replace
    restore

    preserve
        import delimited "`rawfile'", clear varnames(nonames) case(preserve) bindquote(strict) stringcols(_all)
        gen long _n_orig = _n
        drop if _n_orig <= 3
        drop _n_orig
        rename v36 id
        rename v438 round1_combined_array
        keep id round1_combined_array
        gen df = "prereg"
        export delimited using "$CLEAN/Sampling Order/prereg_round1_stata.csv", replace
    restore

    preserve
        import delimited "`rawfile'", clear varnames(nonames) case(preserve) bindquote(strict) stringcols(_all)
        gen long _n_orig = _n
        drop if _n_orig <= 3
        drop _n_orig
        rename v36 id
        rename v439 round2_combined_array
        keep id round2_combined_array
        gen df = "prereg"
        export delimited using "$CLEAN/Sampling Order/prereg_round2_stata.csv", replace
    restore

    di as result "==== prereg view-times + sampling-order complete ===="
end

* Prolific + run
*-------------------------------------------------------------
tempfile prolific_prereg
import delimited "$PROLIFIC\prProlific.csv", clear varnames(nonames) case(preserve) bindquote(strict) stringcols(_all)
drop if _n == 1
rename v1 id
rename v2 age
rename v3 sex
rename v4 student
recast str24 id
save `prolific_prereg'

local pregfile "$RAW\Alex Imas - Michael Ungeheuer - Description Experience Prereg_December 20, 2023_10.59.csv"
clean_prereg "`pregfile'" "`prolific_prereg'"


