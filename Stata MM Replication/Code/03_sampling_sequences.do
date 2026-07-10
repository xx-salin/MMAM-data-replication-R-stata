

*=============================================================
* 03_combine_data.do
* Run after 00_setup.do has set $ROOT $RAW $PROLIFIC $CLEAN

* INPUT: Clean per-experiment data (Data/Clean Data/), produced by 01_clean_raw_data.do
* Output: `combinedDF', the trial-level data set, in memory, that pools the experiments used in the paper's main choice/belief figures.
*=============================================================

do "00_setup.do"

*-------------------------------------------------------------
* Helper: parse "[a,b];[c,d];..." in `arrvar' into long format
* (id, position, outcomeA, outcomeB). Mirrors R's parse_sequence().
* Expects current dataset to contain id + `arrvar'.
*-------------------------------------------------------------
capture program drop parse_sequence
program define parse_sequence
    args arrvar

    keep id `arrvar'
    rename `arrvar' arr

    * drop blank / non-sampling rows (description condition, etc.)
    keep if strpos(arr, "[") > 0

    * split on ";" auto-sizes to the widest row (11 or 51 pairs);
    * shorter rows get blank trailing segments, never gaps
    split arr, parse(";") gen(seg)
    drop arr

    gen long _id_n = _n
    quietly reshape long seg, i(_id_n) j(position)
    drop _id_n

    drop if missing(seg) | seg == ""

    replace seg = subinstr(seg, "[", "", .)
    replace seg = subinstr(seg, "]", "", .)
    split seg, parse(",") gen(outcome)
    rename outcome1 outcomeA
    rename outcome2 outcomeB
    destring outcomeA outcomeB, replace force
    drop seg
end

*-------------------------------------------------------------
* Helper: pivot view1..viewN into long format (position, viewTime).
* Mirrors R's views_long(). Expects current dataset to contain
* id + view* columns (already numeric).
*-------------------------------------------------------------
capture program drop views_long
program define views_long
    quietly ds view*
    local viewvars "`r(varlist)'"
    keep id `viewvars'

    gen long _id_n = _n
    quietly reshape long view, i(_id_n) j(position)
    drop _id_n

    drop if missing(view)
    rename view viewTime
end

*-------------------------------------------------------------
* Single-round sampling experiments (v17, v21, v27): one 11-pair
* sequence each. Leaves the final merged dataset in memory.
*-------------------------------------------------------------
capture program drop build_single_round
program define build_single_round
    args label trials_file seq_file view_file

    * --- sequence ---
    import delimited "$CLEAN/Sampling Order/`seq_file'_stata.csv", clear varnames(1) case(preserve)
    keep if strlen(id) == 24 & id != "000000000000000000000000"
    duplicates drop id, force
    parse_sequence round1_combined_array
    tempfile seqdata
    save `seqdata'

    * --- view times ---
    * These exports come from already-cleaned trial-level data (id-filtered,
    * NA-dropped, Prolific-merged), so there's no stray Qualtrics text row
    * to worry about here, asdouble is enough.
    import delimited "$CLEAN/viewTimes/`view_file'_stata.csv", clear varnames(1) case(preserve) asdouble
    views_long
    tempfile vwsdata
    save `vwsdata'

    * --- choice (+ whichFirst / a3Col if present) ---
    import delimited "$CLEAN/`trials_file'_stata.csv", clear varnames(1) case(preserve)
    duplicates drop id, force
    local keepvars "id choiceB"
    capture confirm variable whichFirst
    if _rc == 0 local keepvars "`keepvars' whichFirst"
    capture confirm variable a3Col
    if _rc == 0 local keepvars "`keepvars' a3Col"
    keep `keepvars'
    tempfile choicedata
    save `choicedata'

    * --- combine: inner_join(choice) then left_join(views) ---
    use `seqdata', clear
    merge m:1 id using `choicedata', keep(match) nogenerate
    merge 1:1 id position using `vwsdata', keep(master match) nogenerate

    gen experiment = "`label'"
    gen round = 1
    gen block = "single"
end

*-------------------------------------------------------------
* Pre-registered experiment: two rounds, each either a short (11)
* or long (51) sampling block per participant.
*-------------------------------------------------------------
capture program drop build_prereg
program define build_prereg

    * --- sequences: round 1 + round 2 ---
    import delimited "$CLEAN/Sampling Order/prereg_round1_stata.csv", clear varnames(1) case(preserve)
    keep if strlen(id) == 24 & id != "000000000000000000000000"
    duplicates drop id, force
    parse_sequence round1_combined_array
    gen round = 1
    tempfile seq1
    save `seq1'

    import delimited "$CLEAN/Sampling Order/prereg_round2_stata.csv", clear varnames(1) case(preserve)
    keep if strlen(id) == 24 & id != "000000000000000000000000"
    duplicates drop id, force
    parse_sequence round2_combined_array
    gen round = 2
    tempfile seq2
    save `seq2'

    use `seq1', clear
    append using `seq2'
    tempfile seqdata
    save `seqdata'

    * --- view times: short + long blocks, tagged ---
    * A leftover Qualtrics question-text row survives clean_prereg's raw
    * viewTimes export (its view1 is not blank, so the "keep if view1 != """
    * filter there doesn't catch it, see discrepancy_log.md). Import as
    * string, then convert view* via real()+double: this forces the bogus
    * text row to missing (matching R's as.numeric()-then-filter(!is.na())
    * defensive handling) while preserving double precision for real values.
    import delimited "$CLEAN/viewTimes/prereg_short_stata.csv", clear varnames(1) case(preserve) stringcols(_all)
    quietly ds view*
    foreach v of varlist `r(varlist)' {
        gen double _tmp_`v' = real(`v')
        drop `v'
        rename _tmp_`v' `v'
    }
    views_long
    gen short = 1
    tempfile vws_short
    save `vws_short'

    import delimited "$CLEAN/viewTimes/prereg_long_stata.csv", clear varnames(1) case(preserve) stringcols(_all)
    quietly ds view*
    foreach v of varlist `r(varlist)' {
        gen double _tmp_`v' = real(`v')
        drop `v'
        rename _tmp_`v' `v'
    }
    views_long
    gen short = 0
    tempfile vws_long
    save `vws_long'

    use `vws_short', clear
    append using `vws_long'
    tempfile vwsdata
    save `vwsdata'

    * --- trials: sampling condition only, per (id, round) ---
    import delimited "$CLEAN/prereg_stata.csv", clear varnames(1) case(preserve)
    keep if cond_presentation == "sampling_noiseless"
    keep id round short choiceB
    tempfile trialsdata
    save `trialsdata'

    * --- combine: inner_join(trials) then left_join(views) ---
    use `seqdata', clear
    merge m:1 id round using `trialsdata', keep(match) nogenerate
    merge 1:1 id short position using `vwsdata', keep(master match) nogenerate

    gen experiment = "prereg"
    gen block = cond(short == 1, "short", "long")
    drop short
end

*-------------------------------------------------------------
* Assemble
*-------------------------------------------------------------
tempfile long_v17 long_v21 long_v27 long_prereg

build_single_round "v17 (Record)"        "v17"        "v17"          "v17"
save `long_v17'

build_single_round "v21 (Interference B)" "v21"        "v21"          "v21"
save `long_v21'

build_single_round "v27 (Interference A)" "v27_trials" "v27_sampling" "v27_views"
save `long_v27'

build_prereg
save `long_prereg'

use `long_v17', clear
append using `long_v21'
append using `long_v27'
append using `long_prereg'

bysort experiment id round: gen nPairs = _N
bysort experiment id round (position): gen isLastPair = (position == position[_N])
gen spread = abs(outcomeA - outcomeB)

order experiment id round block position nPairs isLastPair outcomeA outcomeB spread viewTime choiceB
capture order whichFirst, after(choiceB)
capture order a3Col, after(whichFirst)

capture erase "$CLEAN/samplingSequences_long_stata.csv"
export delimited using "$CLEAN/samplingSequences_long_stata.csv", replace

egen _pr_tag = tag(experiment id round)
di as result "==== samplingSequences_long complete: " _N " rows, " sum(_pr_tag) " participant-rounds ===="
drop _pr_tag