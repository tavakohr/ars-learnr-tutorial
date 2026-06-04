# Chapter 6 — R Ecosystem and Tools

## 6.1 Overview

The R ecosystem for ARS currently covers three parts of the pipeline well and one part poorly. Understanding exactly what each tool does and where it stops is essential before designing `arsbridge`.

```
SAP ──→ ARM-TS ──→ ADaM ──→ ARD ──→ Display
          ↑                  ↑          ↑
     [NOT COVERED]     [{cards}]   [{gtsummary}]
     [arsbridge]       [{cardx}]   [{rtables}]
          ↑                           ↑
     [NOT COVERED]            [{datasetjson}]
     [arsbridge]               (exchange format)
```

---

## 6.2 {cards} — CDISC Analysis Results Data

**Repository:** https://github.com/insightsengineering/cards  
**Maintainer:** Roche, GSK, Novartis (Insights Engineering)  
**CRAN:** Yes  
**Purpose:** Generate ARD data frames from R data

### What it Does

`{cards}` generates flat ARD-structured data frames from analysis datasets. It is the primary tool for producing the ARD layer.

### Core Functions

| Function | Purpose | Example Use |
|----------|---------|-------------|
| `ard_continuous()` | Summary stats (n, mean, sd, median, min, max, quantiles) | Age, lab values, vital signs |
| `ard_categorical()` | Frequency tables | AE preferred terms, sex, race |
| `ard_dichotomous()` | Binary counts and percentages | Any TEAE flag, response flag |
| `ard_missing()` | Missing data summaries | Missing lab values |
| `ard_total_n()` | Total N per group | Denominators for percentages |
| `ard_stack()` | Combine multiple ARD data frames | Build a full table's ARD |
| `ard_fmt_args()` | Set formatting arguments | Apply display formats |

### Basic Usage

```r
library(cards)
library(dplyr)

# Load ADSL
adsl <- haven::read_sas("adsl.sas7bdat") %>%
  filter(SAFFL == "Y")   # Apply AnalysisSet manually

# ARD for age summary by treatment
ard_age <- ard_continuous(
  data = adsl,
  by = TRT01A,
  variables = AGE
)

# ARD for sex by treatment (categorical)
ard_sex <- ard_categorical(
  data = adsl,
  by = TRT01A,
  variables = SEX
)

# Combine
ard_demog <- ard_stack(ard_age, ard_sex)
```

### What {cards} Does NOT Do

- It does not read or parse ARM-TS JSON
- It does not know about AnalysisSets — you apply population filters manually before calling it
- It does not know about GroupingFactor definitions — you pass the grouping variable directly
- It does not link the ARD back to the analysis specification
- It does not produce ARM-TS from annotated shells

---

## 6.3 {cardx} — Extended ARD Utilities

**Repository:** https://github.com/insightsengineering/cardx  
**Purpose:** More complex statistical analyses for ARD generation

`{cardx}` extends `{cards}` with functions for statistics that require additional packages:

| Function | Purpose | Example Use |
|----------|---------|-------------|
| `ard_survival_survfit()` | Kaplan-Meier estimates | Overall survival at timepoints |
| `ard_regression()` | Model-based summaries | Logistic / Cox regression results |
| `ard_stats_t_test()` | t-test ARD | Treatment comparison p-values |
| `ard_stats_wilcox_test()` | Wilcoxon ARD | Non-parametric comparisons |
| `ard_stats_chisq_test()` | Chi-square test ARD | Categorical comparisons |
| `ard_stats_fisher_test()` | Fisher's exact test | Small cell frequencies |
| `ard_cmh_test()` | Cochran-Mantel-Haenszel | Stratified AE comparisons |

### KM Analysis Example (relevant for ADTTE)

```r
library(cardx)
library(survival)

adtte_os <- adtte %>%
  filter(PARAMCD == "OS" & ITTFL == "Y")   # Apply DataSubset manually

ard_km_os <- ard_survival_survfit(
  data = adtte_os,
  by = TRT01A,
  variables = c(time = "AVAL", event = "1-CNSR"),
  times = c(6, 12, 18, 24)
)
```

---

## 6.4 {gtsummary} — Table Generation from ARD

**Repository:** https://github.com/ddsjoberg/gtsummary  
**Purpose:** Render clinical trial tables from ARD data frames

`{gtsummary}` consumes ARD objects produced by `{cards}` and renders them into formatted tables. In recent versions (3.x), it has been refactored to use ARD as its core data structure.

### Usage Pattern

```r
library(gtsummary)

# Create a demographics table from ARD
tbl_ard_summary(
  cards = ard_demog,
  by = TRT01A,
  variables = c(AGE, SEX, RACE)
) %>%
  add_overall() %>%
  modify_header(label = "Characteristic") %>%
  modify_caption("Table 14.1.1 Demographic Characteristics")
```

The output is a formatted table object that can be rendered to RTF, PDF, or HTML — matching typical TLF delivery formats.

### What {gtsummary} Does NOT Do

- It does not produce ARM-TS
- It does not link output display sections (title, footnotes) to `OutputDisplay` objects in the formal model
- It does not validate that the table matches what ARM-TS specifies

---

## 6.5 {datasetjson} — CDISC Dataset-JSON Exchange Format

**Repository:** https://github.com/atorus-research/datasetjson  
**CRAN:** Yes (v0.3.0)  
**Purpose:** Read and write CDISC Dataset-JSON files for regulatory submission

Dataset-JSON is the new exchange format that the FDA is evaluating as a replacement for SAS XPT. It serializes analysis datasets (SDTM, ADaM) as JSON with CDISC-compliant metadata.

```r
library(datasetjson)

# Read a Dataset-JSON file
adsl <- read_dataset_json("adsl.json")

# Write a data frame as Dataset-JSON
write_dataset_json(
  data = adsl,
  file = "adsl_submission.json",
  file_metadata = set_file_metadata(
    originator = "Sponsor Inc.",
    sys_generated_flag = FALSE
  ),
  dataset_metadata = set_dataset_metadata(
    domain = "ADSL",
    label = "Subject Level Analysis Dataset"
  )
)
```

### Relevance to ARS

Dataset-JSON handles the *dataset exchange* layer. The R Consortium used it for the FDA Pilot 4 submission (fall 2025). ARS ARM-TS is a separate JSON structure that lives alongside Dataset-JSON — ARM-TS encodes the analysis specification, Dataset-JSON encodes the datasets.

---

## 6.6 The ARS JSON Parser Gap

None of the above tools read or write ARM-TS JSON. There is no R function that does any of the following:

- Parse an ARM-TS JSON file into an R list/object
- Extract `AnalysisSet` conditions from ARM-TS and apply them as dplyr filters
- Generate an ARM-TS JSON from a structured annotated shell
- Render an ARM-TS JSON as a human-readable annotated shell
- Validate that an ARD is consistent with its ARM-TS specification

This is the gap. The CDISC model YAML (`ars_ldm.yaml`) defines the schema. The schema defines every object, every slot, every constraint. But no R package implements:

```r
parse_ars("reporting_event.json")      # → R list of ARS objects
ars_to_shell(re, output_id = "OUT001") # → Excel annotated shell
shell_to_ars("annotated_shell.xlsx")   # → ARM-TS JSON
validate_ard_vs_ars(ard, re)           # → traceability report
```

This is what `arsbridge` builds.

---

## 6.7 siera (Clymb Clinical) — Closed-Source Comparison

For completeness: `siera` is a commercial R package from Clymb Clinical that:
- Automates ARD generation
- Claims traceability linking
- Integrates with their eTFL portal

It is proprietary, not on CRAN, and requires a commercial license. It is the closest thing to what `arsbridge` would do — but it is not open-source, not pharmaverse-aligned, and is developed by the same team (Bhavin Busa) who leads the ARS standard. The open-source community version of this capability does not exist.

---

## 6.8 Tool Coverage Summary

| Capability | Tool | Coverage |
|------------|------|----------|
| Generate ARD from ADaM | {cards} + {cardx} | ✅ Good |
| Render tables from ARD | {gtsummary}, {rtables} | ✅ Good |
| Exchange datasets as JSON | {datasetjson} | ✅ Good |
| Parse ARM-TS JSON into R | — | ❌ Missing |
| Generate ARM-TS from annotated shell | — | ❌ Missing |
| Render ARM-TS as annotated shell | — | ❌ Missing |
| Validate ARD against ARM-TS | — | ❌ Missing |
| Apply AnalysisSet from ARM-TS to data | — | ❌ Missing |

The bottom four rows are `arsbridge`.

---

## Chapter 6 Summary

- `{cards}` and `{cardx}` generate ARDs from ADaM — well-covered
- `{gtsummary}` renders tables from ARDs — well-covered
- `{datasetjson}` handles dataset exchange — well-covered
- The ARM-TS layer — parsing, generating, rendering, validating — is entirely uncovered in open source
- `siera` is the only existing tool in this space but is commercial and closed

**Next:** Chapter 7 — Package Design Roadmap
