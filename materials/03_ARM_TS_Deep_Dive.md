# Chapter 3 — ARM-TS Deep Dive

This chapter walks through every major ARM-TS object with full JSON examples. Each section includes the equivalent annotated shell annotation so you can see exactly how your existing knowledge maps to the formal model.

The examples use a running case study: **a safety table showing adverse event summary statistics by treatment arm in the ITT population**, which is a common table type you will have programmed many times.

---

## 3.1 ReportingEvent

The root container. Represents one reporting deliverable — typically one CSR or one interim analysis.

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | Unique identifier for this reporting event |
| `version` | integer | No | Version number (increment on updates) |
| `name` | string | Yes | Human-readable name |
| `description` | string | No | Free-text description |
| `label` | string | No | Short display label |
| `mainListOfContents` | ListOfContents | Yes | The table of contents |
| `referenceDocuments` | [ReferenceDocument] | No | External documents (SAP, programs) |
| `analysisSets` | [AnalysisSet] | No | All population definitions |
| `dataSubsets` | [DataSubset] | No | All data filter definitions |
| `analysisGroupings` | [GroupingFactor] | No | All grouping factor definitions |
| `methods` | [AnalysisMethod] | No | All statistical method definitions |
| `analyses` | [Analysis] | No | All analysis definitions |
| `outputs` | [Output] | No | All output/display definitions |

### JSON Example

```json
{
  "id": "RE001",
  "version": 1,
  "name": "Study XYZ-001 Final CSR",
  "description": "Analyses and outputs for the final Clinical Study Report of Study XYZ-001",
  "label": "XYZ-001 Final CSR",
  "mainListOfContents": { ... },
  "referenceDocuments": [ ... ],
  "analysisSets": [ ... ],
  "dataSubsets": [ ... ],
  "analysisGroupings": [ ... ],
  "methods": [ ... ],
  "analyses": [ ... ],
  "outputs": [ ... ]
}
```

### Annotated Shell Equivalent

The annotated shell header that typically contains: study number, protocol title, SAP version, date. The `ReportingEvent` is the machine-readable equivalent of this header block.

---

## 3.2 ReferenceDocument

Links the reporting event to external files. This is how ARS creates a formal link to the SAP.

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | Unique identifier |
| `name` | string | Yes | Human-readable name |
| `location` | URI | No | Path or URL to the document |
| `description` | string | No | Description |

### JSON Example

```json
{
  "referenceDocuments": [
    {
      "id": "SAP001",
      "name": "Statistical Analysis Plan v2.0",
      "location": "documents/XYZ001_SAP_v2.0.pdf",
      "description": "Final SAP approved 15-Jan-2025"
    },
    {
      "id": "PROG001",
      "name": "Primary Efficacy Program",
      "location": "programs/t_efficacy_primary.R"
    }
  ]
}
```

### Annotated Shell Equivalent

The "per Section X.X of SAP" text you write in each annotation. In ARM-TS, this becomes a formal `DocumentReference` (with optional page numbers) inside the `Analysis` object, pointing to the `ReferenceDocument` you define here.

---

## 3.3 AnalysisSet

Defines a subject population. Your population flags in ADSL (ITTFL, SAFFL, PPSFL) become `AnalysisSet` objects.

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | Unique identifier |
| `name` | string | Yes | Human-readable name (e.g., "Intent-to-Treat Population") |
| `description` | string | No | Free-text description |
| `condition` | WhereClauseCondition | * | Simple filter (OR use compoundExpression) |
| `compoundExpression` | CompoundSetExpression | * | Complex filter with AND/OR/NOT |

*Exactly one of `condition` or `compoundExpression` should be present.

### JSON Example — Simple (single flag)

```json
{
  "analysisSets": [
    {
      "id": "AS001",
      "name": "Intent-to-Treat Population",
      "description": "All randomized subjects",
      "condition": {
        "dataset": "ADSL",
        "variable": "ITTFL",
        "comparator": "EQ",
        "value": ["Y"]
      }
    },
    {
      "id": "AS002",
      "name": "Safety Population",
      "description": "All subjects who received at least one dose of study drug",
      "condition": {
        "dataset": "ADSL",
        "variable": "SAFFL",
        "comparator": "EQ",
        "value": ["Y"]
      }
    }
  ]
}
```

### JSON Example — Compound (multiple flags)

```json
{
  "id": "AS003",
  "name": "Per-Protocol Population",
  "compoundExpression": {
    "logicalOperator": "AND",
    "whereClauses": [
      {
        "condition": {
          "dataset": "ADSL",
          "variable": "PPSFL",
          "comparator": "EQ",
          "value": ["Y"]
        }
      },
      {
        "condition": {
          "dataset": "ADSL",
          "variable": "COMPLFL",
          "comparator": "EQ",
          "value": ["Y"]
        }
      }
    ]
  }
}
```

### Annotated Shell Equivalent

When you write *"SAFFL='Y' from ADSL"* or *"Safety Population"* in your shell annotation, you are manually encoding an `AnalysisSet`. In ARM-TS, you define it once as `AS002` and then every analysis that uses the safety population simply references `"analysisSetId": "AS002"`.

---

## 3.4 DataSubset

A filter on **data records** (rows in an analysis dataset), not on subjects. Used for things like visit-specific analyses, parameter-specific analyses (PARAMCD), or event flags.

### Key Distinction from AnalysisSet

- `AnalysisSet` = who is in the analysis (subject-level filter, usually from ADSL)
- `DataSubset` = which records to use (row-level filter on the analysis dataset itself)

### JSON Example

```json
{
  "dataSubsets": [
    {
      "id": "DS001",
      "name": "Overall Survival Parameter",
      "description": "Records for the overall survival endpoint",
      "condition": {
        "dataset": "ADTTE",
        "variable": "PARAMCD",
        "comparator": "EQ",
        "value": ["OS"]
      }
    },
    {
      "id": "DS002",
      "name": "Week 24 Visit",
      "condition": {
        "dataset": "ADLB",
        "variable": "AVISIT",
        "comparator": "EQ",
        "value": ["Week 24"]
      }
    }
  ]
}
```

### Annotated Shell Equivalent

When you write *"PARAMCD='OS'"* or *"AVISIT='Week 24'"* in an annotation, that is a `DataSubset`. The distinction matters: your population flag (ITTFL) selects subjects; your PARAMCD filter selects records within those subjects' data.

---

## 3.5 GroupingFactor and Group

Defines how to subdivide the analysis. Treatment arm, sex, age group, visit — these are all grouping factors.

### GroupingFactor Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | Unique identifier |
| `name` | string | Yes | Name of the grouping factor |
| `groupingDataset` | string | No | Dataset containing the grouping variable |
| `groupingVariable` | string | No | Variable used for grouping |
| `dataDriven` | boolean | Yes | If true, groups are derived from data values; if false, groups are pre-specified |
| `groups` | [Group] | No | Pre-specified groups (when dataDriven=false) |

### Group Fields

A `Group` has the same `WhereClause` structure as `AnalysisSet` — it defines which subjects/records belong to that group.

### JSON Example — Treatment Arm Grouping

```json
{
  "analysisGroupings": [
    {
      "id": "GF001",
      "name": "Treatment Arm",
      "groupingDataset": "ADSL",
      "groupingVariable": "TRT01A",
      "dataDriven": false,
      "groups": [
        {
          "id": "G001",
          "name": "Drug XYZ 10mg",
          "condition": {
            "dataset": "ADSL",
            "variable": "TRT01A",
            "comparator": "EQ",
            "value": ["Drug XYZ 10mg"]
          }
        },
        {
          "id": "G002",
          "name": "Placebo",
          "condition": {
            "dataset": "ADSL",
            "variable": "TRT01A",
            "comparator": "EQ",
            "value": ["Placebo"]
          }
        }
      ]
    }
  ]
}
```

### JSON Example — Data-Driven Grouping (visit)

When groups aren't prespecified but come from the data:

```json
{
  "id": "GF002",
  "name": "Analysis Visit",
  "groupingDataset": "ADLB",
  "groupingVariable": "AVISIT",
  "dataDriven": true
}
```

### Annotated Shell Equivalent

The column headers in your tables. A table with columns "Drug XYZ 10mg" and "Placebo" reflects a `GroupingFactor` with two pre-specified `Groups`. When the analysis result is stored, each `OperationResult` will have a `resultGroup` linking it to `G001` or `G002`.

---

## 3.6 AnalysisMethod

Defines one or more statistical operations that can be applied to any analysis variable. Methods are reusable.

### AnalysisMethod Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | Unique identifier |
| `name` | string | Yes | Name (e.g., "Summary Statistics - Continuous") |
| `description` | string | No | Free-text |
| `operations` | [Operation] | Yes | The individual statistical operations |
| `codeTemplate` | AnalysisProgrammingCodeTemplate | No | Reusable code template |
| `documentRefs` | [DocumentReference] | No | Links to methodology docs |

### Operation Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | Unique identifier for this operation |
| `name` | string | Yes | Name (e.g., "Mean", "Standard Deviation") |
| `order` | integer | Yes | Position within the method |
| `resultPattern` | string | No | Display format (e.g., "XX.X", "XX.XX") |
| `referencedOperationRelationships` | [...] | No | How this operation uses results from other operations |

### ReferencedOperationRelationship

Used when one operation's result depends on another — most commonly for percentage calculations where you need to reference the denominator.

| Field | Description |
|-------|-------------|
| `id` | Unique ID for this relationship |
| `referencedOperationRole` | `NUMERATOR` or `DENOMINATOR` |
| `operationId` | Which operation is being referenced |
| `analysisId` | Which analysis contains that operation's results |

### JSON Example — Summary Statistics Method

```json
{
  "methods": [
    {
      "id": "M001",
      "name": "Summary Statistics - Continuous",
      "description": "n, mean, SD, median, min, max",
      "operations": [
        { "id": "O001", "name": "n",      "order": 1, "resultPattern": "XXX"     },
        { "id": "O002", "name": "Mean",   "order": 2, "resultPattern": "XXX.X"   },
        { "id": "O003", "name": "SD",     "order": 3, "resultPattern": "XXX.XX"  },
        { "id": "O004", "name": "Median", "order": 4, "resultPattern": "XXX.X"   },
        { "id": "O005", "name": "Min",    "order": 5, "resultPattern": "XXX"     },
        { "id": "O006", "name": "Max",    "order": 6, "resultPattern": "XXX"     }
      ]
    }
  ]
}
```

### JSON Example — Count with Percentage (uses ReferencedOperationRelationship)

```json
{
  "id": "M002",
  "name": "Count and Percentage",
  "operations": [
    {
      "id": "O007",
      "name": "Count",
      "order": 1,
      "resultPattern": "XXX"
    },
    {
      "id": "O008",
      "name": "Percentage",
      "order": 2,
      "resultPattern": "XX.X",
      "referencedOperationRelationships": [
        {
          "id": "ROR001",
          "referencedOperationRole": { "controlledTerm": "DENOMINATOR" },
          "operationId": "O009",
          "analysisId": "AN_DENOM_001"
        }
      ]
    },
    {
      "id": "O009",
      "name": "Denominator",
      "order": 3,
      "resultPattern": "XXX"
    }
  ]
}
```

### Annotated Shell Equivalent

In your annotated shell, you often write something like: *"n (%), denominator = N in safety population"*. The `AnalysisMethod` encodes this formally. The `resultPattern` encodes your format string (XX.X%). The `ReferencedOperationRelationship` with `DENOMINATOR` encodes where the N comes from.

---

## 3.7 Analysis

The central object. Each `Analysis` ties everything together for one specific analysis.

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | Unique identifier |
| `name` | string | Yes | Human-readable name |
| `version` | integer | No | Version |
| `reason` | ExtensibleTerminologyTerm | Yes | When was it planned (SPECIFIED IN SAP, etc.) |
| `purpose` | ExtensibleTerminologyTerm | Yes | PRIMARY, SECONDARY, or EXPLORATORY |
| `dataset` | string | No | Analysis dataset name (e.g., "ADTTE") |
| `variable` | string | No | Analysis variable (e.g., "AVAL") |
| `analysisSetId` | string | No | References an AnalysisSet |
| `dataSubsetId` | string | No | References a DataSubset |
| `orderedGroupings` | [OrderedGroupingFactor] | No | Grouping factors with order |
| `methodId` | string | Yes | References an AnalysisMethod |
| `documentRefs` | [DocumentReference] | No | Links to SAP sections, programs |
| `programmingCode` | AnalysisOutputProgrammingCode | No | Actual code or file reference |
| `results` | [OperationResult] | No | The ARD — actual computed results |
| `categoryIds` | [string] | No | Categories for organizing analyses |

### OrderedGroupingFactor

Links a `GroupingFactor` to an analysis with an explicit order and a flag indicating whether separate results are expected per group.

| Field | Description |
|-------|-------------|
| `order` | Position of this grouping factor relative to others |
| `groupingId` | References a GroupingFactor |
| `resultsByGroup` | true = expect a result per group; false = one overall result |

### JSON Example — Complete Analysis (AE Count by Treatment)

```json
{
  "analyses": [
    {
      "id": "AN001",
      "name": "Subjects with Any TEAE by Treatment Arm",
      "version": 1,
      "reason": { "controlledTerm": "SPECIFIED IN SAP" },
      "purpose": { "controlledTerm": "PRIMARY OUTCOME MEASURE" },
      "dataset": "ADAE",
      "variable": "USUBJID",
      "analysisSetId": "AS002",
      "orderedGroupings": [
        {
          "order": 1,
          "groupingId": "GF001",
          "resultsByGroup": true
        }
      ],
      "methodId": "M002",
      "documentRefs": [
        {
          "referenceDocumentId": "SAP001",
          "pageRefs": [
            {
              "refType": "PhysicalRef",
              "firstPage": 42,
              "lastPage": 44
            }
          ]
        }
      ],
      "programmingCode": {
        "context": "R version 4.3.1",
        "documentRef": {
          "referenceDocumentId": "PROG001"
        }
      },
      "results": [ ... ]
    }
  ]
}
```

### Annotated Shell Equivalent

Your entire annotated shell cell for a specific statistic maps to one `Analysis` object:

| Your Annotation Text | ARS Field |
|---------------------|-----------|
| "USUBJID count from ADAE" | `dataset: "ADAE"`, `variable: "USUBJID"` |
| "Safety Population (SAFFL='Y')" | `analysisSetId: "AS002"` |
| "By treatment arm (TRT01A)" | `orderedGroupings: [{groupingId: "GF001", resultsByGroup: true}]` |
| "n (%)" | `methodId: "M002"` (Count and Percentage method) |
| "per Section 10.1 of SAP, pp. 42-44" | `documentRefs: [{referenceDocumentId: "SAP001", pageRefs: [...]}]` |
| "program: t_ae_summary.R" | `programmingCode.documentRef` |

---

## 3.8 Output and OutputDisplay

Defines the TFL output — its file format, displays, and display sections (title, footnotes, etc.).

### JSON Example

```json
{
  "outputs": [
    {
      "id": "OUT001",
      "name": "Table 14.3.1 - Summary of Adverse Events",
      "version": 1,
      "fileSpecifications": [
        {
          "name": "Table 14.3.1 RTF",
          "fileType": { "controlledTerm": "rtf" },
          "location": "output/t_ae_summary.rtf"
        }
      ],
      "displays": [
        {
          "order": 1,
          "display": {
            "id": "DISP001",
            "name": "Table 14.3.1",
            "version": 1,
            "displayTitle": "Table 14.3.1 Summary of Treatment-Emergent Adverse Events",
            "displaySections": [
              {
                "sectionType": "Title",
                "orderedSubSections": [
                  {
                    "order": 1,
                    "subSection": {
                      "id": "TITLE001",
                      "text": "Table 14.3.1 Summary of Treatment-Emergent Adverse Events"
                    }
                  }
                ]
              },
              {
                "sectionType": "Footnote",
                "orderedSubSections": [
                  {
                    "order": 1,
                    "subSection": {
                      "id": "FN001",
                      "text": "TEAE = Treatment-Emergent Adverse Event. Subjects counted once per preferred term."
                    }
                  }
                ]
              }
            ]
          }
        }
      ]
    }
  ]
}
```

### Annotated Shell Equivalent

The shell itself — the table number, title, footnotes, and abbreviations — maps directly to the `Output` and `OutputDisplay` objects. Your title cell = `displayTitle`. Your footnote cells = `DisplaySection` with `sectionType: "Footnote"`.

---

## 3.9 AnalysisProgrammingCodeTemplate

When a method is applied to many analyses with minor variations (e.g., different PARAMCD values), the `codeTemplate` mechanism allows one template with replacement parameters.

### JSON Example

```json
{
  "id": "M003",
  "name": "KM Analysis Template",
  "codeTemplate": {
    "context": "R version 4.3.1",
    "code": "km_fit <- survfit(Surv({{AVAR}}, {{CNSR_FLAG}}) ~ TRT01A, data = adtte %>% filter(PARAMCD == '{{PARAMCD}}' & ITTFL == 'Y'))",
    "parameters": [
      {
        "name": "AVAR",
        "description": "Analysis variable (time to event)",
        "valueSource": "analysis.variable"
      },
      {
        "name": "PARAMCD",
        "description": "Parameter code for the endpoint",
        "value": ["OS", "PFS", "DOR"]
      },
      {
        "name": "CNSR_FLAG",
        "description": "Censoring indicator variable",
        "value": ["CNSR"]
      }
    ]
  }
}
```

Individual analyses reference this template and supply their specific parameter values.

---

## Chapter 3 Summary

You have now seen every major ARM-TS object with:
- Full field definitions
- JSON examples grounded in realistic pharma scenarios
- Explicit mapping to what you already write in annotated shells

The key insight: **everything in an annotated shell has an ARM-TS equivalent**. The information is identical; the representation is machine-readable JSON vs. human-readable annotation text.

In the next chapter we cover the ARD — what goes inside `Analysis.results` when analyses are actually run.

**Next:** Chapter 4 — ARD Deep Dive
