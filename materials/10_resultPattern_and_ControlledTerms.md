# `resultPattern` Grammar and Controlled Terminology

Two topics that are scattered across the ARS LDM and rarely documented end-
to-end in one place: how `resultPattern` actually works, and the exact
permissible values for every enumeration in the standard.

---

## Part A — The `resultPattern` Field

`resultPattern` is a slot on `Operation`. The LDM definition is short:

> "The default pattern or format to apply to the result for display."

That's all the standard says. The `X`-based grammar below is **industry
convention**, used by the CDISC examples, by `{cards}` / `{gtsummary}`, and
by every published ARM-TS file the author has seen. It is *not* a normative
syntax — sponsors may use SAS-format strings (`8.1`), Excel-style codes
(`0.0`), or anything else — but the conventional grammar is the one
covered here, and is the one this tutorial uses throughout.

### A.1 The grammar

| Character | Meaning |
|-----------|---------|
| `X` | One digit position |
| `.` | The decimal point (separates the integer and decimal parts) |
| `(` and `)` | Literal parentheses to appear in the formatted output |
| `%` | Literal percent sign |
| `:` | Literal colon (used in `XX:XX` patterns for time-like values) |

Position semantics: **count the `X`s after the decimal point to know the
number of decimal places**. The `X`s before the decimal point indicate the
maximum integer width but are not strictly enforced — `XX.X` accepts both
`9.5` and `12.3`.

### A.2 Common patterns

| Pattern | Decimal places | Use case | Example raw → formatted |
|---------|----------------|----------|------------------------|
| `XXX` | 0 (integer) | n, counts, denominators | `45` → `45` |
| `XX.X` | 1 | Mean, percentage, median | `84.44444` → `84.4` |
| `XXX.XX` | 2 | SD, hazard ratios | `5.234` → `5.23` |
| `X.XXX` | 3 | p-values, sometimes effect sizes | `0.0234` → `0.023` |
| `X.XXXX` | 4 | Very precise p-values | `0.00031` → `0.0003` |
| `(XX.X)` | 1, with parens | "(84.4)" wrapper for percentages | `84.4` → `(84.4)` |
| `XX.X%` | 1, with percent sign | "84.4%" wrapper | `84.4` → `84.4%` |
| `XX.X (XX.X)` | composite | n (%) joined display | composite — uses two operations |

### A.3 Validation rule

Given `rawValue` (string) and `resultPattern`, the **expected `formattedValue`**
is what you would get by:

1. Parsing `rawValue` as a `Double`.
2. Counting the number of `X`s after the `.` in `resultPattern`. Call this `n`.
3. Formatting the number with that many decimal places, rounded half-up
   (`sprintf("%.<n>f", value)` in R/C).
4. Substituting that formatted number into the `resultPattern`, replacing
   the consecutive `X` runs.

`arsbridge::validate_ard()` Check #5 applies this rule. A discrepancy
between the recomputed expected value and the stored `formattedValue`
is flagged.

### A.4 Edge cases worth knowing

- **Integer rawValue with non-zero decimal pattern.** `rawValue = "45"`,
  `resultPattern = "XX.X"` → formattedValue should be `"45.0"`. Some
  tooling drops trailing zeros incorrectly.
- **Negative numbers.** Conventional patterns don't show a leading `-`,
  but `-12.3` is formatted as `-12.3` (the sign comes from the value, not
  the pattern).
- **Composite n (%) displays.** These are produced by TWO operations
  (Count and Percentage), each with its own `resultPattern`. The
  *display* may join them as "38 (84.4)", but the *ARD* stores them
  separately as two `OperationResult` rows.

---

## Part B — The Controlled Terminology

ARS uses two layers of vocabulary:

1. **Closed enumerations** — fixed values built into the LDM; not extensible.
2. **Extensible enumerations** — published values plus sponsor-defined terms
   added via `TerminologyExtension`.

### B.1 Closed enumerations

#### `ConditionComparatorEnum` — comparators in WhereClauseCondition

| Value | Meaning |
|-------|---------|
| `EQ` | equal |
| `NE` | not equal |
| `LT` | less than |
| `LE` | less than or equal |
| `GT` | greater than |
| `GE` | greater than or equal |
| `IN` | value is one of the supplied list |
| `NOTIN` | value is not one of the supplied list |

Values are **uppercase exactly**. Case variants (`eq`, `Eq`) are not
accepted.

#### `ExpressionLogicalOperatorEnum` — combinators in compound expressions

| Value | Meaning |
|-------|---------|
| `AND` | All sub-clauses must be true |
| `OR`  | At least one sub-clause must be true |
| `NOT` | The single sub-clause must be false |

Note: `NOT` combines with a **single** child clause; `AND` and `OR` take two
or more.

#### `DisplaySectionTypeEnum` — sections within an `OutputDisplay`

| Value | Where it appears in the table |
|-------|-------------------------------|
| `Title` | Above the table body |
| `Header` | The column-header row(s) |
| `Rowlabel-Header` | Row-label column header |
| `Body` | The data cells |
| `Footnote` | Below the table, before the trailing footer |
| `Abbreviation` | Glossary of abbreviations |
| `Footer` | Final trailing line(s) |

#### `PageRefTypeEnum` — kind of page reference

| Value | Meaning |
|-------|---------|
| `PhysicalRef` | Refers to physical page numbers in a PDF (`firstPage`/`lastPage` or `pageNumbers`) |
| `NamedDestination` | Refers to PDF bookmarks/named destinations by name (`pageNames`) |

### B.2 Extensible enumerations

Each of these has CDISC-published values *and* may be extended by sponsors
via `TerminologyExtension` + `SponsorTerm`. The class that consumes the
enum is `ExtensibleTerminologyTerm`, which has either a `controlledTerm`
(string) for the CDISC value or a `sponsorTermId` (reference) for the
extension.

#### `AnalysisReasonEnum` — why was this analysis performed?

| CDISC value | Meaning |
|-------------|---------|
| `SPECIFIED IN PROTOCOL` | Pre-planned in the study protocol |
| `SPECIFIED IN SAP` | Pre-planned in the SAP (most common in CSRs) |
| `DATA DRIVEN` | Post-hoc / exploratory based on observed data |
| `REQUESTED BY REGULATORY AGENCY` | Added in response to FDA/EMA query |

#### `AnalysisPurposeEnum` — role in the study

| CDISC value | Meaning |
|-------------|---------|
| `PRIMARY OUTCOME MEASURE` | Primary endpoint of the trial |
| `SECONDARY OUTCOME MEASURE` | Secondary endpoint |
| `EXPLORATORY OUTCOME MEASURE` | Exploratory endpoint |

#### `OperationRoleEnum` — role of a referenced operation

| CDISC value | Meaning |
|-------------|---------|
| `NUMERATOR` | This operation provides the numerator (e.g., Count → Percentage) |
| `DENOMINATOR` | This operation provides the denominator (e.g., Total N → Percentage) |

#### `OutputFileTypeEnum` — output file format

| CDISC value | Meaning |
|-------------|---------|
| `pdf` | Adobe PDF |
| `rtf` | Rich Text Format |
| `txt` | Plain text |

Note that these are **lowercase** by convention (unlike the other enums
which are uppercase). This is how CDISC publishes them.

### B.3 Extending an enumeration

If your study needs a value like `"PER PROTOCOL DEVIATION ANALYSIS"` for
`AnalysisReasonEnum`, add it via:

```json
{
  "terminologyExtensions": [
    {
      "id": "TE001",
      "enumeration": "AnalysisReasonEnum",
      "sponsorTerms": [
        {
          "id": "ST001",
          "submissionValue": "PER PROTOCOL DEVIATION ANALYSIS",
          "description": "Analysis added in response to protocol deviation review"
        }
      ]
    }
  ]
}
```

Then the `Analysis` references the extension:

```json
{
  "reason": { "sponsorTermId": "ST001" }
}
```

(rather than `{ "controlledTerm": "..." }`).

This is **Principle 4 (Extensibility)** — the standard stays small and
stable; sponsor-specific terminology is captured explicitly and is
machine-traceable to its definition.

---

## Part C — Putting It All Together

The combined rule set lets you both *produce* a conformant ARM-TS and
*validate* an arbitrary one:

- **Producing.** Stick to the `X`-grammar for `resultPattern`; use exactly
  the closed enum values verbatim; extend via `TerminologyExtension` when
  necessary; never invent ad-hoc strings inside `controlledTerm`.
- **Validating.** For every `controlledTerm` value, check it appears in the
  appropriate enum's value list. For every `formattedValue`, recompute from
  `rawValue` + `resultPattern` and compare. For every `comparator` /
  `logicalOperator`, check exact-uppercase membership in its closed enum.

`arsbridge::validate_ard()` Check #5 (format consistency) and Check #6
(controlled-term membership) collectively automate the entire bottom
half of this chapter.
