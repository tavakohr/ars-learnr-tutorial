# Chapter 5 — The Traceability Chain

## 5.1 The Chain

ARS enables a formal, machine-navigable traceability chain:

```
Protocol / SAP
      ↓
  ARM-TS (Analysis specification)
      ↓
  ADaM datasets (Analysis data)
      ↓
  R code (Execution)
      ↓
  ARD (Computed results)
      ↓
  Output Display (Table / Figure)
```

Each link in this chain should be verifiable. The problem today is that without ARS, the chain is broken between the SAP and everything downstream — the only link is a human reading the SAP and deciding what the code should do.

---

## 5.2 Complete Worked Example

We will trace one specific analysis from SAP language through to a display cell, using real-world-style objects at each step.

**The analysis:** Primary safety endpoint — subjects with any TEAE, count and percentage by treatment arm, in the Safety Population.

---

### Step 1: The SAP

The statistical analysis plan contains, in Section 10.1:

> *"The number and percentage of subjects experiencing at least one Treatment-Emergent Adverse Event (TEAE) will be presented by treatment arm. The Safety Population (subjects who received at least one dose of study drug, defined by SAFFL='Y' in ADSL) will be used. Percentages will be calculated using the number of subjects in the Safety Population per treatment arm as the denominator. Results will be presented in Table 14.3.1."*

Today, a lead programmer reads this and writes an annotation in the table shell. With ARS, this text is formally encoded.

---

### Step 2: ARM-TS Objects Created from the SAP

**ReferenceDocument** (links to the SAP):
```json
{
  "id": "SAP001",
  "name": "Statistical Analysis Plan v2.0",
  "location": "documents/XYZ001_SAP_v2.0.pdf"
}
```

**AnalysisSet** (the Safety Population):
```json
{
  "id": "AS002",
  "name": "Safety Population",
  "description": "Subjects who received at least one dose, SAFFL=Y",
  "condition": {
    "dataset": "ADSL",
    "variable": "SAFFL",
    "comparator": "EQ",
    "value": ["Y"]
  }
}
```

**GroupingFactor** (treatment arm):
```json
{
  "id": "GF001",
  "name": "Treatment Arm",
  "groupingVariable": "TRT01A",
  "groupingDataset": "ADSL",
  "dataDriven": false,
  "groups": [
    {
      "id": "G001", "name": "Drug XYZ 10mg",
      "condition": { "dataset": "ADSL", "variable": "TRT01A", "comparator": "EQ", "value": ["Drug XYZ 10mg"] }
    },
    {
      "id": "G002", "name": "Placebo",
      "condition": { "dataset": "ADSL", "variable": "TRT01A", "comparator": "EQ", "value": ["Placebo"] }
    }
  ]
}
```

**AnalysisMethod** (count and percentage):
```json
{
  "id": "M002",
  "name": "Count and Percentage",
  "operations": [
    { "id": "O007", "name": "Count",       "order": 1, "resultPattern": "XXX"  },
    { "id": "O008", "name": "Percentage",  "order": 2, "resultPattern": "XX.X",
      "referencedOperationRelationships": [
        { "id": "ROR001", "referencedOperationRole": {"controlledTerm": "DENOMINATOR"}, "operationId": "O009", "analysisId": "AN001" }
      ]
    },
    { "id": "O009", "name": "Denominator", "order": 3, "resultPattern": "XXX"  }
  ]
}
```

**Analysis** (the full specification):
```json
{
  "id": "AN001",
  "name": "Subjects with Any TEAE - Safety Population",
  "reason": { "controlledTerm": "SPECIFIED IN SAP" },
  "purpose": { "controlledTerm": "PRIMARY OUTCOME MEASURE" },
  "dataset": "ADAE",
  "variable": "USUBJID",
  "analysisSetId": "AS002",
  "orderedGroupings": [
    { "order": 1, "groupingId": "GF001", "resultsByGroup": true }
  ],
  "methodId": "M002",
  "documentRefs": [
    {
      "referenceDocumentId": "SAP001",
      "pageRefs": [{ "refType": "PhysicalRef", "firstPage": 42, "lastPage": 44 }]
    }
  ]
}
```

**Annotated Shell Equivalent (what the lead programmer writes today):**
```
Table 14.3.1, Row: "Subjects with any TEAE"
Annotation: Count unique USUBJID from ADAE where SAFFL='Y' in ADSL (Safety Pop).
            n (%) — denominator = N subjects per TRT01A in Safety Pop.
            Per SAP Section 10.1, pp. 42-44.
```

These are the same information. One is English in a Word file. The other is JSON.

---

### Step 3: The ADaM Data

The programmer works with two datasets:

**ADSL** (one row per subject):
```
USUBJID    TRT01A         SAFFL
001-001    Drug XYZ 10mg  Y
001-002    Placebo        Y
001-003    Drug XYZ 10mg  Y
001-004    Drug XYZ 10mg  Y
001-005    Placebo        N    ← not in safety pop (no dose received)
...
```

**ADAE** (one row per adverse event):
```
USUBJID    TRT01A         TRTEMFL
001-001    Drug XYZ 10mg  Y
001-001    Drug XYZ 10mg  Y    ← same subject, 2nd AE
001-003    Drug XYZ 10mg  Y
001-002    Placebo        Y
...
```

The ARM-TS tells us:
- Use ADAE (from `Analysis.dataset`)
- Count USUBJID (from `Analysis.variable`)
- Filter subjects: ADSL.SAFFL = 'Y' (from `AnalysisSet AS002`)
- Group by TRT01A (from `GroupingFactor GF001`)

---

### Step 4: The R Code

```r
library(dplyr)
library(cards)

# Load datasets
adsl <- haven::read_sas("adsl.sas7bdat")
adae <- haven::read_sas("adae.sas7bdat")

# Apply population filter (AnalysisSet AS002: SAFFL = 'Y')
adsl_safe <- adsl %>% filter(SAFFL == "Y")

# Join to get treatment arm on AE dataset
# Get subjects with at least one TEAE (TRTEMFL = 'Y')
any_teae <- adae %>%
  filter(TRTEMFL == "Y") %>%
  distinct(USUBJID) %>%
  mutate(has_teae = 1L)

# Build analysis dataset: all safety pop subjects, flag if any TEAE
analysis_data <- adsl_safe %>%
  select(USUBJID, TRT01A) %>%
  left_join(any_teae, by = "USUBJID") %>%
  mutate(has_teae = coalesce(has_teae, 0L))

# Generate ARD using {cards}
ard_result <- ard_dichotomous(
  data = analysis_data,
  by = TRT01A,
  variables = has_teae,
  value = list(has_teae = 1L)
)

ard_result
```

The `ard_result` output is the ARD — the flat data frame with count, percentage, and denominator by treatment arm.

---

### Step 5: The ARD (Computed Results)

The ARD from the R code, mapped back to the formal ARS model:

```json
{
  "results": [
    {
      "operationId": "O009",
      "resultGroups": [{"groupingId": "GF001", "groupId": "G001"}],
      "rawValue": "45",
      "formattedValue": "45"
    },
    {
      "operationId": "O009",
      "resultGroups": [{"groupingId": "GF001", "groupId": "G002"}],
      "rawValue": "44",
      "formattedValue": "44"
    },
    {
      "operationId": "O007",
      "resultGroups": [{"groupingId": "GF001", "groupId": "G001"}],
      "rawValue": "38",
      "formattedValue": "38"
    },
    {
      "operationId": "O007",
      "resultGroups": [{"groupingId": "GF001", "groupId": "G002"}],
      "rawValue": "30",
      "formattedValue": "30"
    },
    {
      "operationId": "O008",
      "resultGroups": [{"groupingId": "GF001", "groupId": "G001"}],
      "rawValue": "84.44444",
      "formattedValue": "84.4"
    },
    {
      "operationId": "O008",
      "resultGroups": [{"groupingId": "GF001", "groupId": "G002"}],
      "rawValue": "68.18182",
      "formattedValue": "68.2"
    }
  ]
}
```

---

### Step 6: The Display

The final table cell reads: `38 (84.4%)` under the Drug XYZ 10mg column.

This value is fully traceable:
- `38` = `O007.rawValue` for `G001` (count from ARD)
- `84.4` = `O008.formattedValue` for `G001` (percentage from ARD)
- Denominator `45` = `O009.rawValue` for `G001` (from ARD)
- Population = Safety Population (`AS002`: ADSL.SAFFL = 'Y')
- Dataset = ADAE, variable = USUBJID
- Group = Drug XYZ 10mg (`G001` in `GF001`)
- SAP reference = Section 10.1, pp. 42-44 (`SAP001`)

Every number in the cell is fully navigable to its source — in machine-readable form.

---

## 5.3 Traceability Validation: What arsbridge Would Check

Given the ARM-TS and the ARD, `arsbridge` would validate:

| Check | How |
|-------|-----|
| Does every Analysis in ARM-TS have results in the ARD? | Match `analysisId` across ARM-TS analyses and ARD results |
| Does the ARD result for each group match what you'd compute from ADaM? | Re-run the specified analysis using ARM-TS parameters, compare to stored result |
| Does the population filter in the ARD match the AnalysisSet? | Apply `AnalysisSet.condition` to ADaM, count subjects, compare to ARD denominator |
| Are all group combinations in the ARD accounted for in the ARM-TS groupings? | Cross-reference `ResultGroup.groupId` against defined `Group` objects |
| Does the formatted value match rawValue + resultPattern? | Apply `resultPattern` format to `rawValue`, compare to `formattedValue` |
| Does the `documentRef` SAP page contain the analysis description? | Structural check — can be partially automated with PDF parsing |

---

## 5.4 The Annotated Shell to ARM-TS Mapping (Complete Reference)

This is the master mapping table for `arsbridge`'s `shell_to_ars()` function:

| Annotated Shell Element | ARM-TS Object | Key Fields |
|------------------------|---------------|------------|
| Table number & title | `Output.id`, `OutputDisplay.displayTitle` | `id`, `displayTitle` |
| Population note (e.g., "Safety Pop, SAFFL=Y") | `AnalysisSet` | `id`, `condition` |
| Data filter (e.g., "PARAMCD='OS'") | `DataSubset` | `id`, `condition` |
| Dataset reference (e.g., "from ADTTE") | `Analysis.dataset` | `dataset` |
| Variable reference (e.g., "AVAL") | `Analysis.variable` | `variable` |
| Column grouping (e.g., "by TRT01A") | `GroupingFactor` + `OrderedGroupingFactor` | `groupingVariable`, `groupingId` |
| Row grouping (e.g., "by AVISIT") | Second `GroupingFactor` + `OrderedGroupingFactor` | |
| Statistic description (e.g., "n, mean, SD") | `AnalysisMethod` + `[Operation]` | `methodId`, `operations` |
| Format string (e.g., "XX.X") | `Operation.resultPattern` | `resultPattern` |
| n (%) denominator note | `ReferencedOperationRelationship` with DENOMINATOR | |
| SAP section reference | `DocumentReference` + `PageRef` | `referenceDocumentId`, `pageRefs` |
| Program file reference | `programmingCode.documentRef` | |
| Pre-specified / data-driven | `Analysis.reason` | SPECIFIED IN SAP vs DATA DRIVEN |
| Primary / secondary / exploratory | `Analysis.purpose` | PRIMARY / SECONDARY / EXPLORATORY |
| Footnote text | `DisplaySection` (sectionType: Footnote) | `text` |
| Abbreviation text | `DisplaySection` (sectionType: Abbreviation) | `text` |

---

## Chapter 5 Summary

You can now trace a single cell in a clinical trial table all the way back to:
- The SAP language that specified it
- The ARM-TS objects that formally encode that specification
- The ADaM data it operates on
- The R code that computed it
- The ARD that stores the result
- The display format that renders it

This chain is what `arsbridge` will make verifiable in R. The annotated shell mapping table in section 5.4 is your primary design reference for the `shell_to_ars()` function.

**Next:** Chapter 6 — R Ecosystem and Tools
