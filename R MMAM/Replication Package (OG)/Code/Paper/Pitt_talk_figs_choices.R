## ---------------------------
##
## Pitt_talk_figs_choices.R
##
## Input:  Pooled trial-level data (`combinedDF`) from 02_combine_data.R
##
## Output: Choice-share figures (% choices for Asset B) by condition
##
## Author: Josh Hascher
##
## Date Created: 4/4/2024
##
## ---------------------------
##
## Notes: Data assembly now lives in 02_combine_data.R, which this script
##        sources. Edit the pooling logic there, not here.
## ---------------------------

# Clear the workspace
rm(list = ls())

# Load necessary libraries
library(tidyverse)
library(scales)

# Locate the repository root and build the pooled data set (`combinedDF`).
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
root <- find_repo_root()
source(file.path(root, "Code", "Paper", "02_combine_data.R"))

sum <- combinedDF %>%
  #filter(choiceStr != 1) %>%
  group_by(df,cond) %>%
  summarise(percB = mean(choiceB),
            n = n(),
            sd = round(sd(choiceB, na.rm = T),3),
            se = round(sd(choiceB, na.rm = TRUE) / sqrt(n()),3)
  )
sum$`Percent Choices Asset B` <- (sum$percB)
sum$df <- factor(sum$df, levels = c("Interference_A", "Interference_B","BoxRight", "NoBox", "Random", "Record", "PR Sampling"))

# All conditions
p <- ggplot(sum, aes(x = df, y = `Percent Choices Asset B`, fill = cond)) +  # Fill by 'cond' which represents conditions
  geom_bar(stat = "identity") +
  geom_errorbar(aes(ymin = percB - se, ymax = percB + se), position = position_dodge(.5), width = .15) +
  labs(x = "Condition", y = "% Choices Asset B (Freq. Better)", title = "") +
  scale_y_continuous(labels = scales::percent,
                     limits = c(0, 1),
                     breaks = seq(0, 1, by = .10)) + # To show y-axis labels as percentages
  theme_minimal() +
  geom_hline(yintercept = .5) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) # Rotate x-axis labels

# Add annotations
p + annotate("text", x = 4, y = .98, label = "Desc-Exp Gap (pre-reg)", size = 3, vjust = 0) +
  annotate("segment", x = 2, xend = 6, y = .95, yend = .95) +
  annotate("segment", x = 2, xend = 2, y = .93, yend = .97) +
  annotate("segment", x = 6, xend = 6, y = .93, yend = .97) +
  annotate("text", x = 4.5, y = .83, label = "No salience no memory", size = 3, vjust = 0) +
  annotate("segment", x = 4, xend = 5, y = .8, yend = .8) +
  annotate("segment", x = 4, xend = 4, y = .78, yend = .82) +
  annotate("segment", x = 5, xend = 5, y = .78, yend = .82)

# Baseline
baseData <- sum %>%
  ungroup() %>%
  filter(df == "BoxRight" | df == "PR Sampling") %>%
  mutate(cond = ifelse(
    cond == "Description",
    "Simultaneous",
    "Sequential"
  ),
         df = ifelse(
    df == "BoxRight",
    "Baseline ",
    "Baseline"
  ))
baseline <- ggplot(baseData , aes(x = df, y = `Percent Choices Asset B`, fill = cond)) +  # Fill by 'cond' which represents conditions
  geom_bar(stat = "identity") +
  geom_errorbar(aes(ymin = percB - se, ymax = percB + se), position = position_dodge(.5), width = .15) +
  labs(x = "", y = "% of Choices for Asset B (Freq. Better)", title = "", fill = "Condition") +
  scale_y_continuous(labels = scales::percent,
                     limits = c(0, 1),
                     breaks = seq(0, 1, by = .10)) + # To show y-axis labels as percentages
  theme_minimal() +
  annotate("segment", x = 0, xend = 6.5, y = .5, yend = .5, linetype = "dashed") +
  # # geom_hline(yintercept = .5,linetype = "dashed") +
  theme(axis.text.x = element_text(size = 10)) # Rotate x-axis labels
baseline

baseline + annotate("text", x = 1.5, y = .98, label = "Choice Gap: Baseline", size = 3, vjust = 0) #+

# Turn of mechanisms
mechOffData <- sum %>%
  ungroup() %>%
  filter(df == "BoxRight" | df == "PR Sampling" | df == "Record" | df == "Random") %>%
  mutate(cond = case_when(
    cond == "Description" ~ "Simultaneous",
    cond == "Sampling" ~ "Sequential",
    T ~ NA
  ),
  df = case_when(
    df == "BoxRight" ~ "Baseline ",
    df == "PR Sampling" ~ "Baseline",
    df == "Record" ~ "No Recall\nBias",
    df == "Random" ~ "No Salience",
    T ~ NA
  ))
mechOff <- ggplot(mechOffData , aes(x = df, y = `Percent Choices Asset B`, fill = cond)) +  # Fill by 'cond' which represents conditions
  geom_bar(stat = "identity") +
  geom_errorbar(aes(ymin = percB - se, ymax = percB + se), position = position_dodge(.5), width = .15) +
  labs(x = "", y = "% of Choices for Asset B (Freq. Better)", title = "", fill = "Condition") +
  scale_y_continuous(labels = scales::percent,
                     limits = c(0, 1),
                     breaks = seq(0, 1, by = .10)) + # To show y-axis labels as percentages
  theme_minimal() +
  annotate("segment", x = 0, xend = 6.5, y = .5, yend = .5, linetype = "dashed") +
  theme(axis.text.x = element_text(size = 10)) # Rotate x-axis labels
mechOff

mechOff + annotate("text", x = 1.5, y = .98, label = "Choice Gap: Baseline", size = 3, vjust = 0) +
  annotate("text", x = 3.5, y = .81, label = "No Choice Gap:\nNo Salience or Memory Bias", size = 2.5, vjust = 0)

# Include everything
allData1 <- sum %>%
  ungroup() %>%
  filter(df != "NoBox" & df != "Interference_A") %>%
  mutate(cond = case_when(
    cond == "Description" ~ "Simultaneous",
    cond == "Sampling" ~ "Sequential",
    T ~ NA
  ),
  df = case_when(
    df == "BoxRight" ~ "Baseline ",
    df == "PR Sampling" ~ "Baseline",
    df == "Record" ~ "No Recall\nBias",
    df == "Random" ~ "No Salience",
    df == "Interference_B" ~ "Interference\nAsset B",
    T ~ NA
  ))
allData1$df <- factor(allData1$df, levels = c("Baseline", "Baseline ", "No Recall\nBias", "No Salience",
                                            "Interference\nAsset B"))
allFig1 <- ggplot(allData1 , aes(x = df, y = `Percent Choices Asset B`, fill = cond)) +
  geom_bar(stat = "identity") +
  geom_errorbar(aes(ymin = percB - se, ymax = percB + se), position = position_dodge(.5), width = .15) +
  labs(x = "", y = "% of Choices for Asset B (Freq. Better)", title = "", fill = "Condition") +
  scale_y_continuous(labels = scales::percent,
                     limits = c(0, 1),
                     breaks = seq(0, 1, by = .10)) + # To show y-axis labels as percentages
  theme_minimal() +
  annotate("segment", x = 0, xend = 6.5, y = .5, yend = .5, linetype = "dashed") +
  theme(axis.text.x = element_text(size = 10)) # Rotate x-axis labels
allFig1

allFig1 + annotate("text", x = 1.5, y = .98, label = "Choice Gap: Baseline", size = 3, vjust = 0) +
  annotate("text", x = 3.5, y = .81, label = "No Choice Gap:\nNo Salience or Memory Bias", size = 2.5, vjust = 0) +
  annotate("text", x = 5.5, y = .9, label = "")

allData2 <- sum %>%
  ungroup() %>%
  filter(df != "NoBox") %>%
  mutate(cond = case_when(
    cond == "Description" ~ "Simultaneous",
    cond == "Sampling" ~ "Sequential",
    T ~ NA
  ),
  df = case_when(
    df == "BoxRight" ~ "Baseline ",
    df == "PR Sampling" ~ "Baseline",
    df == "Record" ~ "No Recall\nBias",
    df == "Random" ~ "No Salience",
    df == "Interference_A" ~ "Interference\nAsset A",
    df == "Interference_B" ~ "Interference\nAsset B",
    T ~ NA
  ))
allData2$df <- factor(allData2$df, levels = c("Baseline", "Baseline ", "No Recall\nBias", "No Salience",
                                             "Interference\nAsset B", "Interference\nAsset A"))
allFig2 <- ggplot(allData2 , aes(x = df, y = `Percent Choices Asset B`, fill = cond)) +
  geom_bar(stat = "identity") +
  geom_errorbar(aes(ymin = percB - se, ymax = percB + se), position = position_dodge(.5), width = .15) +
  labs(x = "", y = "% of Choices for Asset B (Freq. Better)", title = "", fill = "Condition") +
  scale_y_continuous(labels = scales::percent,
                     limits = c(0, 1),
                     breaks = seq(0, 1, by = .10)) + # To show y-axis labels as percentages
  theme_minimal() +
  annotate("segment", x = 0, xend = 6.5, y = .5, yend = .5, linetype = "dashed") +
  theme(axis.text.x = element_text(size = 10)) # Rotate x-axis labels
allFig2

allFig2 + annotate("text", x = 1.5, y = .98, label = "Choice Gap: Baseline", size = 3, vjust = 0) +
  annotate("text", x = 3.5, y = .81, label = "No Choice Gap:\nNo Salience or Memory Bias", size = 2.5, vjust = 0) +
  annotate("text", x = 5.5, y = .9, label = "")
