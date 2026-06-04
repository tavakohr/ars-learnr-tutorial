# Chapter 4 — ARD Deep Dive

## 4.1 What the ARD Is

The Analysis Results Dataset (ARD) is the structured representation of the actual computed results of an analysis. It answers the question: *"What number did this analysis produce?"*

In the ARS formal model, ARD lives inside each `Analysis` object as the `results` slot — a list of `OperationResult` objects. In practice, the ARD is often extracted and stored as a flat tabular dataset (a data frame) for use with tools like `{cards}` and `{gtsummary}`.

---

## 4.2 The OperationResult Object

Each `OperationResult` represents the result of one statistical operation for one specific combination of groups.

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `operationId` | string | Yes | References the `Operation` that produced this result |
| `resultGroups` | [ResultGroup] | No | Which group(s) this result belongs to |
| `rawValue` | string | No | The unformatted computed value |
| `formattedValue` | string | No | The value formatted per the operation's `resultPattern` |

### ResultGroup Fields

One `ResultGroup` per grouping factor in the analysis:

| Field | Description |
|-------|-------------|
| `groupingId` | References the `GroupingFactor` |
| `groupId` | References the specific pre-defined `Group` (if not data-driven) |
| `groupValue` | The data value for data-driven groupings |

---

## 4.3 Worked Example: AE Count Table Results

Continuing from Chapter 3: our analysis `AN001` counts subjects with any TEAE by treatment arm using method `M002` (Count and Percentage with denominator).

### The analysis has:
- Method `M002` with operations: `O007` (Count), `O008` (Percentage), `O009` (Denominator)
- Grouping factor `GF001` (Treatment Arm) with groups `G001` (Drug XYZ 10mg) and `G002` (Placebo)
- `resultsByGroup: true` — so we expect separate results for each treatment arm

### The results (ARD) for this analysis:

```json
{
  "results": [
    {
      "operationId": "O009",
      "resultGroups": [
        { "groupingId": "GF001", "groupId": "G001" }
      ],
      "rawValue": "45",
      "formattedValue": "45"
    },
    {
      "operationId": "O009",
      "resultGroups": [
        { "groupingId": "GF001", "groupId": "G002" }
      ],
      "rawValue": "44",
      "formattedValue": "44"
    },
    {
      "operationId": "O007",
      "resultGroups": [
        { "groupingId": "GF001", "groupId": "G001" }
      ],
      "rawValue": "38",
      "formattedValue": "38"
    },
    {
      "operationId": "O007",
      "resultGroups": [
        { "groupingId": "GF001", "groupId": "G002" }
      ],
      "rawValue": "30",
      "formattedValue": "30"
    },
    {
      "operationId": "O008",
      "resultGroups": [
        { "groupingId": "GF001", "groupId": "G001" }
      ],
      "rawValue": "84.44444",
      "formattedValue": "84.4"
    },
    {
      "operationId": "O008",
      "resultGroups": [
        { "groupingId": "GF001", "groupId": "G002" }
      ],
      "rawValue": "68.18182",
      "formattedValue": "68.2"
    }
  ]
}
```

### Reading the ARD

To interpret any `OperationResult`, you navigate:
1. `operationId` → find the `Operation` → get the statistic name and `resultPattern`
2. `resultGroups[i].groupingId` → find the `GroupingFactor` → know what dimension this represents
3. `resultGroups[i].groupId` → find the `Group` → know which specific group
4. `rawValue` / `formattedValue` → the actual number

So the first result says: "The denominator (O009) for the Drug XYZ 10mg group (G001 within GF001) is 45."

---

## 4.4 The Flat ARD Format (as used by {cards})

The `{cards}` R package implements a flat tabular representation of the ARD. Rather than nesting results inside Analysis objects, it produces a data frame where each row is one result with full context columns.

### Standard ARD Data Frame Structure

| Column | Description | Example |
|--------|-------------|---------|
| `group1` | First grouping variable name | `"TRT01A"` |
| `group1_level` | Value of first grouping variable | `"Drug XYZ 10mg"` |
| `group2` | Second grouping variable (if any) | `"SEX"` |
| `group2_level` | Value of second grouping variable | `"M"` |
| `variable` | Analysis variable name | `"AGE"` |
| `variable_level` | For categorical: the level | `NA` or `"Yes"` |
| `stat_name` | Name of the statistic | `"mean"`, `"sd"`, `"n"` |
| `stat_label` | Display label for the stat | `"Mean"`, `"Std. Dev."` |
| `stat` | The computed value | `52.3` |
| `context` | Source/context string | `"continuous"` |
| `fmt_fn` | Formatting function | `"xx.x"` |
| `warning` | Any warnings during computation | `NULL` |
| `error` | Any errors during computation | `NULL` |

### Example ARD data frame (as you would see it in R)

```r
# ard output for age summary by treatment arm
#   group1  group1_level   variable  stat_name  stat_label  stat
# 1 TRT01A  Drug XYZ 10mg  AGE       n          n           45
# 2 TRT01A  Drug XYZ 10mg  AGE       mean       Mean        52.3
# 3 TRT01A  Drug XYZ 10mg  AGE       sd         Std. Dev.   8.7
# 4 TRT01A  Drug XYZ 10mg  AGE       median     Median      53.0
# 5 TRT01A  Drug XYZ 10mg  AGE       min        Min         31
# 6 TRT01A  Drug XYZ 10mg  AGE       max        Max         74
# 7 TRT01A  Placebo        AGE       n          n           44
# 8 TRT01A  Placebo        AGE       mean       Mean        50.1
# ...
```

This flat format is what `{gtsummary}` consumes to render tables. The mapping between the flat ARD and the nested ARS model structure is handled by the tooling.

---

## 4.5 Relationship Between Flat ARD and Formal ARS Model

Understanding how the flat ARD maps to the formal model is critical for `arsbridge`:

| Flat ARD Column | ARS Model Path |
|----------------|----------------|
| `group1` | `GroupingFactor.groupingVariable` |
| `group1_level` | `Group.name` or `ResultGroup.groupValue` |
| `variable` | `Analysis.variable` |
| `stat_name` | `Operation.name` (lowercase) |
| `stat_label` | `Operation.name` (display form) |
| `stat` | `OperationResult.rawValue` |
| *(formatted value)* | `OperationResult.formattedValue` |

The flat ARD loses some ARS model context — specifically, it doesn't carry the `analysisSetId`, `dataSubsetId`, `methodId`, or `documentRefs`. This is the traceability gap: a flat ARD by itself cannot tell you which population was used or which SAP section it came from. That information lives in the ARM-TS.

---

## 4.6 Generating an ARD with {cards}

```r
library(cards)
library(dplyr)

# Assume adsl has TRT01A, AGE, SEX
ard_age <- ard_continuous(
  data = adsl,
  by = TRT01A,
  variables = AGE,
  statistic = list(AGE = continuous_summary_fns(c("n", "mean", "sd", "median", "min", "max")))
)

# View the ARD
ard_age
```

The resulting object is an ARD data frame following the CDISC ARD structure. `{cardx}` extends this with more complex statistics: t-tests, Wilcoxon, KM estimates, regression models.

```r
library(cardx)

# Kaplan-Meier ARD
ard_km <- ard_survival_survfit(
  data = adtte %>% filter(PARAMCD == "OS" & ITTFL == "Y"),
  by = TRT01A,
  variables = c(time = "AVAL", event = "1-CNSR"),
  times = c(6, 12, 24)  # months
)
```

---

## 4.7 What the ARD Cannot Tell You Alone

This is the core problem your `arsbridge` package will address.

A flat ARD data frame contains the results. It does not contain:

- **Which population was used** — you cannot tell from the ARD alone whether this was ITT or Safety Population
- **Which data subset was applied** — was PARAMCD='OS' filtered? AVISIT='Week 24'?
- **What statistical method was used** — was this a raw count or an adjusted estimate?
- **Where in the SAP this analysis is specified** — no SAP reference
- **What the display context is** — which table does this result appear in?

To answer any of these questions, you need the ARM-TS. The ARM-TS is the context layer. The ARD is the result layer. Only together do they form a complete, traceable record.

This is why a validator that can cross-check ARD against ARM-TS is the most useful tool that currently doesn't exist.

---

## 4.8 rawValue vs formattedValue

One important detail:

- `rawValue` is the full-precision computed value: `"84.44444444"`
- `formattedValue` is what appears in the table: `"84.4"`

Both are stored as **strings** in the ARS model, not numerics. This is deliberate — it preserves the exact display representation while also keeping the underlying precision available for downstream use (e.g., for a regulator who wants to verify rounding).

When building `arsbridge`, you will need to handle both. Validation of traceability should compare `rawValue` against a re-computed result; validation of display correctness should compare `formattedValue` against what the `resultPattern` would produce.

---

## Chapter 4 Summary

- The ARD is the result layer: `Analysis.results` → `[OperationResult]`
- Each `OperationResult` stores one statistic for one group combination
- The flat ARD format (used by `{cards}`) is a tabular extraction of this data
- The flat ARD alone is not sufficient for traceability — ARM-TS context is required
- `rawValue` and `formattedValue` are both stored as strings; both matter for validation
- Generating ARDs in R uses `{cards}` and `{cardx}`

**Next:** Chapter 5 — The Traceability Chain (complete worked example)
