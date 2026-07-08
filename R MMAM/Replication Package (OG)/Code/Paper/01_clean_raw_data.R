## ---------------------------
##
## 01_clean_raw_data.R
##
## Input:  Raw Qualtrics exports  (Data/Raw Data/)
##         Prolific demographics  (Data/Prolific Data/)
##
## Output: Cleaned, trial-level data per experiment (Data/Clean Data/)
##         plus auxiliary view-time and sampling-order files where available.
##
## Author: Josh Hascher
##
## ---------------------------
##
## Notes:
##
##   To reproduce: set the working directory to anywhere inside the repo (or
##   run via `Rscript Code/Paper/01_clean_raw_data.R`) and source the file.
## ---------------------------

# Clear the workspace
rm(list = ls())

# Cleaning only needs data-wrangling + date parsing.
library(tidyverse)
library(lubridate)

# ---------------------------------------------------------------------------
# Paths (resolved relative to the repository root, so the package is portable)
# ---------------------------------------------------------------------------

find_repo_root <- function() {
  # When run with `Rscript path/to/01_clean_raw_data.R`
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

root         <- find_repo_root()
raw_dir      <- file.path(root, "Data", "Raw Data")
prolific_dir <- file.path(root, "Data", "Prolific Data")

# Output directory. Override (e.g. for validation) by setting CLEAN_OUT_DIR.
clean_dir <- Sys.getenv("CLEAN_OUT_DIR",
                        unset = file.path(root, "Data", "Clean Data"))

dir.create(file.path(clean_dir, "viewTimes"),      showWarnings = FALSE, recursive = TRUE)
dir.create(file.path(clean_dir, "Sampling Order"), showWarnings = FALSE, recursive = TRUE)

# ---------------------------------------------------------------------------
# Shared helpers
# ---------------------------------------------------------------------------

# Read a raw Qualtrics export and drop the second header row Qualtrics adds.
read_raw <- function(input) {
  read.csv(file.path(raw_dir, input))[-2, ]
}

# Load + standardise the Prolific demographics for an experiment.
load_prolific <- function(output) {
  files <- switch(output,
    v5     = c("v5Prolific_1.csv", "v5Prolific_2.csv"),
    prereg = "prProlific.csv",
    paste0(output, "Prolific.csv")
  )
  files %>%
    map(~ read.csv(file.path(prolific_dir, .x))) %>%
    bind_rows() %>%
    select(Participant.id, Age, Sex, Student.status) %>%
    rename(id = Participant.id, student = Student.status, age = Age, sex = Sex)
}

# Standard rename applied to the start of every raw frame.
rename_common <- function(d) {
  d %>%
    rename(id = prolific_id,
           riskTaking   = Q22,
           statKnow     = Q25,
           regretExAnte = Q24,
           regretExPost = Q23,
           duration     = Duration..in.seconds.) %>%
    filter(str_length(id) == 24,
           id != "000000000000000000000000") %>%
    mutate(df = 1, date = ymd_hms(StartDate, tz = "US/Central"))
}

# Write a clean trial-level frame, dropping consent-revoked rows and stamping
# the experiment label.
write_clean <- function(d, name) {
  d %>%
    filter(student != "CONSENT_REVOKED") %>%
    mutate(df = name) %>%
    write.csv(file.path(clean_dir, paste0(name, ".csv")),
              row.names = FALSE, quote = FALSE)
}

# ---------------------------------------------------------------------------
# Family 1: two-round, "paste-pair" belief format  (v5, v13, v11)
#
# These early experiments stored each belief/choice-strength entry as a pair
# of adjacent columns (e.g. beliefs_r1_1_1 + beliefs_r1_1_1.1) that must be
# pasted back together. They have two rounds (short / long) and no view times.
# `extra_keep` carries through experiment-specific columns (v11 keeps oddState).
# ---------------------------------------------------------------------------

clean_two_round_paste <- function(input, output, extra_keep = character(0)) {
  prolific <- load_prolific(output)

  orders <- read_raw(input) %>%
    rename(id = prolific_id) %>%
    select(id, contains("DO")) %>%
    mutate(
      r1_whichFirst = case_when(
        str_ends(desc_choice_r1_DO.1, "A") ~ "B",
        str_ends(desc_choice_r1_DO.1, "B") ~ "A",
        str_ends(desc_choice_r1_DO, "A")   ~ "B",
        str_ends(desc_choice_r1_DO, "B")   ~ "A",
        TRUE ~ ""),
      r2_whichFirst = case_when(
        str_ends(desc_choice_r2_DO.1, "A") ~ "B",
        str_ends(desc_choice_r2_DO.1, "B") ~ "A",
        str_ends(desc_choice_r2_DO, "A")   ~ "B",
        str_ends(desc_choice_r2_DO, "B")   ~ "A",
        TRUE ~ "")) %>%
    select(id, r1_whichFirst, r2_whichFirst)

  df <- read_raw(input) %>%
    rename_common() %>%
    select(
      id, bonus_payment,
      choice_round_1.1, choice_round_2.1,
      starts_with("desc_choice_str"),
      rand_long_short_order, cond_beliefs_choice_order,
      starts_with("beliefs_"),
      riskTaking, statKnow, regretExAnte, regretExPost, duration,
      all_of(extra_keep)
    ) %>%
    mutate(
      r1_beliefA = as.numeric(paste(beliefs_r1_1_1, beliefs_r1_1_1.1)),
      r1_beliefB = as.numeric(paste(beliefs_r1_1_2, beliefs_r1_1_2.1)),
      r2_beliefA = as.numeric(paste(beliefs_r2_1_1, beliefs_r2_1_1.1)),
      r2_beliefB = as.numeric(paste(beliefs_r2_1_2, beliefs_r2_1_2.1))
    ) %>%
    mutate(
      r1_beliefA_below = as.numeric(paste(beliefs_alt1_r1_1, beliefs_alt1_r1_1.1)),
      r1_beliefA_equal = as.numeric(paste(beliefs_alt1_r1_2, beliefs_alt1_r1_2.1)),
      r1_beliefA_above = as.numeric(paste(beliefs_alt1_r1_3, beliefs_alt1_r1_3.1)),
      r1_beliefB_below = as.numeric(paste(beliefs_alt2_r1_1, beliefs_alt2_r1_1.1)),
      r1_beliefB_equal = as.numeric(paste(beliefs_alt2_r1_2, beliefs_alt2_r1_2.1)),
      r1_beliefB_above = as.numeric(paste(beliefs_alt2_r1_3, beliefs_alt2_r1_3.1))
    ) %>%
    mutate(
      r2_beliefA_below = as.numeric(paste(beliefs_alt1_r2_1, beliefs_alt1_r2_1.1)),
      r2_beliefA_equal = as.numeric(paste(beliefs_alt1_r2_2, beliefs_alt1_r2_2.1)),
      r2_beliefA_above = as.numeric(paste(beliefs_alt1_r2_3, beliefs_alt1_r2_3.1)),
      r2_beliefB_below = as.numeric(paste(beliefs_alt2_r2_1, beliefs_alt2_r2_1.1)),
      r2_beliefB_equal = as.numeric(paste(beliefs_alt2_r2_2, beliefs_alt2_r2_2.1)),
      r2_beliefB_above = as.numeric(paste(beliefs_alt2_r2_3, beliefs_alt2_r2_3.1))
    ) %>%
    mutate(
      r1_choice_str = as.numeric(paste(desc_choice_str_r1, desc_choice_str_r1.1)),
      r2_choice_str = as.numeric(paste(desc_choice_str_r2, desc_choice_str_r2.1))
    ) %>%
    select(!c(starts_with("beliefs"),
              desc_choice_str_r1, desc_choice_str_r1.1,
              desc_choice_str_r2, desc_choice_str_r2.1)) %>%
    inner_join(orders, by = "id")

  dfr1 <- df %>%
    mutate(short = ifelse(rand_long_short_order == "short_first", 1, 0),
           round = 1) %>%
    rename(choiceB = choice_round_1.1,
           beliefA = r1_beliefA, beliefB = r1_beliefB,
           beliefA_below = r1_beliefA_below, beliefA_equal = r1_beliefA_equal,
           beliefA_above = r1_beliefA_above, beliefB_below = r1_beliefB_below,
           beliefB_equal = r1_beliefB_equal, beliefB_above = r1_beliefB_above,
           whichFirst = r1_whichFirst, choiceStr = r1_choice_str) %>%
    select(!c(rand_long_short_order, choice_round_2.1,
              r2_beliefA, r2_beliefB,
              r2_beliefA_below, r2_beliefA_equal, r2_beliefA_above,
              r2_beliefB_below, r2_beliefB_equal, r2_beliefB_above,
              r2_whichFirst, r2_choice_str))

  dfr2 <- df %>%
    mutate(short = ifelse(rand_long_short_order == "short_first", 0, 1),
           round = 2) %>%
    rename(choiceB = choice_round_2.1,
           beliefA = r2_beliefA, beliefB = r2_beliefB,
           beliefA_below = r2_beliefA_below, beliefA_equal = r2_beliefA_equal,
           beliefA_above = r2_beliefA_above, beliefB_below = r2_beliefB_below,
           beliefB_equal = r2_beliefB_equal, beliefB_above = r2_beliefB_above,
           whichFirst = r2_whichFirst, choiceStr = r2_choice_str) %>%
    select(!c(rand_long_short_order, choice_round_1.1,
              r1_beliefA, r1_beliefB,
              r1_beliefA_below, r1_beliefA_equal, r1_beliefA_above,
              r1_beliefB_below, r1_beliefB_equal, r1_beliefB_above,
              r1_whichFirst, r1_choice_str))

  rbind(dfr1, dfr2) %>%
    mutate(choiceB = as.numeric(choiceB) - 1) %>%
    na.omit() %>%
    inner_join(prolific, by = "id") %>%
    write_clean(output)
}

# ---------------------------------------------------------------------------
# Family 2: one-round, single-column belief format  (v17, v24)
#
# Later experiments stored beliefs in single columns (Q14_1_1, r1beliefs_*).
# One round only, with page-level view times (Q57) and a sampling-order array.
# `view_n` is the number of view-time pages for the experiment.
# ---------------------------------------------------------------------------

clean_one_round_single <- function(input, output, view_n) {
  prolific <- load_prolific(output)

  orders <- read_raw(input) %>%
    rename(id = prolific_id) %>%
    select(id, contains("DO")) %>%
    mutate(r1_whichFirst = case_when(
      str_ends(choice_round_1_DO, "A") ~ "B",
      str_ends(choice_round_1_DO, "B") ~ "A",
      TRUE ~ "")) %>%
    select(id, r1_whichFirst)

  viewTimes <- read_raw(input) %>%
    rename(id = prolific_id) %>%
    select(id, contains("Q57_Page.Submit")) %>%
    rename_with(~ paste0("view", 1:view_n), .cols = 2:(view_n + 1))

  dfr1 <- read_raw(input) %>%
    rename_common() %>%
    select(
      id, bonus_payment, choice_round_1.1, choice_strength_r1,
      rand_long_short_order, cond_beliefs_choice_order,
      Q14_1_1, Q14_1_2, starts_with("r1beliefs"),
      riskTaking, statKnow, regretExAnte, regretExPost, duration
    ) %>%
    mutate(
      r1_beliefA = as.numeric(Q14_1_1),
      r1_beliefB = as.numeric(Q14_1_2),
      r1_beliefA_below = as.numeric(r1beliefs_alt1_1),
      r1_beliefA_equal = as.numeric(r1beliefs_alt1_2),
      r1_beliefA_above = as.numeric(r1beliefs_alt1_3),
      r1_beliefB_below = as.numeric(r1beliefs_alt2_1),
      r1_beliefB_equal = as.numeric(r1beliefs_alt2_2),
      r1_beliefB_above = as.numeric(r1beliefs_alt2_3),
      r1_choice_str    = as.numeric(choice_strength_r1)
    ) %>%
    select(!c(starts_with("r1_beliefs"), Q14_1_1, Q14_1_2, choice_strength_r1)) %>%
    inner_join(orders, by = "id") %>%
    mutate(short = ifelse(rand_long_short_order == "short_first", 1, 0),
           round = 1) %>%
    rename(choiceB = choice_round_1.1,
           beliefA = r1_beliefA, beliefB = r1_beliefB,
           beliefA_below = r1_beliefA_below, beliefA_equal = r1_beliefA_equal,
           beliefA_above = r1_beliefA_above, beliefB_below = r1_beliefB_below,
           beliefB_equal = r1_beliefB_equal, beliefB_above = r1_beliefB_above,
           whichFirst = r1_whichFirst, choiceStr = r1_choice_str) %>%
    select(!starts_with("r1beliefs"))

  df_comb <- dfr1 %>%
    mutate(choiceB = as.numeric(choiceB) - 1) %>%
    na.omit() %>%
    inner_join(viewTimes, by = "id") %>%
    inner_join(prolific, by = "id")

  write_clean(df_comb, output)

  # View times
  df_comb %>%
    select(id, contains("view")) %>%
    mutate(df = output) %>%
    write.csv(file.path(clean_dir, "viewTimes", paste0(output, ".csv")),
              row.names = FALSE, quote = FALSE)

  # Sampling order
  sampOrder <- read_raw(input) %>%
    rename(id = prolific_id) %>%
    select(id, round1_combined_array)
  sampOrder[-1, ] %>%
    mutate(df = output) %>%
    write.csv(file.path(clean_dir, "Sampling Order", paste0(output, ".csv")),
              row.names = FALSE, quote = TRUE)
}

# ---------------------------------------------------------------------------
# Family 3: interference experiments  (v21, v27)
#
# Like family 2, but two colour conditions (Blue / Orange) each with their own
# view-time block (Q57 / Q218), whichFirst derived from the choice-screen
# colour ordering, an `a3Col` column kept, and de-duplication on id.
# `trials_name`/`views_name`/`sampling_name` let the two experiments keep their
# (historically different) output file names; `write_ids` emits an id-only file.
# ---------------------------------------------------------------------------

clean_interference <- function(input, output,
                               trials_name, views_name, sampling_name,
                               write_ids = FALSE) {
  prolific <- load_prolific(output)

  orders <- read_raw(input) %>%
    rename(id = prolific_id) %>%
    select(id, contains("DO")) %>%
    mutate(whichFirst = ifelse(
      str_detect(choice_round_1_DO,
                 "background-color: DodgerBlue.*background-color: orange"),
      "A", "B")) %>%
    select(id, whichFirst)

  viewTimesBlue <- read_raw(input) %>%
    rename(id = prolific_id) %>%
    select(id, contains("Q57_Page.Submit")) %>%
    rename_with(~ paste0("view", 1:11), .cols = 2:12) %>%
    filter(view1 != "")
  viewTimesOrange <- read_raw(input) %>%
    rename(id = prolific_id) %>%
    select(id, contains("Q218_Page.Submit")) %>%
    rename_with(~ paste0("view", 1:11), .cols = 2:12) %>%
    filter(view1 != "")
  viewTimes <- rbind(viewTimesOrange, viewTimesBlue)

  dfr1 <- read_raw(input) %>%
    rename_common() %>%
    select(
      id, bonus_payment, choice_round_1.1, choice_strength_r1,
      rand_long_short_order, cond_beliefs_choice_order,
      Q14_1_1, Q14_1_2, starts_with("r1beliefs"),
      riskTaking, statKnow, regretExAnte, regretExPost, duration, a3Col
    ) %>%
    mutate(
      r1_beliefA = as.numeric(Q14_1_1),
      r1_beliefB = as.numeric(Q14_1_2),
      r1_beliefA_below = as.numeric(r1beliefs_alt1_1),
      r1_beliefA_equal = as.numeric(r1beliefs_alt1_2),
      r1_beliefA_above = as.numeric(r1beliefs_alt1_3),
      r1_beliefB_below = as.numeric(r1beliefs_alt2_1),
      r1_beliefB_equal = as.numeric(r1beliefs_alt2_2),
      r1_beliefB_above = as.numeric(r1beliefs_alt2_3),
      r1_choice_str    = as.numeric(choice_strength_r1)
    ) %>%
    select(!c(starts_with("r1_beliefs"), Q14_1_1, Q14_1_2, choice_strength_r1)) %>%
    inner_join(orders, by = "id") %>%
    mutate(short = ifelse(rand_long_short_order == "short_first", 1, 0),
           round = 1) %>%
    rename(choiceB = choice_round_1.1,
           beliefA = r1_beliefA, beliefB = r1_beliefB,
           beliefA_below = r1_beliefA_below, beliefA_equal = r1_beliefA_equal,
           beliefA_above = r1_beliefA_above, beliefB_below = r1_beliefB_below,
           beliefB_equal = r1_beliefB_equal, beliefB_above = r1_beliefB_above,
           choiceStr = r1_choice_str) %>%
    select(!contains("r1beliefs_"))

  df_comb <- dfr1 %>%
    mutate(choiceB = as.numeric(choiceB) - 1) %>%
    na.omit() %>%
    inner_join(viewTimes, by = "id") %>%
    inner_join(prolific, by = "id") %>%
    distinct(id, .keep_all = TRUE)

  # Trial-level data
  df_comb %>%
    filter(student != "CONSENT_REVOKED") %>%
    mutate(df = output) %>%
    write.csv(file.path(clean_dir, paste0(trials_name, ".csv")),
              row.names = FALSE, quote = FALSE)

  # View times
  df_comb %>%
    select(id, contains("view")) %>%
    mutate(df = output) %>%
    write.csv(file.path(clean_dir, "viewTimes", paste0(views_name, ".csv")),
              row.names = FALSE, quote = FALSE)

  # Sampling order
  sampOrder <- read_raw(input) %>%
    rename(id = prolific_id) %>%
    select(id, round1_combined_array)
  sampOrder[-1, ] %>%
    mutate(df = output) %>%
    write.csv(file.path(clean_dir, "Sampling Order", paste0(sampling_name, ".csv")),
              row.names = FALSE, quote = TRUE)

  # Optional id-only file (used downstream for the interference matching)
  if (write_ids) {
    df_comb %>%
      filter(student != "CONSENT_REVOKED") %>%
      select(id) %>%
      write.csv(file.path(clean_dir, paste0(output, "_IDs.csv")),
                row.names = FALSE, quote = FALSE)
  }
}

# ---------------------------------------------------------------------------
# Family 4: pre-registered experiment  (prereg)
#
# Structurally unique: a single raw file containing BOTH the sampling and the
# description conditions, across two rounds, with condition-dependent belief
# columns and short/long view-time blocks. Kept as its own function.
# ---------------------------------------------------------------------------

clean_prereg <- function(input = "Alex Imas - Michael Ungeheuer - Description Experience Prereg_December 20, 2023_10.59.csv",
                         output = "prereg") {
  prolific <- load_prolific(output)

  orders <- read_raw(input) %>%
    rename(id = prolific_id) %>%
    select(id, contains("DO")) %>%
    mutate(
      r1_whichFirst = case_when(
        str_ends(choice_round_1_DO, "A")  ~ "B",
        str_ends(choice_round_1_DO, "B")  ~ "A",
        str_ends(desc_choice_r1_DO, "A")  ~ "B",
        str_ends(desc_choice_r1_DO, "B")  ~ "A",
        str_ends(desc_choice_r1_DO.1, "A") ~ "B",
        str_ends(desc_choice_r1_DO.1, "B") ~ "A",
        TRUE ~ ""),
      r2_whichFirst = case_when(
        str_ends(choice_round_2_DO, "A")  ~ "B",
        str_ends(choice_round_2_DO, "B")  ~ "A",
        str_ends(desc_choice_r2_DO, "A")  ~ "B",
        str_ends(desc_choice_r2_DO, "B")  ~ "A",
        str_ends(desc_choice_r2_DO.1, "A") ~ "B",
        str_ends(desc_choice_r2_DO.1, "B") ~ "A",
        TRUE ~ "")) %>%
    select(id, r1_whichFirst, r2_whichFirst) %>%
    distinct(id, .keep_all = TRUE)

  choiceStrength_r1 <- read_raw(input) %>%
    rename(id = prolific_id) %>%
    select(id, contains("choice_str") & contains("r1")) %>%
    mutate(choiceStr = do.call(paste0, select(., 2:4)), round = 1) %>%
    select(id, choiceStr, round) %>%
    filter(id != "")
  choiceStrength_r2 <- read_raw(input) %>%
    rename(id = prolific_id) %>%
    select(id, contains("choice_str") & contains("r2")) %>%
    mutate(choiceStr = do.call(paste0, select(., 2:4)), round = 2) %>%
    select(id, choiceStr, round) %>%
    filter(id != "")

  viewTimesShort <- read_raw(input) %>%
    rename(id = prolific_id) %>%
    select(id, contains("Q57_Page.Submit")) %>%
    rename_with(~ paste0("view", 1:11), .cols = 2:12) %>%
    filter(view1 != "") %>%
    mutate(cond_presentation = "sampling_noiseless", short = 1)
  viewTimesLong <- read_raw(input) %>%
    rename(id = prolific_id) %>%
    select(id, contains("Q60_Page.Submit")) %>%
    rename_with(~ paste0("view", 1:51), .cols = 2:52) %>%
    filter(view1 != "") %>%
    mutate(cond_presentation = "sampling_noiseless", short = 0)

  df <- read_raw(input) %>%
    rename_common() %>%
    mutate(
      r1_beliefA = case_when(
        cond_presentation == "sampling_noiseless" ~ as.numeric(Q14_1_1),
        (cond_presentation == "description_noiseless" & cond_beliefs_choice_order == "choice_first")  ~ as.numeric(beliefs_r1_1_1),
        (cond_presentation == "description_noiseless" & cond_beliefs_choice_order == "beliefs_first") ~ as.numeric(beliefs_r1_1_1.1)),
      r1_beliefB = case_when(
        cond_presentation == "sampling_noiseless" ~ as.numeric(Q14_1_2),
        (cond_presentation == "description_noiseless" & cond_beliefs_choice_order == "choice_first")  ~ as.numeric(beliefs_r1_1_2),
        (cond_presentation == "description_noiseless" & cond_beliefs_choice_order == "beliefs_first") ~ as.numeric(beliefs_r1_1_2.1)),
      r2_beliefA = case_when(
        cond_presentation == "sampling_noiseless" ~ as.numeric(Q81_1_1),
        (cond_presentation == "description_noiseless" & cond_beliefs_choice_order == "choice_first")  ~ as.numeric(beliefs_r2_1_1),
        (cond_presentation == "description_noiseless" & cond_beliefs_choice_order == "beliefs_first") ~ as.numeric(beliefs_r2_1_1.1)),
      r2_beliefB = case_when(
        cond_presentation == "sampling_noiseless" ~ as.numeric(Q81_1_2),
        (cond_presentation == "description_noiseless" & cond_beliefs_choice_order == "choice_first")  ~ as.numeric(beliefs_r2_1_2),
        (cond_presentation == "description_noiseless" & cond_beliefs_choice_order == "beliefs_first") ~ as.numeric(beliefs_r2_1_2.1))
    ) %>%
    select(id, bonus_payment,
           choice_round_1.1, choice_round_2.1,
           rand_long_short_order, cond_presentation, cond_beliefs_choice_order,
           r1_beliefA, r1_beliefB, r2_beliefA, r2_beliefB,
           riskTaking, statKnow, regretExAnte, regretExPost, duration,
           contains("beliefs_alt"))

  dfr1 <- df %>%
    select(id, choice_round_1.1, r1_beliefA, r1_beliefB, rand_long_short_order,
           cond_presentation, cond_beliefs_choice_order,
           riskTaking, statKnow, regretExAnte, regretExPost, duration,
           contains("beliefs_alt")) %>%
    unite("beliefA_below", c("beliefs_alt1_r1_1", "beliefs_alt1_r1_1.1", "r1beliefs_alt1_1"), sep = "", remove = TRUE) %>%
    unite("beliefA_equal", c("beliefs_alt1_r1_2", "beliefs_alt1_r1_2.1", "r1beliefs_alt1_2"), sep = "", remove = TRUE) %>%
    unite("beliefA_above", c("beliefs_alt1_r1_3", "beliefs_alt1_r1_3.1", "r1beliefs_alt1_3"), sep = "", remove = TRUE) %>%
    unite("beliefB_below", c("beliefs_alt2_r1_1", "beliefs_alt2_r1_1.1", "r1beliefs_alt2_1"), sep = "", remove = TRUE) %>%
    unite("beliefB_equal", c("beliefs_alt2_r1_2", "beliefs_alt2_r1_2.1", "r1beliefs_alt2_2"), sep = "", remove = TRUE) %>%
    unite("beliefB_above", c("beliefs_alt2_r1_3", "beliefs_alt2_r1_3.1", "r1beliefs_alt2_3"), sep = "", remove = TRUE) %>%
    mutate(short = ifelse(rand_long_short_order == "short_first", 1, 0), round = 1) %>%
    rename(choiceB = choice_round_1.1, beliefA = r1_beliefA, beliefB = r1_beliefB) %>%
    select(!c(rand_long_short_order, contains("beliefs_alt"))) %>%
    inner_join(orders %>% select(id, r1_whichFirst) %>% rename(whichFirst = r1_whichFirst), by = "id") %>%
    inner_join(choiceStrength_r1 %>% select(id, choiceStr), by = "id")

  dfr2 <- df %>%
    select(id, choice_round_2.1, r2_beliefA, r2_beliefB, rand_long_short_order,
           cond_presentation, cond_beliefs_choice_order,
           riskTaking, statKnow, regretExAnte, regretExPost, duration,
           contains("beliefs_alt")) %>%
    unite("beliefA_below", c("beliefs_alt1_r2_1", "beliefs_alt1_r2_1.1", "r2beliefs_alt1_1"), sep = "", remove = TRUE) %>%
    unite("beliefA_equal", c("beliefs_alt1_r2_2", "beliefs_alt1_r2_2.1", "r2beliefs_alt1_2"), sep = "", remove = TRUE) %>%
    unite("beliefA_above", c("beliefs_alt1_r2_3", "beliefs_alt1_r2_3.1", "r2beliefs_alt1_3"), sep = "", remove = TRUE) %>%
    unite("beliefB_below", c("beliefs_alt2_r2_1", "beliefs_alt2_r2_1.1", "r2beliefs_alt2_1"), sep = "", remove = TRUE) %>%
    unite("beliefB_equal", c("beliefs_alt2_r2_2", "beliefs_alt2_r2_2.1", "r2beliefs_alt2_2"), sep = "", remove = TRUE) %>%
    unite("beliefB_above", c("beliefs_alt2_r2_3", "beliefs_alt2_r2_3.1", "r2beliefs_alt2_3"), sep = "", remove = TRUE) %>%
    mutate(short = ifelse(rand_long_short_order == "short_first", 0, 1), round = 2) %>%
    rename(choiceB = choice_round_2.1, beliefA = r2_beliefA, beliefB = r2_beliefB) %>%
    select(!c(rand_long_short_order, contains("beliefs_alt"))) %>%
    inner_join(orders %>% select(id, r2_whichFirst) %>% rename(whichFirst = r2_whichFirst), by = "id") %>%
    inner_join(choiceStrength_r2 %>% select(id, choiceStr), by = "id")

  rbind(dfr1, dfr2) %>%
    mutate(choiceB = as.numeric(choiceB) - 1) %>%
    na.omit() %>%
    inner_join(prolific, by = "id") %>%
    write_clean(output)

  # View-time blocks (sampling condition only)
  viewTimesLong %>%
    mutate(df = output) %>%
    write.csv(file.path(clean_dir, "viewTimes", paste0(output, "_long.csv")),
              row.names = FALSE, quote = FALSE)
  viewTimesShort %>%
    mutate(df = output) %>%
    write.csv(file.path(clean_dir, "viewTimes", paste0(output, "_short.csv")),
              row.names = FALSE, quote = FALSE)

  # Sampling order (per round)
  sampOrder <- read_raw(input) %>%
    rename(id = prolific_id) %>%
    select(id, round1_combined_array, round2_combined_array)
  sampOrder[-1, ] %>%
    select(id, round1_combined_array) %>%
    mutate(df = output) %>%
    write.csv(file.path(clean_dir, "Sampling Order", paste0(output, "_round1.csv")),
              row.names = FALSE, quote = TRUE)
  sampOrder[-1, ] %>%
    select(id, round2_combined_array) %>%
    mutate(df = output) %>%
    write.csv(file.path(clean_dir, "Sampling Order", paste0(output, "_round2.csv")),
              row.names = FALSE, quote = TRUE)
}

# ---------------------------------------------------------------------------
# Run every experiment used by the paper
# ---------------------------------------------------------------------------

raw_files <- list(
  v5  = "Alex Imas - Michael Ungeheuer - Description Experience v5_December 20, 2023_09.23.csv",
  v13 = "Alex Imas - Michael Ungeheuer - Description Experience v13_December 20, 2023_09.55.csv",
  v11 = "Alex Imas - Michael Ungeheuer - Description Experience v11_December 20, 2023_10.05.csv",
  v17 = "Alex Imas - Michael Ungeheuer - Description Experience v17_December 20, 2023_10.10.csv",
  v24 = "Alex Imas - Michael Ungeheuer - Description Experience v24_December 26, 2023_15.45.csv",
  v21 = "Alex Imas - Michael Ungeheuer - Description Experience v21_December 20, 2023_10.36.csv",
  v27 = "Alex Imas - Michael Ungeheuer - Description Experience v27_January 8, 2024_14.40.csv"
)

# Family 1: two-round, paste-pair beliefs
clean_two_round_paste(raw_files$v5,  "v5")
clean_two_round_paste(raw_files$v13, "v13")
clean_two_round_paste(raw_files$v11, "v11", extra_keep = "oddState")

# Family 2: one-round, single-column beliefs (view_n = number of view pages)
clean_one_round_single(raw_files$v17, "v17", view_n = 11)
clean_one_round_single(raw_files$v24, "v24", view_n = 3)

# Family 3: interference experiments
clean_interference(raw_files$v21, "v21",
                   trials_name = "v21", views_name = "v21", sampling_name = "v21")
clean_interference(raw_files$v27, "v27",
                   trials_name = "v27_trials", views_name = "v27_views",
                   sampling_name = "v27_sampling", write_ids = TRUE)

# Family 4: pre-registered experiment
clean_prereg()

message("Cleaning complete. Clean data written to: ", clean_dir)
