# Data sources

## `data/source/nfhs5_state_factsheet_indicators.csv`

Compiled from the NFHS-5 (2019–21) state and union territory factsheets
published by IIPS. Columns:

| Column | Meaning |
|---|---|
| `state` | State/UT name as printed on the factsheet; "India" is the national factsheet |
| `state_code` | Census state code where available |
| `indicator` | Factsheet indicator number and wording, verbatim |
| `nfhs5_urban`, `nfhs5_rural`, `nfhs5_total` | NFHS-5 values |
| `nfhs4_total` | NFHS-4 (2015–16) value as printed on the NFHS-5 factsheet for comparison |

Factsheets: https://rchiips.org/nfhs/factsheet_NFHS-5.shtml
(IIPS and ICF. 2021. *National Family Health Survey (NFHS-5), 2019–21: India.*
Mumbai: IIPS.)

Only published aggregate percentages are included. No unit-level DHS/NFHS
microdata are redistributed in this repository.

## Extraction

Values were transcribed from the factsheet PDFs into the table above. Spot
checks against the PDFs are advised before any reuse beyond this analysis;
transcription errors are the author's responsibility.
