# =============================================================
# Women's Household Autonomy vs Spousal Violence (NFHS-5)
# State-wise two-axis quadrant analysis. Run from the repository root.
# =============================================================
# Indicators in the source file:
#   119 - participates in household decisions   (VOICE)
#   120 - worked & paid in cash                   (ECONOMIC)
#   121 - owns house/land                         (ECONOMIC)
#   122 - has & uses a bank account               (ECONOMIC)
#   123 - has & uses own mobile phone             (VOICE)
#   125 - ever experienced spousal violence       (OUTCOME)
# =============================================================

# ---- 0. Packages -------------------------------------------
# tidyverse gives us dplyr (wrangling), tidyr (reshape), ggplot2 (plot).
# ggrepel keeps state labels from overlapping.

library(tidyverse)
library(ggrepel)

# ---- 1. Read the data --------------------------------------

df <- read_csv("data/processed/nfhs5_indicators_119_125_long.csv")


df <- df %>% mutate(value = as.numeric(nfhs5_total))

# ---- 2. Long -> wide ---------------------------------------
# One row per state; one column per indicator number.
wide <- df %>%
  select(state, indicator_num, value) %>%
  pivot_wider(names_from = indicator_num,
              values_from = value,
              names_prefix = "ind_") %>%
  # rename to readable labels
  rename(dec = ind_119, cash = ind_120, land = ind_121,
         bank = ind_122, phone = ind_123, viol = ind_125) %>%
  drop_na()   # drop states missing any indicator

# ---- 3. Min-max normalize helper ---------------------------
# Rescales a vector to 0-100 so indicators with different spreads
# contribute equally to the composite.
nrm <- function(x) (x - min(x)) / (max(x) - min(x)) * 100

# ---- 4. Build the two autonomy indices ---------------------
scores <- wide %>%
  mutate(
    voice_index = (nrm(dec)  + nrm(phone)) / 2,            # decisions + phone
    econ_index  = (nrm(cash) + nrm(land) + nrm(bank)) / 3, # cash + land + bank
    violence_pct = viol
  ) %>%
  select(state, voice_index, econ_index, violence_pct)

# Save the scores table
write_csv(scores, "data/processed/autonomy_violence_scores.csv")

# ---- 5. Correlations (the slope of each relationship) ------
cor_voice <- cor(scores$voice_index, scores$violence_pct)
cor_econ  <- cor(scores$econ_index,  scores$violence_pct)
cat("Voice index vs violence  r =", round(cor_voice, 2), "\n")
cat("Economic index vs violence r =", round(cor_econ, 2), "\n")

# ---- 6. Reusable quadrant-plot function --------------------
# x_var      = name of the index column to put on the x-axis
# label_mode = "all"      -> label every state (ggrepel spreads them out)
#              "outliers" -> label only states far from BOTH medians
# q          = cutoff for "outliers": label states whose standardized
#              distance from the median-cross is in the top (1 - q) share.
#              q = 0.70 labels roughly the most extreme 30% of states.
quad_plot <- function(data, x_var, x_label, r,
                      label_mode = "all", q = 0.70) {
  mx <- median(data[[x_var]])
  my <- median(data$violence_pct)

  # Decide which states get a text label.
  if (label_mode == "outliers") {
    # Standardized (z-score) distance from the median-cross, so the
    # two axes are comparable even though their units differ.
    d <- sqrt(((data[[x_var]] - mx) / sd(data[[x_var]]))^2 +
              ((data$violence_pct - my) / sd(data$violence_pct))^2)
    data$lab <- ifelse(d >= quantile(d, q), data$state, "")
  } else {
    data$lab <- data$state
  }

  ggplot(data, aes(x = .data[[x_var]], y = violence_pct)) +
    geom_vline(xintercept = mx, linetype = "dashed", colour = "grey60") +
    geom_hline(yintercept = my, linetype = "dashed", colour = "grey60") +
    geom_point(size = 3, colour = "#1f6f8b") +
    geom_text_repel(aes(label = lab), size = 2.8,
                    fontface = "bold", max.overlaps = 30) +
    labs(x = x_label,
         y = "Spousal violence ever experienced (%)",
         title = paste0(x_label, " vs Violence  (r = ", round(r, 2), ")")) +
    theme_minimal(base_size = 11)
}

# label_mode = "all" for the full version; switch to "outliers" to declutter.
p_voice <- quad_plot(scores, "voice_index",
                     "Voice & Decision Autonomy index", cor_voice,
                     label_mode = "outliers")
p_econ  <- quad_plot(scores, "econ_index",
                     "Economic Autonomy index", cor_econ,
                     label_mode = "outliers")

# ---- 7. Save panels ----------------------------------------
ggsave("figures/autonomy_voice_quadrant.png",    p_voice, width = 8, height = 7, dpi = 150)
ggsave("figures/autonomy_economic_quadrant.png", p_econ,  width = 8, height = 7, dpi = 150)

# Optional: side-by-side if 'patchwork' is installed
# install.packages("patchwork"); library(patchwork)
# ggsave("autonomy_vs_violence_quadrants.png", p_voice + p_econ,
#        width = 16, height = 7, dpi = 150)

cat("Done. Wrote scores CSV and two quadrant PNGs.\n")
writeLines(capture.output(sessionInfo()), "code/sessionInfo.txt")

# ---- 8. Voice-minus-economic gap ranking -------------------
# Where do the two forms of autonomy diverge?
#   gap > 0 (green) -> VOICE-LED: decisions/phone outrun assets/income
#   gap < 0 (red)   -> ECONOMY-LED: assets/income outrun voice
gap_df <- scores %>%
  mutate(gap = voice_index - econ_index,
         type = ifelse(gap >= 0, "Voice-led", "Economy-led")) %>%
  arrange(gap)   # most economy-led at top of the data, voice-led at bottom

write_csv(gap_df, "data/processed/autonomy_gap_ranking.csv")

# Lock the bar order to the ranking (factor levels = sorted states).
gap_df <- gap_df %>%
  mutate(state = factor(state, levels = state))

p_gap <- ggplot(gap_df, aes(x = gap, y = state, fill = type)) +
  geom_col() +
  geom_vline(xintercept = 0, colour = "black", linewidth = 0.4) +
  geom_text(aes(label = sprintf("%+.0f", gap),
                hjust = ifelse(gap >= 0, -0.15, 1.15)),
            size = 2.6) +
  scale_fill_manual(values = c("Voice-led" = "#27ae60",
                               "Economy-led" = "#c0392b")) +
  labs(x = "Voice index  minus  Economic index  (points, 0-100 scale)",
       y = NULL, fill = NULL,
       title = "Where the two autonomies diverge",
       subtitle = "Green = voice outruns assets/income | Red = assets/income outrun voice") +
  theme_minimal(base_size = 11) +
  theme(legend.position = "top")

ggsave("figures/autonomy_gap_ranking.png", p_gap, width = 9, height = 11, dpi = 150)

# Quick console readout of the extremes.
cat("\nMost ECONOMY-LED (voice lags assets):\n")
print(gap_df %>% slice_head(n = 5) %>% select(state, gap))
cat("\nMost VOICE-LED (voice outruns assets):\n")
print(gap_df %>% slice_tail(n = 5) %>% select(state, gap))
