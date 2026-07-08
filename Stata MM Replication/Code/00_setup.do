*-----------------------------------------------------------
* 00_setup.do
* Simplest version: hardcode the repo root, set paths from it.
*-----------------------------------------------------------

global ROOT "C:\Users\salins4\OneDrive - Aalto University\Desktop\MMAM\Stata MM Replication"

global RAW      "$ROOT\Data\Raw Data"
global PROLIFIC "$ROOT\Data\Prolific Data"
global CLEAN    "$ROOT\Data\Clean Data"

cap mkdir "$CLEAN"
cap mkdir "$CLEAN\viewTimes"
cap mkdir "$CLEAN\Sampling Order"

display as text "ROOT:      $ROOT"
display as text "RAW:       $RAW"
display as text "PROLIFIC:  $PROLIFIC"
display as text "CLEAN:     $CLEAN"

