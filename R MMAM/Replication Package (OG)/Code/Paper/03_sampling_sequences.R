## ---------------------------
##
## 03_sampling_sequences.R
##
## Input:  Clean data (Data/Clean Data/) produced by 01_clean_raw_data.R:
##           - Sampling Order/ : the per-participant display order of the
##             outcome pairs in the sequential (sampling) treatment
##           - viewTimes/      : seconds spent on each pair's page
##           - the trial-level files (for the participant's choice)
##
## Output: Data/Clean Data/samplingSequences_long.csv
##         One row per participant x round x position (the k-th pair shown),
##         with the pair's outcomes, the time spent viewing it, and the
##         participant's choice. Built for the sequential treatment only.
##
## Author: Josh Hascher
##
## ---------------------------
##
## Notes:
##   Purpose: enable (a) the recency-bias robustness check (does the choice
##   for the frequently-better asset survive even when the extreme outcome
##   pair happens to be shown last?) and (b) attention analyses on viewing
##   times in the sequential format.
##
##   Alignment: page k displays combined_array[k] and view_k is the time on
##   that page (verified from the Qualtrics randomisation script: the order is
##   shuffled once and both the display fields and combined_array are written
##   from the same shuffled array at the same index). So position k joins the
##   k-th pair in the sequence to view_k.
## ---------------------------

# Clear the workspace
rm(list = ls())

library(tidyverse)

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

find_repo_root <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- sub("^--file=", "", args[grepl("^--file=", args)])
  # Rscript encodes spaces in the path as "~+~"; decode them.
  file_arg <- gsub("~+~", " ", file_arg, fixed = TRUE)
  if (length(file_arg) == 1 && nzchar(file_arg)) {
    return(normalizePath(file.path(dirname(file_arg), "..", "..")))
  }
  rprojroot::find_root(rprojroot::has_dir("Data"))
}

root      <- find_repo_root()
clean_dir <- Sys.getenv("CLEAN_OUT_DIR",
                        unset = file.path(root, "Data", "Clean Data"))

read_clean <- function(...) read.csv(file.path(clean_dir, ...))

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Parse a "[a,b];[c,d];..." combined-array string column into a long tibble
# with one row per display position.
parse_sequence <- function(d, arr_col) {
  d %>%
    transmute(id, arr = .data[[arr_col]]) %>%
    filter(str_detect(arr, "\\[")) %>%                 # drop blank / non-sampling rows
    separate_rows(arr, sep = ";") %>%
    group_by(id) %>%
    mutate(position = row_number()) %>%
    ungroup() %>%
    mutate(arr = str_remove_all(arr, "\\[|\\]")) %>%
    separate(arr, into = c("outcomeA", "outcomeB"), sep = ",", convert = TRUE)
}

# Pivot a viewTimes frame (view1..viewN) into long form (position, viewTime).
views_long <- function(d) {
  d %>%
    select(id, matches("^view[0-9]+$")) %>%
    pivot_longer(matches("^view[0-9]+$"),
                 names_to = "position", values_to = "viewTime",
                 names_transform = list(position = ~ as.integer(str_remove(.x, "view")))) %>%
    mutate(viewTime = suppressWarnings(as.numeric(viewTime))) %>%  # some files store "" -> NA
    filter(!is.na(viewTime))
}

# Keep one sequence per real participant id (drop the Qualtrics dummy id and
# any duplicate attempts).
clean_seq_ids <- function(d) {
  d %>%
    filter(str_length(id) == 24, id != strrep("0", 24)) %>%
    distinct(id, .keep_all = TRUE)
}

# ---------------------------------------------------------------------------
# Single-round sampling experiments (v17, v21, v27): one 11-pair sequence each
# ---------------------------------------------------------------------------

build_single_round <- function(label, trials_file, seq_file, view_file) {
  seq <- read_clean("Sampling Order", paste0(seq_file, ".csv")) %>%
    clean_seq_ids() %>%
    parse_sequence("round1_combined_array")

  vws <- read_clean("viewTimes", paste0(view_file, ".csv")) %>%
    views_long()

  choice <- read_clean(paste0(trials_file, ".csv")) %>%
    distinct(id, .keep_all = TRUE) %>%
    select(id, choiceB, any_of(c("whichFirst", "a3Col")))

  seq %>%
    inner_join(choice, by = "id") %>%          # restrict to the analysis sample + attach choice
    left_join(vws, by = c("id", "position")) %>%
    mutate(experiment = label, round = 1L, block = "single")
}

# ---------------------------------------------------------------------------
# Pre-registered experiment: two rounds, each either a short (11) or long (51)
# sampling block per participant.
# ---------------------------------------------------------------------------

build_prereg <- function() {
  seq1 <- read_clean("Sampling Order", "prereg_round1.csv") %>%
    clean_seq_ids() %>% parse_sequence("round1_combined_array") %>% mutate(round = 1L)
  seq2 <- read_clean("Sampling Order", "prereg_round2.csv") %>%
    clean_seq_ids() %>% parse_sequence("round2_combined_array") %>% mutate(round = 2L)
  seq <- bind_rows(seq1, seq2)

  # View times are stored per block (short = Q57/11 pages, long = Q60/51 pages),
  # each tagged with the block's `short` indicator.
  vws <- bind_rows(
    read_clean("viewTimes", "prereg_short.csv") %>% views_long() %>% mutate(short = 1L),
    read_clean("viewTimes", "prereg_long.csv")  %>% views_long() %>% mutate(short = 0L)
  )

  # Trial data carries, per (id, round): the choice, the block (short), and the
  # condition. Sequence/attention apply to the sampling condition only.
  trials <- read_clean("prereg.csv") %>%
    filter(cond_presentation == "sampling_noiseless") %>%
    select(id, round, short, choiceB)

  seq %>%
    inner_join(trials, by = c("id", "round")) %>%            # sampling sample + choice + block
    left_join(vws, by = c("id", "short", "position")) %>%
    mutate(experiment = "prereg",
           block = if_else(short == 1L, "short", "long")) %>%
    select(-short)
}

# ---------------------------------------------------------------------------
# Assemble
# ---------------------------------------------------------------------------

long <- bind_rows(
  build_single_round("v17 (Record)",          "v17",        "v17",          "v17"),
  build_single_round("v21 (Interference B)",   "v21",        "v21",          "v21"),
  build_single_round("v27 (Interference A)",   "v27_trials", "v27_sampling", "v27_views"),
  build_prereg()
) %>%
  group_by(experiment, id, round) %>%
  mutate(nPairs     = n(),
         isLastPair = as.integer(position == max(position)),
         spread     = abs(outcomeA - outcomeB)) %>%
  ungroup() %>%
  select(experiment, id, round, block, position, nPairs, isLastPair,
         outcomeA, outcomeB, spread, viewTime, choiceB,
         any_of(c("whichFirst", "a3Col")))

write.csv(long, file.path(clean_dir, "samplingSequences_long.csv"),
          row.names = FALSE, quote = FALSE)

message("Wrote ", file.path(clean_dir, "samplingSequences_long.csv"),
        " (", nrow(long), " rows, ",
        dplyr::n_distinct(paste(long$experiment, long$id, long$round)),
        " participant-rounds)")
