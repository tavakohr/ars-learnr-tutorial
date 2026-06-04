# Chapter 2 — The ARS Data Model

## 2.1 Overview

The ARS data model is a **logical model** — it defines objects and their relationships, independent of any specific file format. In practice, ARS is serialized as JSON (or YAML), but the model itself is format-agnostic.

The model has a single root object: the `ReportingEvent`. Everything else hangs off it.

---

## 2.2 The Two Layers Revisited

Before diving into objects, anchor the two layers:

```
┌─────────────────────────────────────────────────────────┐
│                     ARM-TS Layer                        │
│  (What was planned and how analyses were performed)     │
│                                                         │
│  ReportingEvent                                         │
│  ├── AnalysisSets      (population filters / flags)    │
│  ├── DataSubsets       (data record filters)           │
│  ├── AnalysisGroupings (treatment, sex, visit...)      │
│  ├── Methods           (statistical operations)        │
│  ├── Analyses          (dataset + variable + method)   │
│  └── Outputs           (displays / tables)             │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                      ARD Layer                          │
│  (What was actually computed)                           │
│                                                         │
│  Lives inside Analysis.results                          │
│  OperationResult: operationId + resultGroups +          │
│                   rawValue + formattedValue             │
└─────────────────────────────────────────────────────────┘
```

The ARD is not a separate file in the formal model — it lives as the `results` slot inside each `Analysis` object. In practice, it is often extracted and stored as a separate flat dataset (a data frame) for use with tools like `{cards}`.

---

## 2.3 The Complete Object Hierarchy

Here is every class in the ARS model, organized by function:

### Root

```
ReportingEvent
```
The top-level container for everything associated with one reporting requirement (e.g., one CSR, one interim analysis). All other objects live inside or are referenced from a `ReportingEvent`.

---

### Structural / Organizational Objects

```
ReportingEvent
├── ListOfContents          — structured table of contents for analyses and outputs
│   └── NestedList
│       └── OrderedListItem — points to an Analysis or Output, with level/order
│
├── ReferenceDocument       — external file (SAP PDF, program file, etc.)
│
├── TerminologyExtension    — sponsor-defined terms extending CDISC enumerations
│   └── SponsorTerm
│
└── AnalysisOutputCategorization  — implementer-defined category system
    └── AnalysisOutputCategory    — a single category (e.g., "Safety", "Efficacy")
```

---

### Population and Data Selection Objects

These define **who** and **what data** is included in analyses. This maps directly to WHERE clauses in your annotated shells.

```
ReportingEvent
├── AnalysisSets            — subject populations (ITT, PP, Safety, etc.)
│   └── WhereClause         — the filter logic (e.g., ADSL.ITTFL EQ 'Y')
│
├── DataSubsets             — data record filters (e.g., a specific visit, PARAMCD)
│   └── WhereClause
│
└── AnalysisGroupings       — factors for subdividing (treatment arm, sex, visit)
    └── GroupingFactor
        └── Group           — one level within the factor (e.g., "Treatment A")
            └── WhereClause
```

A `WhereClause` can be either:
- A **simple condition**: `[dataset].[variable] [comparator] [value]` — e.g., `ADSL.ITTFL EQ 'Y'`
- A **compound expression**: AND / OR / NOT combination of simple conditions or referenced clauses

---

### Method Objects

These define **how** analyses are performed. One method can be reused across many analyses.

```
ReportingEvent
└── Methods
    └── AnalysisMethod       — a named set of statistical operations
        ├── Operations        — one or more statistical operations (each produces one result)
        │   └── Operation
        │       └── ReferencedOperationRelationship  — how operations relate (e.g., numerator/denominator for %)
        │
        └── AnalysisProgrammingCodeTemplate  — reusable code template with parameters
            └── TemplateCodeParameter
```

A **method** is reusable. For example, a method called "n, mean, SD, median, min, max" might have 6 operations, each producing one statistic. This method can then be referenced by any `Analysis` that needs those summary statistics.

---

### Analysis Objects

Each `Analysis` is one specific analysis in the study. It ties together: a dataset, a variable, a population, optional data filters, optional groupings, and a method.

```
ReportingEvent
└── Analyses
    └── Analysis
        ├── dataset          — e.g., "ADTTE"
        ├── variable         — e.g., "AVAL"
        ├── analysisSetId    — references an AnalysisSet (population)
        ├── dataSubsetId     — references a DataSubset (optional)
        ├── orderedGroupings — references GroupingFactors (treatment, visit, etc.)
        ├── methodId         — references an AnalysisMethod
        ├── reason           — SPECIFIED IN PROTOCOL / SPECIFIED IN SAP / DATA DRIVEN
        ├── purpose          — PRIMARY OUTCOME MEASURE / SECONDARY / EXPLORATORY
        ├── documentRefs     — links to SAP, program files
        ├── programmingCode  — actual R/SAS code or reference to file
        └── results          — the ARD (OperationResults)
            └── OperationResult
                ├── operationId     — which operation this result is for
                ├── resultGroups    — which group combination (e.g., Treatment A, Week 24)
                ├── rawValue        — unformatted result
                └── formattedValue  — result formatted per resultPattern
```

---

### Output / Display Objects

These define the **display** — the table itself, its title, footnotes, and how analyses map into it.

```
ReportingEvent
└── Outputs
    └── Output
        ├── fileSpecifications  — output file format (PDF, RTF, TXT)
        ├── programmingCode     — code to generate the display
        └── displays            — ordered list of displays in the output
            └── OrderedDisplay
                └── OutputDisplay
                    ├── displayTitle      — the table title
                    └── displaySections   — title, header, footnote, abbreviation, footer
                        └── DisplaySection
                            └── OrderedDisplaySubSection
                                └── DisplaySubSection (text)
```

---

### Document Reference Objects

Used throughout to link to external documents (SAP, programs).

```
DocumentReference
├── referenceDocumentId   — points to a ReferenceDocument
└── pageRefs              — optional specific page(s) in the document
    └── PageRef (abstract)
        ├── PageNumberListRef    — specific page numbers [3, 7, 12]
        ├── PageNumberRangeRef   — page range: first=3, last=7
        └── PageNameRef         — named bookmarks
```

---

## 2.4 The WhereClause System

The `WhereClause` is the most important structural pattern in ARS because it appears in three different contexts: `AnalysisSet`, `DataSubset`, and `Group`. Understanding it well is critical.

### Simple Condition

```json
{
  "condition": {
    "dataset": "ADSL",
    "variable": "ITTFL",
    "comparator": "EQ",
    "value": ["Y"]
  }
}
```

This directly maps to: `WHERE ADSL.ITTFL = 'Y'` in SAS, or `filter(ITTFL == "Y")` in R.

### Compound Expression

```json
{
  "compoundExpression": {
    "logicalOperator": "AND",
    "whereClauses": [
      {
        "condition": {
          "dataset": "ADSL",
          "variable": "ITTFL",
          "comparator": "EQ",
          "value": ["Y"]
        }
      },
      {
        "condition": {
          "dataset": "ADSL",
          "variable": "AGE",
          "comparator": "GE",
          "value": ["18"]
        }
      }
    ]
  }
}
```

Logical operators: `AND`, `OR`, `NOT`.
Comparators: `EQ`, `NE`, `GT`, `GE`, `LT`, `LE`, `IN`, `NOTIN`.

### Referenced WhereClause

A `WhereClause` can reference another already-defined clause by its ID (e.g., reusing an `AnalysisSet` as part of a `Group` definition). This avoids repeating complex logic.

---

## 2.5 The Controlled Terminology

ARS uses four extensible enumerations. These are the only controlled terms in the model:

| Enumeration | Values | What it encodes |
|-------------|--------|-----------------|
| `AnalysisReasonEnum` | SPECIFIED IN PROTOCOL, SPECIFIED IN SAP, DATA DRIVEN, REQUESTED BY REGULATORY AGENCY | When/why the analysis was planned |
| `AnalysisPurposeEnum` | PRIMARY OUTCOME MEASURE, SECONDARY OUTCOME MEASURE, EXPLORATORY OUTCOME MEASURE | Role of the analysis in the study |
| `OperationRoleEnum` | NUMERATOR, DENOMINATOR | Relationship between operations (for % calculations) |
| `OutputFileTypeEnum` | pdf, rtf, txt | File format of output |

All four are **extensible** — sponsors can add their own terms via `TerminologyExtension`.

---

## 2.6 Key Design Principles

**Principle 1: Reuse over repetition**

Methods, AnalysisSets, DataSubsets, and Groups are defined once and referenced by ID from multiple Analyses. If 50 analyses all use the ITT population, there is one `AnalysisSet` with `id = "AS001"` and all 50 analyses reference `analysisSetId = "AS001"`. This is how the model enforces consistency.

**Principle 2: Separation of specification from results**

The specification (what to do) and the results (what was computed) live in the same `Analysis` object. The `results` slot contains `OperationResult` objects — this is the ARD. But the analysis specification is the parent. This means the full context of a result is always navigable from the result itself.

**Principle 3: Ordered everything**

Lists in ARS are ordered explicitly using `level` and `order` integer fields. The `ListOfContents` uses this to define the table of contents. `OrderedGroupings` uses it to define the sequence of grouping factors. This is important for display rendering.

**Principle 4: Extensibility**

Where CDISC controlled terms don't cover a sponsor's needs, the `TerminologyExtension` mechanism allows adding custom terms while remaining conformant with the standard.

---

## 2.7 Entity-Relationship Summary

```
ReportingEvent (1)
    |
    ├─── (many) AnalysisSet          ← referenced by Analysis.analysisSetId
    ├─── (many) DataSubset           ← referenced by Analysis.dataSubsetId
    ├─── (many) GroupingFactor       ← referenced by OrderedGroupingFactor.groupingId
    │            └── (many) Group    ← referenced by ResultGroup.groupId
    ├─── (many) AnalysisMethod       ← referenced by Analysis.methodId
    │            └── (many) Operation ← referenced by OperationResult.operationId
    ├─── (many) Analysis             ← referenced by OrderedListItem.analysisId
    │            └── (many) OperationResult (ARD lives here)
    ├─── (many) Output               ← referenced by OrderedListItem.outputId
    │            └── (many) OutputDisplay
    └─── (many) ReferenceDocument    ← referenced by DocumentReference.referenceDocumentId
```

---

## Chapter 2 Summary

- The ARS model has a single root: `ReportingEvent`
- ARM-TS objects define the specification: AnalysisSets, DataSubsets, Groupings, Methods, Analyses, Outputs
- ARD lives inside `Analysis.results` as `OperationResult` objects
- `WhereClause` is the universal filter mechanism (maps to your WHERE clauses)
- Objects are defined once and referenced by ID — reuse is a core principle
- Four extensible controlled terminologies cover reason, purpose, operation role, and file type

**Next:** Chapter 3 — ARM-TS Deep Dive (every object with examples and annotated shell mappings)
