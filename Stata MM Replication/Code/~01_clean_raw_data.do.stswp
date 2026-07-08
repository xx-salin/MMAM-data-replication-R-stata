

*=============================================================
* 01_clean_raw_data.do 
* Run after 00_setup.do has set $ROOT $RAW $PROLIFIC $CLEAN
*=============================================================


do "C:\Users\salins4\OneDrive - Aalto University\Desktop\MMAM\Stata MM Replication\Code\00_setup.do"

local v5file "$RAW\Alex Imas - Michael Ungeheuer - Description Experience v5_December 20, 2023_09.23.csv"
display "`v5file'"
import delimited "`v5file'", clear varnames(nonames) case(preserve) bindquote(strict) stringcols(_all)



*=============================================================
*        Family 1: paste-pair beliefs (v5, v13, v11)
*=============================================================


* Helper: coalesce a pasted pair of columns into one, flagging
* any true collisions (both non-missing — R would set these NA)
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

* Main Family 1 cleaner (mirrors R's clean_two_round_paste())
*   args: rawfile output pos1(choiceB_r1) pos2(choiceB_r2) oddpos("" if none) prolifictmp
*-------------------------------------------------------------
capture program drop clean_family1
program define clean_family1
    args rawfile output pos1 pos2 oddpos prolifictmp

    import delimited "`rawfile'", clear varnames(nonames) case(preserve) bindquote(strict) stringcols(_all)
	
	* Dedup raw submissions by prolific_id (R's clean_two_round_paste omits
    * this dedup, unlike clean_interference — see discrepancy_log.md)
    sort v35
    by v35: keep if _n == 1

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

    destring riskTaking statKnow regretExAnte regretExPost duration ///
        beliefs_r1_1_1 beliefs_r1_1_1_1 beliefs_r1_1_2 beliefs_r1_1_2_1 ///
        beliefs_alt1_r1_1 beliefs_alt1_r1_1_1 beliefs_alt1_r1_2 beliefs_alt1_r1_2_1 ///
        beliefs_alt1_r1_3 beliefs_alt1_r1_3_1 beliefs_alt2_r1_1 beliefs_alt2_r1_1_1 ///
        beliefs_alt2_r1_2 beliefs_alt2_r1_2_1 beliefs_alt2_r1_3 beliefs_alt2_r1_3_1 ///
        beliefs_r2_1_1 beliefs_r2_1_1_1 beliefs_r2_1_2 beliefs_r2_1_2_1 ///
        beliefs_alt1_r2_1 beliefs_alt1_r2_1_1 beliefs_alt1_r2_2 beliefs_alt1_r2_2_1 ///
        beliefs_alt1_r2_3 beliefs_alt1_r2_3_1 beliefs_alt2_r2_1 beliefs_alt2_r2_1_1 ///
        beliefs_alt2_r2_2 beliefs_alt2_r2_2_1 beliefs_alt2_r2_3 beliefs_alt2_r2_3_1 ///
        desc_choice_str_r1 desc_choice_str_r1_1 desc_choice_str_r2 desc_choice_str_r2_1, replace force

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

    local misscols "bonus_payment choiceB cond_beliefs_choice_order riskTaking statKnow regretExAnte regretExPost duration beliefA beliefB beliefA_below beliefA_equal beliefA_above beliefB_below beliefB_equal beliefB_above choiceStr whichFirst short round"
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

* Build Prolific demographic files (per experiment)
*---------------------------------------------------------------
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


* Run Family 1
*---------------------------------------------------------------
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

    * dedup raw submissions by id (see discrepancy_log.md)
    sort id
    by id: keep if _n == 1

    recast strL id

    keep StartDate duration id bonus_payment choice_round_1_DO choiceB_r1 choice_strength_r1 rand_long_short_order cond_beliefs_choice_order Q14_1_1 Q14_1_2 r1beliefs_alt1_1 r1beliefs_alt1_2 r1beliefs_alt1_3 r1beliefs_alt2_1 r1beliefs_alt2_2 r1beliefs_alt2_3 riskTaking statKnow regretExAnte regretExPost round1_combined_array `viewlist'

    keep if regexm(id, "^[0-9a-f]{24}$") & id != "000000000000000000000000"

    destring duration riskTaking statKnow regretExAnte regretExPost Q14_1_1 Q14_1_2 r1beliefs_alt1_1 r1beliefs_alt1_2 r1beliefs_alt1_3 r1beliefs_alt2_1 r1beliefs_alt2_2 r1beliefs_alt2_3 choice_strength_r1 choiceB_r1, replace force

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

    egen nmiss = rowmiss(bonus_payment choiceB cond_beliefs_choice_order riskTaking statKnow regretExAnte regretExPost duration beliefA beliefB beliefA_below beliefA_equal beliefA_above beliefB_below beliefB_equal beliefB_above choiceStr whichFirst short round)
    drop if nmiss > 0
    drop nmiss

    recast str24 id
    merge m:1 id using "`prolifictmp'", keep(match) nogenerate

    drop if student == "CONSENT_REVOKED"
    capture drop df
    gen df = "`output'"

    keep id bonus_payment choiceB cond_beliefs_choice_order riskTaking statKnow regretExAnte regretExPost duration beliefA beliefB beliefA_below beliefA_equal beliefA_above beliefB_below beliefB_equal beliefB_above choiceStr whichFirst short round `viewlist' rand_long_short_order age sex student df

    export delimited using "$CLEAN/`output'_stata.csv", replace
    di as result "==== `output' complete: " _N " rows ===="
end

* Build Prolific files + run Family 2
*=------------------------------------------------------------
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
* Family 3:     interference experiments (v21, v27)
*=============================================================









