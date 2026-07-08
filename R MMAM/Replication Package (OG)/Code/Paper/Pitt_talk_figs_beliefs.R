## ---------------------------
##
## Pitt_talk_figs_beliefs.R
##
## Input:  Pooled trial-level data (`combinedDF`) from 02_combine_data.R
##
## Output: Belief figures (excess outcome estimate for Asset B) by condition
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

beliefDispersion <- combinedDF %>%
  filter(df != "NoBox",
         beliefA < 5,
         beliefB < 5,
         df == "BoxRight",
         cond != "Sampling") %>%
  mutate(excessB = beliefB - beliefA)

hist(beliefDispersion$beliefA)
hist(beliefDispersion$beliefB)
hist(beliefDispersion$excessB, breaks = 30)

sum <- combinedDF %>%
  filter(df != "NoBox",
         beliefA < 5,
         beliefB < 5) %>%
  #filter(choiceStr != 1) %>%
  mutate(excessB = beliefB - beliefA) %>%
  group_by(df,cond) %>%
  summarise(meanEB = mean(excessB),
            n = n(),
            sd = round(sd(excessB, na.rm = T),3),
            se = round(sd(excessB, na.rm = TRUE) / sqrt(n()),3)
  )
sum$`Excess Estimate of Outcome for Asset B` <- (sum$meanEB)
sum$df <- factor(sum$df, levels = c("Interference_A", "Interference_B","BoxRight", "NoBox", "Random", "Record", "PR Sampling"))

# All conditions
p <- ggplot(sum, aes(x = df, y = `Excess Estimate of Outcome for Asset B`, fill = cond)) +  # Fill by 'cond' which represents conditions
  geom_bar(stat = "identity") +
  geom_errorbar(aes(ymin = meanEB - se, ymax = meanEB + se), position = position_dodge(.5), width = .15) +
  labs(x = "Condition", y = "Excess Estimate of Outcome for Asset B", title = "") +
  scale_y_continuous(limits = c(-.25, 0.5),
                     breaks = seq(-.2, 0.5, by = .10)) + # To show y-axis labels as percentages
  theme_minimal() +
  geom_hline(yintercept = 0) +
  theme(axis.text.x = element_text(size = 10)) # Rotate x-axis labels
p

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
baseline <- ggplot(baseData , aes(x = df, y = `Excess Estimate of Outcome for Asset B`, fill = cond)) +  # Fill by 'cond' which represents conditions
  geom_bar(stat = "identity") +
  geom_errorbar(aes(ymin = meanEB - se, ymax = meanEB + se), position = position_dodge(.5), width = .15) +
  labs(x = "", y = "Excess Estimate of Outcome for Asset B", title = "", fill = "Condition") +
  scale_y_continuous(labels = function(x) paste("$", sprintf("%.2f", x)),
                     limits = c(-.25, 0.5),
                     breaks = seq(-.2, 0.5, by = .10)) + # To show y-axis labels as percentages
  theme_minimal() +
  annotate("segment", x = 0, xend = 6.5, y = 0, yend = 0, linetype = "dashed") +
  # geom_hline(yintercept = .5,linetype = "dashed") +
  theme(axis.text.x = element_text(size = 10)) # Rotate x-axis labels
baseline

baseline + annotate("text", x = 1.5, y = .45, label = "Belief Gap: Baseline", size = 3, vjust = 0)

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
mechOff <- ggplot(mechOffData , aes(x = df, y = `Excess Estimate of Outcome for Asset B`, fill = cond)) +  # Fill by 'cond' which represents conditions
  geom_bar(stat = "identity") +
  geom_errorbar(aes(ymin = meanEB - se, ymax = meanEB + se), position = position_dodge(.5), width = .15) +
  labs(x = "", y = "Excess Estimate of Outcome for Asset B", title = "", fill = "Condition") +
  scale_y_continuous(labels = function(x) paste("$", sprintf("%.2f", x)),
                     limits = c(-.25, 0.5),
                     breaks = seq(-.2, 0.5, by = .10)) + # To show y-axis labels as percentages
  theme_minimal() +
  annotate("segment", x = 0, xend = 6.5, y = 0, yend = 0, linetype = "dashed") +
  theme(axis.text.x = element_text(size = 10)) # Rotate x-axis labels
mechOff

mechOff + annotate("text", x = 1.5, y = .45, label = "Belief Gap: Baseline", size = 3, vjust = 0) +
  annotate("text", x = 3.5, y = .3, label = "No Belief Gap:\nNo Salience or Memory Bias", size = 2.5, vjust = 0)

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
allFig1 <- ggplot(allData1 , aes(x = df, y = `Excess Estimate of Outcome for Asset B`, fill = cond)) +
  geom_bar(stat = "identity") +
  geom_errorbar(aes(ymin = meanEB - se, ymax = meanEB + se), position = position_dodge(.5), width = .15) +
  labs(x = "", y = "Excess Estimate of Outcome for Asset B", title = "", fill = "Condition") +
  scale_y_continuous(labels = function(x) paste("$", sprintf("%.2f", x)),
                     limits = c(-.25, 0.5),
                     breaks = seq(-.2, 0.5, by = .10)) + # To show y-axis labels as percentages
  theme_minimal() +
  annotate("segment", x = 0, xend = 6.5, y = 0, yend = 0, linetype = "dashed") +
  theme(axis.text.x = element_text(size = 10)) # Rotate x-axis labels
allFig1

allFig1 + annotate("text", x = 1.5, y = .45, label = "Choice Gap: Baseline", size = 3, vjust = 0) +
  annotate("text", x = 3.5, y = .3, label = "No Choice Gap:\nNo Salience or Memory Bias", size = 2.5, vjust = 0)

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
allFig2 <- ggplot(allData2 , aes(x = df, y = `Excess Estimate of Outcome for Asset B`, fill = cond)) +
  geom_bar(stat = "identity") +
  geom_errorbar(aes(ymin = meanEB - se, ymax = meanEB + se), position = position_dodge(.5), width = .15) +
  labs(x = "", y = "Excess Estimate of Outcome for Asset B", title = "", fill = "Condition") +
  scale_y_continuous(labels = function(x) paste("$", sprintf("%.2f", x)),
                     limits = c(-.25, 0.5),
                     breaks = seq(-.2, 0.5, by = .10)) + # To show y-axis labels as percentages
  theme_minimal() +
  annotate("segment", x = 0, xend = 6.5, y = 0, yend = 0, linetype = "dashed") +
  theme(axis.text.x = element_text(size = 10)) # Rotate x-axis labels
allFig2

allFig2 + annotate("text", x = 1.5, y = .45, label = "Belief Gap: Baseline", size = 3, vjust = 0) +
  annotate("text", x = 3.5, y = .3, label = "No Belief Gap:\nNo Salience or Memory Bias", size = 2.5, vjust = 0)
