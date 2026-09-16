# Codebook

## Unit of analysis

State or union territory as reported in the NFHS-5 (2019–21) state factsheets.
*n* = 36 (28 states, 8 union territories). The all-India aggregate row present in
the source table is excluded by `code/01_filter_indicators.R`.

## Source variables

All values are the `nfhs5_total` column (urban + rural combined). Indicator
numbers follow the NFHS-5 state factsheet numbering. The trailing digits in the
source wording (e.g. "decisions25") are factsheet footnote markers, not part of
the indicator.

| Code | NFHS-5 indicator | Factsheet wording | Used in |
|---|---|---|---|
| `dec` | 119 | Currently married women who usually participate in three household decisions (%) | Voice index |
| `cash` | 120 | Women who worked in the last 12 months and were paid in cash (%) | Economic index |
| `land` | 121 | Women owning a house and/or land (alone or jointly with others) (%) | Economic index |
| `bank` | 122 | Women having a bank or savings account that they themselves use (%) | Economic index |
| `phone` | 123 | Women having a mobile phone that they themselves use (%) | Voice index |
| `viol` | 125 | Ever-married women age 18–49 years who have ever experienced spousal violence (%) | Outcome |

Note the denominators differ: 119 is currently married women, 120–123 are all
women age 15–49, 125 is ever-married women 18–49. The indices combine them as
published percentages without adjustment.

## Index construction

Each component is min–max scaled across the 36 units to a 0–100 range:

    scaled = (x − min(x)) / (max(x) − min(x)) × 100

Indices are unweighted means of scaled components:

    voice_index = (scaled(dec) + scaled(phone)) / 2
    econ_index  = (scaled(cash) + scaled(land) + scaled(bank)) / 3

`gap = voice_index − econ_index`. A state is labelled "Voice-led" if gap ≥ 0 and
"Economy-led" otherwise.

No component is reverse-coded. There are no missing values for these six
indicators across the 36 units; `drop_na()` in the script is a guard, not an
active step.

## Results (n = 36)

| Relationship | Pearson *r* | *p* | Spearman ρ | *p* |
|---|---|---|---|---|
| Voice index vs violence | −0.505 | 0.002 | −0.560 | <0.001 |
| Economic index vs violence | +0.461 | 0.005 | +0.375 | 0.024 |

Component correlations with violence (Pearson): `dec` −0.34, `phone` −0.48,
`cash` +0.30, `land` +0.41, `bank` +0.23. The voice index is carried mainly by
phone ownership and the economic index mainly by house/land ownership.

## Output files

- `data/processed/nfhs5_indicators_119_125_long.csv` — six indicators, long format, 216 rows
- `data/processed/autonomy_violence_scores.csv` — `state, voice_index, econ_index, violence_pct`
- `data/processed/autonomy_gap_ranking.csv` — the above plus `gap` and `type`, sorted by gap

## Known limitations

See "What this does and does not show" in the README. In addition: the scaling
is relative to the sample, so an index value of 100 means "highest among the 36
units in NFHS-5", not an absolute level, and values are not comparable to a
future NFHS round without rescaling on the pooled data.
