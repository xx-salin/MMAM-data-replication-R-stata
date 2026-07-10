
*=============================================================
* 02_combine_data.do
* Run after 00_setup.do has set $ROOT $RAW $PROLIFIC $CLEAN

* INPUT: Clean per-experiment data (Data/Clean Data/), produced by 01_clean_raw_data.do
* Output: `combinedDF', the trial-level data set, in memory, that pools the experiments used in the paper's main choice/belief figures.
*=============================================================


do "00_setup.do"

* Belief columns must be forced to double on import, import delimited
* defaults decimal columns to float, which silently reintroduces float32
* rounding noise (e.g. "33.4" -> 33.400002) even when the source CSV was
* exported with full double precision. See discrepancy_log.md.
* NOTE: doublelist() is not a valid import delimited option — asdouble
* forces ALL numeric variables to double storage instead (harmless here).

tempfile tNoBox tRandom tRecord tInter tInterOrange tPreRegSamp t11_2 tPreRegDesc tBoxRight

*-----------------------------------------------------------
* vNoBox: v5, Description, drop bonus_payment
*-----------------------------------------------------------
import delimited "$CLEAN/v5_stata.csv", clear varnames(1) case(preserve) asdouble
capture tostring age, replace force
drop bonus_payment
gen cond = "Description"
replace df = "NoBox"
save `tNoBox'

*-----------------------------------------------------------
* vRandom: v13, Description, drop bonus_payment
*-----------------------------------------------------------
import delimited "$CLEAN/v13_stata.csv", clear varnames(1) case(preserve) asdouble
capture tostring age, replace force
drop bonus_payment
gen cond = "Description"
replace df = "Random"
save `tRandom'

*-----------------------------------------------------------
* vRecord: v17, Sampling, drop bonus_payment rand_long_short_order view*
*-----------------------------------------------------------
import delimited "$CLEAN/v17_stata.csv", clear varnames(1) case(preserve) asdouble
capture tostring age, replace force
drop bonus_payment rand_long_short_order view1-view11
gen cond = "Sampling"
replace df = "Record"
save `tRecord'

*-----------------------------------------------------------
* vInter: v27_trials, filter a3Col==Blue, drop a3Col bonus_payment
* rand_long_short_order view* -> df="Interference_A"
*-----------------------------------------------------------
import delimited "$CLEAN/v27_trials_stata.csv", clear varnames(1) case(preserve) asdouble
capture tostring age, replace force
keep if a3Col == "Blue"
drop a3Col bonus_payment rand_long_short_order view1-view11
gen cond = "Sampling"
replace df = "Interference_A"
save `tInter'

*-----------------------------------------------------------
* vInterOrange: v21, filter a3Col==Orange, same drops
* -> df="Interference_B"
*-----------------------------------------------------------
import delimited "$CLEAN/v21_stata.csv", clear varnames(1) case(preserve) asdouble
capture tostring age, replace force
keep if a3Col == "Orange"
drop a3Col bonus_payment rand_long_short_order view1-view11
gen cond = "Sampling"
replace df = "Interference_B"
save `tInterOrange'

*-----------------------------------------------------------
* vPreRegSamp: prereg, filter sampling_noiseless, drop cond_presentation
*-----------------------------------------------------------
import delimited "$CLEAN/prereg_stata.csv", clear varnames(1) case(preserve) asdouble
capture tostring age, replace force
keep if cond_presentation == "sampling_noiseless"
drop cond_presentation
gen cond = "Sampling"
replace df = "PR Sampling"
save `tPreRegSamp'

*-----------------------------------------------------------
* v11_2: v11, filter oddState==right, drop oddState bonus_payment
* (no df/cond assigned yet, inherited from vBoxRight below)
*-----------------------------------------------------------
import delimited "$CLEAN/v11_stata.csv", clear varnames(1) case(preserve) asdouble
capture tostring age, replace force
keep if oddState == "right"
drop oddState bonus_payment
save `t11_2'

*-----------------------------------------------------------
* vPreRegDesc: prereg, filter description_noiseless, drop cond_presentation
* (no bonus_payment column in prereg, nothing to drop here)
*-----------------------------------------------------------
import delimited "$CLEAN/prereg_stata.csv", clear varnames(1) case(preserve) asdouble
capture tostring age, replace force
keep if cond_presentation == "description_noiseless"
drop cond_presentation
save `tPreRegDesc'

*-----------------------------------------------------------
* vBoxRight = rbind(vPreRegDesc, v11_2), df="BoxRight", cond="Description"
*-----------------------------------------------------------
use `tPreRegDesc', clear
append using `t11_2'
gen cond = "Description"
replace df = "BoxRight"
save `tBoxRight'

*-----------------------------------------------------------
* combinedDF = rbind(vNoBox, vRandom, vBoxRight, vPreRegSamp,
*                     vRecord, vInter, vInterOrange)
*-----------------------------------------------------------
use `tNoBox', clear
append using `tRandom'
append using `tBoxRight'
append using `tPreRegSamp'
append using `tRecord'
append using `tInter'
append using `tInterOrange'

di as result "==== combinedDF assembled: " _N " rows, df values: ===="
tab df

capture erase "$CLEAN/dataForMichael_stata.csv"
export delimited using "$CLEAN/dataForMichael_stata.csv", replace