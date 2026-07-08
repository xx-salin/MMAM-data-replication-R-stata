## ---------------------------
##
## 02_combine_data.R
##
## Input:  Clean per-experiment data (Data/Clean Data/), produced by
##         01_clean_raw_data.R
##
## Output: `combinedDF` — the trial-level data set, in memory, that pools the
##         experiments used in the paper's main choice/belief figures.
##
## Author: Josh Hascher
##
## ---------------------------
##
## Notes:
##   This script holds the data-assembly step that was previously duplicated at
##   the top of every figure script. The figure scripts now `source()` this
##   file and then draw their plots, so the pooling logic lives in one place.
##
##   It can also be run on its own to inspect / export `combinedDF`.
## ---------------------------

library(tidyverse)

# ---------------------------------------------------------------------------
# Paths (resolved relative to the repository root, so the package is portable)
# ---------------------------------------------------------------------------

if (!exists("find_repo_root")) {
  find_repo_root <- function() {
    # When run with `Rscript path/to/02_combine_data.R`
    args <- commandArgs(trailingOnly = FALSE)
    file_arg <- sub("^--file=", "", args[grepl("^--file=", args)])
    # Rscript encodes spaces in the path as "~+~"; decode them.
    file_arg <- gsub("~+~", " ", file_arg, fixed = TRUE)
    if (length(file_arg) == 1 && nzchar(file_arg)) {
      return(normalizePath(file.path(dirname(file_arg), "..", "..")))
    }
    # When source()'d interactively: walk up from the working dir to the folder
    # that contains the Data directory.
    rprojroot::find_root(rprojroot::has_dir("Data"))
  }
}

if (!exists("root")) root <- find_repo_root()
clean_dir <- Sys.getenv("CLEAN_OUT_DIR",
                        unset = file.path(root, "Data", "Clean Data"))

read_clean <- function(file) read.csv(file.path(clean_dir, file))

# ---------------------------------------------------------------------------
# Assemble the pooled, trial-level data set
#
# Each experiment is relabelled into the condition names used in the figures.
# The two interference cells are kept separate (Interference_A = v27 / Blue,
# Interference_B = v21 / Orange).
# ---------------------------------------------------------------------------

vNoBox <- read_clean("v5.csv") %>%
  mutate(df = "NoBox", cond = "Description") %>%
  select(!bonus_payment)

vRandom <- read_clean("v13.csv") %>%
  mutate(df = "Random", cond = "Description") %>%
  select(!bonus_payment)

vRecord <- read_clean("v17.csv") %>%
  mutate(df = "Record", cond = "Sampling") %>%
  select(!c(bonus_payment, rand_long_short_order, starts_with("view")))

vInter <- read_clean("v27_trials.csv") %>%
  filter(a3Col == "Blue") %>%
  select(!c(a3Col, bonus_payment, rand_long_short_order, starts_with("view"))) %>%
  mutate(df = "Interference_A", cond = "Sampling")

vInterOrange <- read_clean("v21.csv") %>%
  filter(a3Col == "Orange") %>%
  select(!c(a3Col, bonus_payment, rand_long_short_order, starts_with("view"))) %>%
  mutate(df = "Interference_B", cond = "Sampling")

vPreRegSamp <- read_clean("prereg.csv") %>%
  filter(cond_presentation == "sampling_noiseless") %>%
  mutate(df = "PR Sampling", cond = "Sampling") %>%
  select(!c(cond_presentation))

v11_2 <- read_clean("v11.csv") %>%
  filter(oddState == "right") %>%
  select(!c(oddState, bonus_payment))

vPreRegDesc <- read_clean("prereg.csv") %>%
  filter(cond_presentation == "description_noiseless") %>%
  select(!cond_presentation)

vBoxRight <- rbind(vPreRegDesc, v11_2) %>%
  mutate(df = "BoxRight", cond = "Description")

combinedDF <- rbind(vNoBox, vRandom, vBoxRight, vPreRegSamp, vRecord, vInter, vInterOrange)

# To export the pooled data set, uncomment:
# write.csv(combinedDF, file.path(clean_dir, "dataForMichael.csv"),
#           row.names = FALSE, quote = FALSE)
