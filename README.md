# CDISC Analysis Results Standard (ARS) — Interactive R Tutorial

> Hands-on **learnr** tutorial covering CDISC ARS v1.0 — from annotated TLF
> shells to ARM-TS JSON, with live exercises on real **pharmaverse** datasets.

A seven-chapter interactive course that takes a clinical R or SAS programmer
from "what is ARS?" all the way to prototyping the core helpers of a future
open-source R package (`arsbridge`) that bridges annotated TLF shells and the
formal ARS model.

Every chapter mixes narrative theory with **runnable code exercises** (graded
with `{gradethis}`) and **knowledge-check quizzes**. All exercises use real
pharmaverse ADaM datasets (`adsl`, `adae`, `adtte`, `adlb`) and a sample ARM-TS
JSON (`data/reporting_event.json`) derived from the CDISC Pilot Study.

---

## Who This Is For

- **Clinical R / SAS programmers** who write or QC annotated TLF shells and
  want to understand how their existing workflow maps to CDISC ARS
- **Lead programmers and statisticians** preparing for ARS-conformant
  submissions (FDA Dataset-JSON, R Consortium Pilot 4+, CDISC 360i)
- **Pharmaverse contributors** interested in the open-source ARM-TS gap and
  how `{cards}`, `{cardx}`, `{gtsummary}`, and `{datasetjson}` fit together
- **R package authors** thinking about building tooling on top of the ARS v1.0
  specification

---

## Chapter Overview

| # | Chapter | What you learn / build |
|---|---------|------------------------|
| 1 | [Why ARS Exists](ars_tutorial_ch1.Rmd) | The five chronic problems ARS was built to solve; the regulatory signals; why your annotated shell IS a manual ARM-TS |
| 2 | [The ARS Data Model](ars_tutorial_ch2.Rmd) | The complete object hierarchy; the WhereClause system; translating ARM-TS filters into dplyr |
| 3 | [ARM-TS Deep Dive](ars_tutorial_ch3.Rmd) | Every major ARM-TS object (`ReportingEvent`, `AnalysisSet`, `Method`, `Analysis`, `Output`…); build them by hand from a shell annotation |
| 4 | [ARD Deep Dive](ars_tutorial_ch4.Rmd) | `OperationResult`, the flat-ARD format, generating continuous / dichotomous / KM ARDs with `{cards}` and `{cardx}` |
| 5 | [The Traceability Chain](ars_tutorial_ch5.Rmd) | End-to-end worked example: SAP → ARM-TS → ADaM → R → ARD → display; detect a population traceability break and a format-consistency break |
| 6 | [R Ecosystem and Tools](ars_tutorial_ch6.Rmd) | Where `{cards}`, `{cardx}`, `{gtsummary}`, `{datasetjson}` cover the pipeline and where the open-source ARM-TS gap sits |
| 7 | [Package Design Roadmap: arsbridge](ars_tutorial_ch7.Rmd) | The v0.1 design — five functions, the build sequence, internal helpers; prototype `where_clause_to_text()` and the ID-indexed parser |

The original chapter source materials live in [`materials/`](materials/).

---

## Quick Start

### 1 — Install the R dependencies

```r
install.packages(c(
  "learnr",           # interactive tutorial engine
  "gradethis",        # exercise grading
  "pharmaverseadam",  # ADaM datasets: ADSL, ADAE, ADTTE, ADLB
  "pharmaversesdtm",  # SDTM datasets
  "dplyr",
  "cards",            # ARD generation
  "cardx",            # extended ARD (KM, regression)
  "gtsummary",        # render ARD as clinical tables
  "jsonlite",         # parse ARM-TS JSON
  "glue"
))
```

If `pharmaverseadam` / `pharmaversesdtm` are not on CRAN in your region:

```r
remotes::install_github("pharmaverse/pharmaverseadam")
remotes::install_github("pharmaverse/pharmaversesdtm")
```

### 2 — Run a chapter

In R:

```r
rmarkdown::run("ars_tutorial_ch1.Rmd")
```

Or in RStudio: open any `ars_tutorial_ch*.Rmd` and click **"Run Document"**.

Each chapter opens in your browser as a self-contained interactive tutorial
with a green-accented left navigation, live code editors, hints, solutions,
and quizzes.

---

## Repository Structure

```
ars-learnr-tutorial/
├── ars_tutorial_ch1.Rmd        ← Chapter 1: Why ARS Exists
├── ars_tutorial_ch2.Rmd        ← Chapter 2: The ARS Data Model
├── ars_tutorial_ch3.Rmd        ← Chapter 3: ARM-TS Deep Dive
├── ars_tutorial_ch4.Rmd        ← Chapter 4: ARD Deep Dive
├── ars_tutorial_ch5.Rmd        ← Chapter 5: The Traceability Chain
├── ars_tutorial_ch6.Rmd        ← Chapter 6: R Ecosystem and Tools
├── ars_tutorial_ch7.Rmd        ← Chapter 7: arsbridge Package Design
│
├── data/
│   └── reporting_event.json    ← Sample ARM-TS (CDISC-Pilot-style)
│
├── www/
│   └── custom.css              ← White background, light-green accents
│
├── materials/                  ← Chapter source narratives (one .md per chapter)
│   ├── 00_README.md
│   ├── 01_Why_ARS_Exists.md
│   ├── 02_ARS_Data_Model.md
│   ├── 03_ARM_TS_Deep_Dive.md
│   ├── 04_ARD_Deep_Dive.md
│   ├── 05_Traceability_Chain.md
│   ├── 06_R_Ecosystem_and_Tools.md
│   └── 07_Package_Design_Roadmap.md
│
├── setup_renv.R                ← Optional: set up an renv project lockfile
├── .gitignore
└── README.md
```

> Rendered `*.html` files and the build-instructions doc are intentionally
> excluded from version control — see `.gitignore`. Re-render any chapter
> locally with `rmarkdown::run()`.

---

## The Sample Data

- **ADaM datasets** come from `{pharmaverseadam}` — the same data shape used
  in the public CDISC Pilot submission. `ADSL` carries `SAFFL`, `TRT01A`,
  `AGE`, `SEX`; `ADAE` carries `TRTEMFL`, `AEDECOD`; `ADTTE` carries
  `PARAMCD`, `AVAL`, `CNSR`.
- **`data/reporting_event.json`** is a minimal but complete `ReportingEvent`
  with one `Analysis` (Age summary by treatment arm, Safety population),
  two `AnalysisSets` (ITT, Safety), one `GroupingFactor` (Treatment Arm),
  one `AnalysisMethod` (n, Mean, SD, Median, Min, Max), and six stored
  `OperationResult` rows. It is the running case study across all seven
  chapters.

---

## Custom Theme

The left navigation uses a clean **white background with light-green text
accents** (Inter / Lato sans-serif). The theme is defined in
[`www/custom.css`](www/custom.css) and is referenced from every chapter's
YAML header (`css: www/custom.css`).

---

## Roadmap: the `arsbridge` Package

Chapter 7 lays out the v0.1 design for an open-source R package that would
close the ARM-TS gap identified in Chapter 6:

| Function | Purpose |
|----------|---------|
| `parse_ars(file)` | Read an ARM-TS JSON into an ID-indexed R object tree |
| `ars_to_shell(re, output_id)` | Render an ARM-TS as a human-readable Excel annotated shell |
| `shell_to_ars(file, ...)` | Parse a structured annotated shell back into ARM-TS JSON |
| `validate_ard(re, ard)` | Cross-check an ARD against its ARM-TS specification |
| `ars_summary(re)` | Print a human-readable summary of a ReportingEvent |

The hands-on exercises in Chapter 7 prototype `where_clause_to_text()`, the
ID-indexed lookup pattern at the heart of `parse_ars()`, and the Coverage
check inside `validate_ard()`. The actual package lives in a separate
repository (planned).

---

## References

- **ARS v1.0 Specification** — https://cdisc-org.github.io/analysis-results-standard/
- **ARS GitHub (model YAML, examples)** — https://github.com/cdisc-org/analysis-results-standard
- **CDISC Pilot Study data** — https://github.com/cdisc-org/sdtm-adam-pilot-project
- **`{cards}`** — https://insightsengineering.github.io/cards/
- **`{cardx}`** — https://insightsengineering.github.io/cardx/
- **`{gtsummary}`** — https://www.danieldsjoberg.com/gtsummary/
- **`{datasetjson}`** — https://atorus-research.github.io/datasetjson/
- **`{learnr}`** — https://rstudio.github.io/learnr/
- **pharmaverse** — https://pharmaverse.org

---

## Author

**Hamid Tavakoli, MD, MSc**
GitHub: [@tavakohr](https://github.com/tavakohr)

---

## License

This tutorial — narrative content, exercises, and code — is released under
the **MIT License**. The pharmaverse datasets retain their original licenses
(MIT / Apache 2.0). The CDISC ARS specification itself is the property of
CDISC and is referenced here under fair-use educational principles.

---

## Disclaimer

This material represents independent educational work product. It contains no
proprietary items, confidential materials, or intellectual property belonging
to any past, current, or specific organization or corporate entity. All
mappings, standards, and logic used herein are derived strictly from public
CDISC documentation, open-source pharmaverse packages, and simulated /
publicly available pilot data.
