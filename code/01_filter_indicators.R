# ============================================================
# NFHS-5 State Data Filter
# Target indicators: 119, 120, 121, 122, 123, 125
# Output: state + indicator + nfhs5_total (all-India row excluded)
# Run from the repository root.
# ============================================================

library(dplyr)
library(readr)
library(stringr)

# -----------------------------------------------------------
# 1. Load data
# -----------------------------------------------------------
nfhs_raw <- read_csv("data/source/nfhs5_state_factsheet_indicators.csv", show_col_types = FALSE)

cat("Loaded:", nrow(nfhs_raw), "rows across", n_distinct(nfhs_raw$state), "states\n")
cat("Columns:", paste(names(nfhs_raw), collapse = ", "), "\n\n")

# -----------------------------------------------------------
# 2. Extract numeric indicator index from the indicator column
#    Indicators are formatted as "119. Women who..." etc.
# -----------------------------------------------------------
nfhs_raw <- nfhs_raw %>%
  mutate(
    indicator_num = as.integer(str_extract(indicator, "^\\d+"))
  )

# -----------------------------------------------------------
# 3. Filter for target indicators
# -----------------------------------------------------------
target_indicators <- c(119, 120, 121, 122, 123, 125)

nfhs_filtered <- nfhs_raw %>%
  filter(indicator_num %in% target_indicators,
         state != "India") %>%   # drop the all-India aggregate: units are states/UTs only
  select(state, indicator_num, indicator, nfhs5_total) %>%
  arrange(state, indicator_num)

cat("Filtered dataset:\n")
cat("  Rows   :", nrow(nfhs_filtered), "\n")
cat("  States :", n_distinct(nfhs_filtered$state), "\n")
cat("  Indicators confirmed present:", paste(sort(unique(nfhs_filtered$indicator_num)), collapse = ", "), "\n\n")

# -----------------------------------------------------------
# 4. Preview
# -----------------------------------------------------------
print(head(nfhs_filtered, 12))

# -----------------------------------------------------------
# 5. Export
# -----------------------------------------------------------
write_csv(nfhs_filtered, "data/processed/nfhs5_indicators_119_125_long.csv")

cat("\nExported: nfhs5_indicators_119_125_long.csv\n")
