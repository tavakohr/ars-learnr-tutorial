# CDISC Analysis Results Standard (ARS): Interactive R Tutorial

> Hands-on **learnr** tutorial covering CDISC ARS v1.0, from annotated TLF
> shells to ARM-TS JSON, with live exercises on real **pharmaverse** datasets.

A seven-chapter interactive course that takes a clinical R or SAS programmer
from "what is ARS?" all the way to prototyping the core helpers of a future
open-source R package (`arsbridge`) that bridges annotated TLF shells and the
formal ARS model.

Every chapter follows a consistent three-step teaching pattern:

1. **Annotated shell**: the TLF shell as a lead programmer writes it today,
   with `DATASET.VARIABLE='VALUE'` filter annotations in the industry-standard
   style (dataset/variable name in red next to each row label, population
   filter in the subtitle, grouping variable in the column annotation)
2. **ARM-TS JSON encoding**: the same information in machine-readable ARS form
3. **Live R exercise**: complete the code, graded by `{gradethis}`

Each chapter also includes knowledge-check quizzes (multiple choice, graded,
retryable) covering all section concepts.

---

## Who This Is For

- **Clinical R and SAS programmers** who write or QC annotated TLF shells and
  want to understand how their existing workflow maps to CDISC ARS
- **Lead programmers and statisticians** preparing for ARS-conformant
  submissions (FDA Dataset-JSON, R Consortium Pilot 4+, CDISC 360i)
- **Pharmaverse contributors** interested in the open-source ARM-TS gap and
  how `{cards}`, `{cardx}`, `{gtsummary}`, and `{datasetjson}` fit together
- **R package authors** thinking about building tooling on top of the ARS v1.0
  specification

---

## Chapter Overview

### Chapter 1: Why ARS Exists (`ars_tutorial_ch1.Rmd`)

**Concepts covered**

- The five chronic failures ARS was built to address: static outputs,
  non-reusable results, no machine-readable intent-to-execution link,
  sponsor variation, and limited regulatory utility
- Historical context: ARM v1.0 and Define-XML, what they solved, where they stopped
- **ARS, ARM-TS, and ARD**: the three terms, how they nest, how they differ:
  - *ARS file*: one `ReportingEvent` (the whole standard in one JSON document)
  - *ARM-TS* (Analysis Results Metadata Technical Specification): the plan layer
    covering populations, methods, analyses, and outputs
  - *ARD* (Analysis Results Dataset): the results layer nested inside
    `Analysis.results` as `OperationResult` objects
- **Color-coded JSON walkthrough**: a minimal mean-age table rendered
  as blue (ARM-TS) and orange (ARD) sections in a single `ReportingEvent`
- Regulatory signals: R Consortium Pilot 4, FDA RFI, CDISC 360i
- The open-source ARM-TS gap and where `arsbridge` will sit

**Exercises**

| Exercise | What you do |
|----------|-------------|
| 1.1 | Count distinct treatment arms (`TRT01A`) in the Safety population, which maps to `GroupingFactor.groups` |
| 1.2 | Count subjects with at least one TEAE by arm, producing the three `OperationResult.rawValue`s for one analysis row |
| 1.3 | Read the reporting event name from a parsed ARM-TS JSON |

---

### Chapter 2: The ARS Data Model (`ars_tutorial_ch2.Rmd`)

**Concepts covered**

- The `ReportingEvent` as the single root object
- Complete object hierarchy: AnalysisSet, DataSubset, AnalysisGrouping,
  AnalysisMethod, Analysis, Output, OperationResult
- **AnalysisSet vs DataSubset** (the most-tested distinction):
  AnalysisSet is a subject-level population filter (ADSL-based);
  DataSubset is a data-record-level filter (BDS-based)
- **WhereClause system**: simple condition, compound expression
  (`AND`/`OR`/`NOT`), referenced clause
- Comparator-to-dplyr mapping: `EQ` to `==`, `GE` to `>=`, `IN` to `%in%`, etc.
- Four extensible enumerations: `AnalysisReasonEnum`, `AnalysisPurposeEnum`,
  `OperationRoleEnum`, `OutputFileTypeEnum`
- **Design principles**: Reuse-over-repetition (define once, reference by ID);
  separation of specification from results; ordered everything; extensibility
- **Define once, reference everywhere**: explicit JSON showing one `AS001`
  referenced from 50 analyses, each carrying only `"analysisSetId": "AS001"`

**Exercises**

| Exercise | What you do |
|----------|-------------|
| 2.1 | Parse and explore the sample ARM-TS (`re_json$name`, `length(re_json$analyses)`, `re_json$analysisSets[[1]]$id`) |
| 2.2 | Translate the `AS002` WhereClause (`ADSL.SAFFL EQ 'Y'`) into a `dplyr::filter()` and count subjects |
| 2.3 | Translate a compound expression (ITT AND AGE >= 18) into a two-condition `filter()` |
| 2.4 | Map six annotated-shell phrases to their ARS object classes (AnalysisSet, DataSubset, etc.) |
| 2.5 | Walk all fields of the first `Analysis` object: dataset, variable, analysisSetId, methodId, reason, purpose |
| 2.6 | Pull a single `OperationResult` (mean age, Xanomeline High Dose) and read rawValue plus formattedValue |

---

### Chapter 3: ARM-TS Deep Dive (`ars_tutorial_ch3.Rmd`)

**Concepts covered**

- Every major ARM-TS class with full field tables:
  AnalysisSet, DataSubset, GroupingFactor, Group, AnalysisMethod, Operation,
  Analysis, Output, OutputDisplay
- **Annotated-shell to ARM-TS field mapping** (six-row table, one annotation
  element per ARS field)
- `AnalysisProgrammingCodeTemplate`, which is the ARS version of a parameterized macro
- **Object ID conventions**: industry-standard prefix table
  (`AS`, `DS`, `GF`, `G`, `M`, `O`, `AN`, `OUT`, `DISP`, ...);
  Style A (sequential `AS001`) vs Style B (descriptive `AS_SAFETY`)
- **`name`, `label`, `description`**: three text fields and when to use each
- **JSON field syntax**: camelCase, `*Id` vs `*Ids`, plural collections,
  mutual-exclusion slot pairs (`condition` OR `compoundExpression`)
- **`resultPattern` grammar**: X's after the decimal point equal the number
  of decimal places (`"XXX.X"` gives 1 dp; `"XXX.XX"` gives 2 dp)
- Controlled terminology (closed vs extensible enumerations);
  `TerminologyExtension` pattern for sponsor terms

**Exercises**

| Exercise | What you do |
|----------|-------------|
| 3.1 | Extract `AS002`, reconstruct `"ADSL.SAFFL EQ 'Y'"` with `glue()`, the core of `ars_to_shell()` |
| 3.2 | Build `AnalysisMethod M001` (six operations: n, Mean, SD, Median, Min, Max) as an R list |
| 3.3 | Build a `Group` for "Xanomeline High Dose" with its `ADSL.TRT01A EQ '...'` WhereClause |
| 3.4 | Capstone: translate a full annotated-shell annotation row into a complete `Analysis` R list |
| 3.5 | Write a prefix-convention validator with `sapply()` + `startsWith()` |
| 3.6 | Resolve an `analysisSetId` reference: index `analysisSets` by ID and look up `AN001$analysisSetId` |

---

### Chapter 4: ARD Deep Dive (`ars_tutorial_ch4.Rmd`)

**Concepts covered**

- `OperationResult` anatomy: `operationId`, `resultGroups`, `rawValue`,
  `formattedValue`
- **Formal ARS ARD** (nested in `Analysis.results`) vs
  **flat ARD data frame** (the `{cards}` format)
- Field-by-field flat-ARD to formal-ARD mapping:
  `group1_level` maps to `groupId`, `stat_name` maps to `operationId`, `stat` maps to `rawValue`
- `{cards}` API: `ard_continuous()`, `ard_categorical()`,
  `ard_dichotomous()`, `ard_stack()`
- `{cardx}` extension: `ard_survival_survfit()` for Kaplan-Meier estimates
- **Why both rawValue and formattedValue**: precision for validators,
  display-ready string for renderers
- **What the ARD cannot tell you alone**: population, data subset, method,
  SAP reference, and display context all require the ARM-TS

**Exercises**

| Exercise | What you do |
|----------|-------------|
| 4.1 | Generate a continuous ARD (`ard_continuous`) for AGE by TRT01A, predicting 18 rows (6 stats x 3 arms) |
| 4.2 | Filter the flat ARD to the mean for Xanomeline High Dose with `filter()` + `pull(stat)` |
| 4.3 | Generate a dichotomous ARD (`ard_dichotomous`) for any-TEAE; pull the percentage for one arm |
| 4.4 | Generate a KM ARD (`cardx::ard_survival_survfit`) at months 6/12/18/24 for the ITT population |

---

### Chapter 5: The Traceability Chain (`ars_tutorial_ch5.Rmd`)

**Concepts covered**

- The six-link traceability chain: SAP > ARM-TS > ADaM > R code > ARD > Display
- Where the chain is weakest in industry today (the SAP-to-ARM-TS gap)
- Six `validate_ard()` checks:
  1. Coverage: every ARM-TS analysis has ARD rows
  2. Re-derivation: re-applying the ARM-TS spec to ADaM matches stored rawValue
  3. Population consistency: ARD computed against the right AnalysisSet
  4. Group completeness: ARD has one row per expected group combination
  5. Format consistency: `formattedValue` matches `rawValue` under `resultPattern`
  6. Operation completeness: all operations in the Method have result rows
- Population traceability break (the most dangerous silent bug): a result
  computed against the wrong population still looks plausible
- Shell decomposition: one annotated-shell row decomposes into six ARM-TS objects

**Exercises**

| Exercise | What you do |
|----------|-------------|
| 5.1 | Re-derive mean AGE from ADSL (Safety pop, by TRT01A) and compare to stored `formattedValue` (Check #2 by hand) |
| 5.2 | Introduce a deliberate population break (ITT instead of Safety) and quantify the numerical difference |
| 5.3 | Prototype `check_format()`: `sprintf("%.Nf", as.numeric(rawValue)) == formattedValue` (Check #5) |
| 5.4 | Capstone: decompose a full shell row into six ARS objects using a `tribble` mapping exercise |

---

### Chapter 6: R Ecosystem and Tools (`ars_tutorial_ch6.Rmd`)

**Concepts covered**

- The coverage picture: `{cards}` / `{cardx}` cover the ARD layer; `{gtsummary}` / `{rtables}` cover the display layer;
  `{datasetjson}` covers exchange; the ARM-TS layer is uncovered (the `arsbridge` gap)
- `{cards}` deep-dive: `ard_continuous()`, `ard_categorical()`,
  `ard_dichotomous()`, `ard_stack()`
- `{gtsummary}` integration: `tbl_ard_summary()`, `modify_caption()`
- `{datasetjson}`: Dataset-JSON exchange format used in FDA R Consortium Pilot 4
- `siera` (TransCelerate, commercial): what exists and why an open-source
  equivalent is still missing
- **The gap exercise**: manually applying an `AS002` WhereClause to `adsl`
  with `.data[[cond$variable]]`. This mechanical step is what `parse_ars()` will automate

**Exercises**

| Exercise | What you do |
|----------|-------------|
| 6.1 | Build a multi-variable ARD with `ard_stack()` (AGE continuous + SEX categorical) |
| 6.2 | Render the ARD as a `tbl_ard_summary()` demographics table with a caption |
| 6.3 | Fill the tool-coverage `tribble` from memory: which package covers each ARS capability (or "MISSING / arsbridge") |
| 6.4 | Manually apply the ARM-TS `AS002` WhereClause to `adsl` using `.data[[cond$variable]]` (the gap exercise) |

---

### Chapter 7: Package Design Roadmap for arsbridge (`ars_tutorial_ch7.Rmd`)

**Concepts covered**

- `arsbridge` v0.1 concept: bidirectional bridge between annotated TLF shells
  and ARS ARM-TS, plus ARD traceability validation
- Five v0.1 functions:

| Function | Direction | Input | Output |
|----------|-----------|-------|--------|
| `parse_ars()` | Foundation | ARM-TS JSON path | ID-indexed R list (S3 class `ars_reporting_event`) |
| `ars_to_shell()` | ARM-TS to Shell | ARS R list + output ID | Excel annotated shell |
| `shell_to_ars()` | Shell to ARM-TS | Excel annotated shell | ARM-TS JSON |
| `validate_ard()` | Validate | ARS R list + ARD data frame | Validation report |
| `ars_summary()` | Explore | ARS R list | Console summary |

- **`parse_ars()` internals**: `index_by_id()` builds ID-indexed lists for O(1)
  lookups; every object collection is indexed by its `id` field
- **`where_clause_to_text()`**: internal helper shared by `ars_to_shell()` and
  `ars_summary()`; reconstructs `"ADSL.SAFFL EQ 'Y'"` from a condition object
- **`validate_ard()` checks 1 through 6** (same six as Chapter 5)
- **Package infrastructure**: dependencies (`jsonlite`, `openxlsx2`, `dplyr`,
  `glue`, `cli`, `rlang`); file structure; v0.1 scope decisions
- **Build sequence**: schema_objects > parse_ars > ars_summary >
  where_clause helpers > ars_to_shell > validate_ard > shell_to_ars
- **GitHub and LinkedIn launch strategy**: three-post series timed to
  functional milestones

**Exercises**

| Exercise | What you do |
|----------|-------------|
| 7.1 | Prototype `where_clause_to_text()`: reconstruct `"ADSL.SAFFL EQ 'Y'"` from a condition R list |
| 7.2 | Prototype `index_by_id()`: build the ID-indexed list pattern at the heart of `parse_ars()` |
| 7.3 | Prototype the Populations section of `ars_summary()`, printing one console line per AnalysisSet |
| 7.4 | Prototype `validate_ard()` Check #1 (Coverage): `%in%` test to confirm every ARM-TS analysis ID appears in the ARD |
| 7.5 | Capstone: build the `arsbridge_map` `tribble` linking each function to its pipeline step and dependencies |

---

## Quick Start

### 1. Install the R dependencies via renv

This project uses `renv` for reproducible package management. To restore the
exact package versions used during development:

```r
install.packages("renv")
renv::restore()
```

Or install manually:

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
  "glue",
  "tibble"
))
```

If `pharmaverseadam` or `pharmaversesdtm` are not on CRAN in your region:

```r
remotes::install_github("pharmaverse/pharmaverseadam")
remotes::install_github("pharmaverse/pharmaversesdtm")
```

### 2. Run a chapter

In R:

```r
rmarkdown::run("ars_tutorial_ch1.Rmd")
```

Or in RStudio: open any `ars_tutorial_ch*.Rmd` and click **Run Document**.

Each chapter opens in your browser as a self-contained interactive tutorial
with a green-accented left navigation, live code editors, hints, solutions,
and quizzes.

---

## Repository Structure

```
ars-learnr-tutorial/
├── ars_tutorial_ch1.Rmd        Chapter 1: Why ARS Exists
├── ars_tutorial_ch2.Rmd        Chapter 2: The ARS Data Model
├── ars_tutorial_ch3.Rmd        Chapter 3: ARM-TS Deep Dive
├── ars_tutorial_ch4.Rmd        Chapter 4: ARD Deep Dive
├── ars_tutorial_ch5.Rmd        Chapter 5: The Traceability Chain
├── ars_tutorial_ch6.Rmd        Chapter 6: R Ecosystem and Tools
├── ars_tutorial_ch7.Rmd        Chapter 7: arsbridge Package Design
│
├── data/
│   └── reporting_event.json    Sample ARM-TS (CDISC-Pilot-style)
│
├── www/
│   └── custom.css              White background, light-green accents
│
├── materials/                  Chapter source narratives (one .md per chapter)
│   ├── 00_README.md
│   ├── 01_Why_ARS_Exists.md
│   ├── 02_ARS_Data_Model.md
│   ├── 03_ARM_TS_Deep_Dive.md
│   ├── 04_ARD_Deep_Dive.md
│   ├── 05_Traceability_Chain.md
│   ├── 06_R_Ecosystem_and_Tools.md
│   └── 07_Package_Design_Roadmap.md
│
├── renv/                       renv infrastructure (do not edit manually)
├── renv.lock                   Exact package versions (R 4.6.0)
├── .gitignore
└── README.md
```

Rendered `*.html` files are excluded from version control (see `.gitignore`).
Re-render any chapter locally with `rmarkdown::run()`.

---

## The Sample Data

- **ADaM datasets** come from `{pharmaverseadam}`, the same data shape used
  in the public CDISC Pilot submission. `ADSL` carries `SAFFL`, `TRT01A`,
  `AGE`, and `SEX`; `ADAE` carries `TRTEMFL` and `AEDECOD`; `ADTTE` (via
  `adtte_onco`) carries `PARAMCD`, `AVAL`, and `CNSR`.
  Note: `pharmaverseadam` ADSL does not ship `ITTFL`; the tutorials derive it
  from `ARM != ""` in the setup chunk.
- **`data/reporting_event.json`** is a minimal but complete `ReportingEvent`
  with one `Analysis` (age summary by treatment arm, Safety population),
  two `AnalysisSets` (ITT = AS001, Safety = AS002), one `GroupingFactor`
  (Treatment Arm = GF001 with three Groups), one `AnalysisMethod` M001
  (n, Mean, SD, Median, Min, Max with six Operations), and six stored
  `OperationResult` rows (one per arm per statistic subset). It is the
  running case study across all seven chapters.

---

## Annotation Style

All "Step 1: the annotated shell" blocks in the exercises use the
lead programmer TLF shell annotation convention:

- **Subtitle**: population filter in red, e.g. `ADSL.SAFFL='Y'`
- **Row labels**: analysis description with `DATASET.VARIABLE='VALUE'`
  annotation in red, placed inline next to the row text
- **Column headers**: arm name with the grouping variable annotated
- **Footer**: grouping variable, format pattern (`resultPattern`), SAP reference

This mirrors the annotation style used on regulatory submission shells and
makes the shell-to-ARM-TS translation visible in both directions.

---

## Custom Theme

The left navigation uses a clean white background with light-green text
accents (Inter / Lato sans-serif). The theme is defined in
[`www/custom.css`](www/custom.css) and is referenced from every chapter's
YAML header (`css: www/custom.css`).

---

## Roadmap: the arsbridge Package

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

- **ARS v1.0 Specification**: https://cdisc-org.github.io/analysis-results-standard/
- **ARS GitHub (model YAML, examples)**: https://github.com/cdisc-org/analysis-results-standard
- **CDISC Pilot Study data**: https://github.com/cdisc-org/sdtm-adam-pilot-project
- **`{cards}`**: https://insightsengineering.github.io/cards/
- **`{cardx}`**: https://insightsengineering.github.io/cardx/
- **`{gtsummary}`**: https://www.danieldsjoberg.com/gtsummary/
- **`{datasetjson}`**: https://atorus-research.github.io/datasetjson/
- **`{learnr}`**: https://rstudio.github.io/learnr/
- **pharmaverse**: https://pharmaverse.org

---

## Author

**Hamid Tavakoli, MD, MSc**
Physician, Data Scientist, Senior Clinical Statistical Programmer
GitHub: [@tavakohr](https://github.com/tavakohr)

---

## License

This tutorial (narrative content, exercises, and code) is released under
the **MIT License**. The pharmaverse datasets retain their original licenses
(MIT / Apache 2.0). The CDISC ARS specification itself is the property of
CDISC and is referenced here under fair-use educational principles.

---

## Disclaimer

This material represents independent educational work product. It contains no
proprietary items, confidential materials, or intellectual property belonging
to any past, current, or specific organization or corporate entity. All
mappings, standards, and logic used herein are derived strictly from public
CDISC documentation, open-source pharmaverse packages, and simulated or
publicly available pilot data.
