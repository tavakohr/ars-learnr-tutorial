# Chapter 7 — Package Design Roadmap: arsbridge

## 7.1 Package Concept

`arsbridge` is an R package with a single clear purpose:

> **Bridge the annotated shell world and the ARS world — bidirectionally — and validate traceability between ARM-TS and ARD.**

It serves two audiences:
1. **Practitioners with annotated shells** who want to adopt ARS without starting from scratch
2. **ARS adopters** who want a human-readable view of their ARM-TS files and a validator for their pipeline

---

## 7.2 Core Functions (v0.1 Scope)

Five functions for v0.1:

| Function | Direction | Input | Output |
|----------|-----------|-------|--------|
| `parse_ars()` | — | ARM-TS JSON file path | R list (ARS object tree) |
| `ars_to_shell()` | ARM-TS → Shell | ARS R list + output ID | Excel annotated shell |
| `shell_to_ars()` | Shell → ARM-TS | Excel annotated shell | ARM-TS JSON file |
| `validate_ard()` | Validate | ARS R list + ARD data frame | Validation report |
| `ars_summary()` | Explore | ARS R list | Console summary of the reporting event |

This is a complete, coherent v0.1. Each function is independently useful. Together they cover the full bridge concept.

---

## 7.3 Function 1: parse_ars()

### Purpose
Read an ARM-TS JSON file and return a structured R list with named elements corresponding to ARS objects.

### Signature
```r
parse_ars(
  file,           # Path to ARM-TS JSON file
  validate = TRUE # Whether to validate against ARS schema
)
```

### Returns
An S3 object of class `"ars_reporting_event"` — a named R list with elements:
- `$id`, `$name`, `$version`
- `$reference_documents` — list of ReferenceDocument objects
- `$analysis_sets` — named list of AnalysisSet objects, indexed by ID
- `$data_subsets` — named list of DataSubset objects
- `$groupings` — named list of GroupingFactor objects
- `$methods` — named list of AnalysisMethod objects
- `$analyses` — named list of Analysis objects
- `$outputs` — named list of Output objects

### Implementation Notes
- Use `{jsonlite}` for JSON parsing
- Validate required fields against the ARS v1.0 schema
- Convert WhereClause conditions to a standardized R structure for easy filter generation
- Index all lists by object ID for fast lookup

### Example Usage
```r
re <- parse_ars("reporting_event.json")

# Access objects by ID
re$analysis_sets[["AS002"]]
re$analyses[["AN001"]]
re$methods[["M002"]]
```

---

## 7.4 Function 2: ars_to_shell()

### Purpose
Generate a human-readable annotated shell in Excel format from an ARM-TS object, for a specified output or for all outputs.

### Signature
```r
ars_to_shell(
  re,               # ARS reporting event (from parse_ars())
  output_id = NULL, # If NULL, generate shells for all outputs
  file = "annotated_shell.xlsx",
  style = c("standard", "cdisc_pilot")
)
```

### Output Excel Structure
One worksheet per output, with columns:

| Column | Content | ARM-TS Source |
|--------|---------|---------------|
| Table Number | Output identifier | `Output.id` |
| Table Title | Display title | `OutputDisplay.displayTitle` |
| Row Label | Row description | Derived from Analysis.name |
| Dataset | Analysis dataset | `Analysis.dataset` |
| Variable | Analysis variable | `Analysis.variable` |
| Population | Population name | `AnalysisSet.name` |
| Population Filter | WHERE clause text | Generated from `AnalysisSet.condition` |
| Data Filter | Additional data filter | Generated from `DataSubset.condition` |
| Grouping 1 | First grouping factor | `GroupingFactor.name` |
| Grouping 2 | Second grouping factor (if any) | `GroupingFactor.name` |
| Method | Statistical method | `AnalysisMethod.name` |
| Operations | Statistics computed | `[Operation.name]` joined |
| Format | Display format | `Operation.resultPattern` |
| SAP Reference | SAP section | Generated from `DocumentReference + PageRef` |
| Program | Code file | `programmingCode.documentRef` |
| Reason | Pre-specified / data driven | `Analysis.reason` |
| Purpose | Primary / Secondary | `Analysis.purpose` |

### WhereClause to Text Conversion
A key internal function: convert a `WhereClause` object to a human-readable filter string.

```r
# Internal helper
where_clause_to_text <- function(wc) {
  if (!is.null(wc$condition)) {
    cond <- wc$condition
    val_str <- paste0("'", cond$value, "'", collapse = ", ")
    glue::glue("{cond$dataset}.{cond$variable} {cond$comparator} {val_str}")
  } else if (!is.null(wc$compoundExpression)) {
    # Recursively process compound expressions
    op <- wc$compoundExpression$logicalOperator
    clauses <- sapply(wc$compoundExpression$whereClauses, where_clause_to_text)
    if (op == "NOT") {
      glue::glue("NOT ({clauses[1]})")
    } else {
      paste(clauses, collapse = glue::glue(" {op} "))
    }
  }
}
```

---

## 7.5 Function 3: shell_to_ars()

### Purpose
Read a structured annotated shell Excel file and generate an ARM-TS JSON file.

### Signature
```r
shell_to_ars(
  file,               # Path to Excel annotated shell
  study_id,           # ReportingEvent ID
  study_name,         # ReportingEvent name
  sap_file = NULL,    # Path to SAP PDF (for ReferenceDocument)
  output_file = "reporting_event.json",
  template = c("arsbridge_standard", "custom"),
  col_mapping = NULL  # For custom templates: named vector mapping columns to fields
)
```

### Required Excel Template Structure
The input Excel must follow the `arsbridge_standard` template (or a custom mapping). The standard template has columns matching the ARM-TS field names documented in section 7.4 above.

Users who have existing annotated shell formats can provide `col_mapping` to map their columns to the expected fields:

```r
shell_to_ars(
  file = "my_shells.xlsx",
  study_id = "RE001",
  study_name = "Study XYZ Final CSR",
  col_mapping = c(
    table_number   = "TBL_NUM",
    table_title    = "TITLE",
    population     = "POPN",
    pop_filter     = "WHERE_CLAUSE",
    dataset        = "DATASET",
    variable       = "VARIABLE",
    method         = "STAT_METHOD"
  )
)
```

### Text to WhereClause Conversion
The inverse of `where_clause_to_text()` — parse text like `"ADSL.SAFFL EQ 'Y'"` into a `WhereClauseCondition` structure. This is the hardest part of the function to implement robustly.

```r
# Internal helper - parse annotation text to WhereClause
text_to_where_clause <- function(text) {
  # Simple case: "DATASET.VARIABLE COMPARATOR 'VALUE'"
  # Pattern match and build condition structure
  pattern <- "^(\\w+)\\.(\\w+)\\s+(EQ|NE|GT|GE|LT|LE|IN|NOTIN)\\s+'(.+)'$"
  m <- regmatches(text, regexpr(pattern, text, perl = TRUE))
  # ... build condition from matches
}
```

For v0.1, support simple single-condition WHERE clauses. Complex compound expressions can be added in v0.2.

---

## 7.6 Function 4: validate_ard()

### Purpose
Validate that an ARD data frame is consistent with the ARM-TS specification.

### Signature
```r
validate_ard(
  re,              # ARS reporting event (from parse_ars())
  ard,             # ARD data frame (from {cards})
  analysis_id,     # Which analysis to validate (or NULL for all)
  adam_data = NULL # Optional: ADaM datasets for re-computation check
)
```

### Validation Checks

**Check 1: Coverage** — Does every Analysis in ARM-TS have results in the ARD?
```r
# For each analysis in re$analyses:
#   - find matching rows in ard by analysis context
#   - flag analyses with no ARD rows
```

**Check 2: Group completeness** — For each grouping factor with `resultsByGroup=TRUE`, are all expected groups present in the ARD?
```r
# For each Analysis with orderedGroupings:
#   - enumerate all expected group combinations
#   - verify each combination appears in ard
```

**Check 3: Denominator consistency** — For percentage operations with a DENOMINATOR relationship, does the referenced denominator result exist?
```r
# For each Operation with ReferencedOperationRelationship (role = DENOMINATOR):
#   - locate the referenced operation's result in the ARD
#   - verify it exists and is numeric
```

**Check 4: Format consistency** — Does formattedValue match rawValue + resultPattern?
```r
# For each OperationResult:
#   - apply resultPattern to rawValue
#   - compare to formattedValue
#   - flag discrepancies
```

**Check 5 (if adam_data provided): Re-computation** — Apply ARM-TS specification to ADaM and compare to stored results.
```r
# For each Analysis:
#   - apply AnalysisSet filter to adam_data
#   - apply DataSubset filter if present
#   - compute statistics per AnalysisMethod
#   - compare to stored OperationResult.rawValue
```

### Returns
A structured validation report (data frame + summary):

```r
# validate_ard() output:
# $summary
#   analysis_count: 45
#   analyses_with_results: 43
#   analyses_missing_results: 2
#   format_discrepancies: 1
#   group_completeness_issues: 0
#
# $details (data frame)
#   analysis_id  check_type         status   message
#   AN001        coverage           PASS
#   AN002        coverage           PASS
#   AN003        coverage           FAIL     No ARD rows found
#   AN001        format             FAIL     O008/G001: expected '84.4', got '84.44'
#   ...
```

---

## 7.7 Function 5: ars_summary()

### Purpose
Print a human-readable summary of a `ReportingEvent` object — useful for exploring an unfamiliar ARS file.

### Example Output
```
── ARS Reporting Event ────────────────────────────────────
ID:      RE001
Name:    Study XYZ-001 Final CSR
Version: 1

── Populations (AnalysisSets) ──────────────────────────
  AS001  Intent-to-Treat Population    ADSL.ITTFL EQ 'Y'
  AS002  Safety Population             ADSL.SAFFL EQ 'Y'
  AS003  Per-Protocol Population       ADSL.PPSFL EQ 'Y' AND ADSL.COMPLFL EQ 'Y'

── Data Subsets ────────────────────────────────────────
  DS001  Overall Survival Parameter    ADTTE.PARAMCD EQ 'OS'
  DS002  Week 24 Visit                 ADLB.AVISIT EQ 'Week 24'

── Grouping Factors ────────────────────────────────────
  GF001  Treatment Arm                 TRT01A (2 groups)
  GF002  Analysis Visit                AVISIT (data-driven)

── Methods ─────────────────────────────────────────────
  M001  Summary Statistics - Continuous  6 operations
  M002  Count and Percentage             3 operations
  M003  KM Analysis                      4 operations

── Analyses ────────────────────────────────────────────
  45 analyses defined
  38 analyses have stored results (ARD)
   7 analyses have no stored results

── Outputs ─────────────────────────────────────────────
  12 outputs defined
```

---

## 7.8 Package Infrastructure

### Dependencies
```
Imports:
  jsonlite      # JSON read/write
  openxlsx2     # Excel read/write (modern replacement for openxlsx)
  dplyr         # Data manipulation
  glue          # String interpolation
  cli           # Console output formatting
  rlang         # Error handling
  
Suggests:
  cards         # For ARD generation in examples
  cardx         # Extended ARD
  haven         # SAS dataset reading in vignettes
  testthat      # Testing
  knitr         # Vignette building
```

### File Structure
```
arsbridge/
├── R/
│   ├── parse_ars.R         # parse_ars()
│   ├── ars_to_shell.R      # ars_to_shell()
│   ├── shell_to_ars.R      # shell_to_ars()
│   ├── validate_ard.R      # validate_ard()
│   ├── ars_summary.R       # ars_summary() + print method
│   ├── where_clause.R      # Internal: WhereClause helpers
│   ├── schema_objects.R    # Internal: R representations of ARS objects
│   └── utils.R             # Internal utilities
├── inst/
│   ├── extdata/
│   │   ├── ars_schema/     # ARS v1.0 JSON Schema for validation
│   │   └── templates/      # Shell Excel templates
│   └── examples/
│       └── cdisc_pilot/    # CDISC pilot study example files
├── vignettes/
│   ├── getting_started.Rmd
│   ├── shell_to_ars_workflow.Rmd
│   └── validating_ard.Rmd
├── tests/
│   └── testthat/
└── data/                   # Small example ARS and ARD objects for testing
```

---

## 7.9 Build Sequence (v0.1)

Recommended order to avoid rework:

1. **Schema objects** (`schema_objects.R`) — define the R data structures that mirror ARS model classes
2. **parse_ars()** — once you can parse, everything else builds on it
3. **ars_summary()** — quick win to verify parsing works, useful for debugging
4. **where_clause.R helpers** — needed by both shell functions and validate_ard
5. **ars_to_shell()** — tests your understanding of object navigation
6. **validate_ard()** — Checks 1-4 only (no re-computation yet)
7. **shell_to_ars()** — hardest function; build after shell template is established
8. **Vignette: CDISC pilot** — walk through parse → summary → ars_to_shell → validate_ard on the public CDISC pilot study data

---

## 7.10 GitHub and LinkedIn Strategy

**GitHub repo name:** `arsbridge`  
**GitHub description:** *"R package for bidirectional translation between annotated TLF shells and CDISC ARS ARM-TS, with ARD traceability validation"*

**LinkedIn launch posts (3-part series):**

Post 1 (when repo is created with README): *"The clinical programming community spent 20 years annotating TLF shells in Word files. CDISC ARS is the machine-readable version of exactly that. I'm building the R package that bridges them."*

Post 2 (when parse_ars + ars_to_shell are working): *"You can now take any ARS ARM-TS JSON file and render it as a human-readable annotated Excel shell in 3 lines of R. Here's a demo using the CDISC pilot study data."*

Post 3 (when validate_ard is working): *"arsbridge v0.1 is on GitHub: parse ARM-TS, generate annotated shells, validate ARD traceability. First open-source R tool that closes the loop between analysis specification and results. Feedback welcome."*

---

## Chapter 7 Summary

You now have a complete design for v0.1 of `arsbridge`:
- 5 clearly scoped functions with defined inputs, outputs, and internal logic
- Package infrastructure and dependency choices
- A build sequence that minimizes rework
- A GitHub and LinkedIn content strategy tied to development milestones

The training curriculum is complete. You have everything you need to begin.

---

## Appendix: Key Resources

| Resource | URL |
|----------|-----|
| ARS v1.0 Specification | https://cdisc-org.github.io/analysis-results-standard/ |
| ARS GitHub (model YAML, examples) | https://github.com/cdisc-org/analysis-results-standard |
| CDISC Pilot Study data | https://github.com/cdisc-org/sdtm-adam-pilot-project |
| cards package | https://insightsengineering.github.io/cards/ |
| cardx package | https://insightsengineering.github.io/cardx/ |
| gtsummary package | https://www.danieldsjoberg.com/gtsummary/ |
| datasetjson package | https://atorus-research.github.io/datasetjson/ |
| CDISC 360i | https://www.cdisc.org/cdisc-360i |
| pharmaverse | https://pharmaverse.org |
| ARS User Guide v1.0 | https://wiki.cdisc.org/display/ARSP/Analysis+Results+Standard+User+Guide+v1.0 |
