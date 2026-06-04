# JSON Field Syntax Reference

The ARS LDM is defined in [LinkML](https://linkml.io/) and serialized as
JSON. This reference documents the field-level rules that every ARM-TS JSON
document must follow.

---

## 1. Field Casing — camelCase Throughout

**Every field in the LDM is `lowerCamelCase`.** This is not a stylistic
choice; it is the LDM's serialization rule, and validators reject other
casings.

```json
{
  "analysisSets":     [...],   ✅
  "dataSubsets":      [...],   ✅
  "analysisGroupings":[...],   ✅
  "AnalysisSets":     [...],   ❌ PascalCase
  "analysis_sets":    [...],   ❌ snake_case
  "analysissets":     [...]    ❌ no boundary
}
```

**Class names (referenced in documentation) are `UpperCamelCase`** to
distinguish them from field names:

- `AnalysisSet` (class) vs `analysisSets` (field on `ReportingEvent`)
- `GroupingFactor` (class) vs `analysisGroupings` (field — note the name
  deliberately differs from the class for historical reasons)

When in doubt: classes start UPPER, fields start lower.

---

## 2. Reference Fields — the `*Id` Convention

References between objects use a suffixed field name with the singular form
of the target class plus `Id`. The value is the string id of the target.

| Field | Points at | Class of target |
|-------|-----------|----------------|
| `analysisSetId` | An `AnalysisSet` | `AnalysisSet` |
| `dataSubsetId` | A `DataSubset` | `DataSubset` |
| `groupingId` | A `GroupingFactor` (note: NOT `groupingFactorId`) | `GroupingFactor` |
| `groupId` | A `Group` within a `GroupingFactor` | `Group` |
| `methodId` | An `AnalysisMethod` | `AnalysisMethod` |
| `operationId` | An `Operation` within a method | `Operation` |
| `analysisId` | An `Analysis` | `Analysis` |
| `outputId` | An `Output` | `Output` |
| `referenceDocumentId` | A `ReferenceDocument` | `ReferenceDocument` |
| `subSectionId` | A `DisplaySubSection` | `DisplaySubSection` |
| `sponsorTermId` | A `SponsorTerm` | `SponsorTerm` |
| `referencedOperationRelationshipId` | A `ReferencedOperationRelationship` | `ReferencedOperationRelationship` |
| `categoryIds` (plural) | One or more `AnalysisOutputCategory` | `AnalysisOutputCategory` |

**Two patterns worth memorizing:**

- Singular `*Id` (string) — exactly one reference, e.g.
  `"analysisSetId": "AS002"`
- Plural `*Ids` (array of strings) — many references, e.g.
  `"categoryIds": ["C001", "C003"]`

If a field name ends in `Id` and is a string, it is a single reference. If
it ends in `Ids` and is an array, it is a list of references.

---

## 3. Collection Fields — Plural Names with Array Values

Top-level collections on `ReportingEvent` are **plural nouns** with array
values. The class of each element is the singular form.

| Field on `ReportingEvent` | Element class |
|---------------------------|---------------|
| `referenceDocuments` | `ReferenceDocument` |
| `analysisSets` | `AnalysisSet` |
| `dataSubsets` | `DataSubset` |
| `analysisGroupings` | `GroupingFactor` (note historical name mismatch) |
| `methods` | `AnalysisMethod` |
| `analyses` | `Analysis` |
| `outputs` | `Output` |
| `terminologyExtensions` | `TerminologyExtension` |
| `analysisOutputCategorizations` | `AnalysisOutputCategorization` |
| `globalDisplaySections` | `GlobalDisplaySection` |

Same rule recursively: `Analysis.results` is an array of
`OperationResult`; `AnalysisMethod.operations` is an array of `Operation`;
`GroupingFactor.groups` is an array of `Group`; etc.

---

## 4. Required vs. Optional Fields

The LDM marks each slot as required or optional. **Required slots must be
present** in the JSON for the document to validate.

### Almost-always-required across classes

| Field | When required |
|-------|---------------|
| `id` | Required on every class that has one |
| `name` | Required on most container classes |
| `version` | Required on `ReportingEvent`, `Analysis`, `Output`, `OutputDisplay` (integer) |
| `mainListOfContents` | Required on `ReportingEvent` |

### Object-specific required slots

| Class | Required slots |
|-------|----------------|
| `Analysis` | `id`, `version`, `reason`, `purpose`, `methodId` |
| `AnalysisMethod` | `id`, `name`, `operations` |
| `Operation` | `id`, `order`, `name` |
| `GroupingFactor` | `id`, `name`, `dataDriven` |
| `WhereClauseCondition` | `dataset`, `variable`, `comparator`, `value` |
| `OperationResult` | `operationId` (plus typically `rawValue` and `resultGroups`) |
| `PageRef` | `refType` (plus type-specific fields) |

Optional fields can simply be omitted from the JSON; **do not write
`null`** unless the LDM explicitly allows it. Validators commonly flag
explicit nulls as schema violations.

---

## 5. Mutual-Exclusion Slot Pairs

A handful of classes carry **two slots that cannot both be present**.
Exactly one must be supplied.

### `AnalysisSet`, `DataSubset`, `Group`

```
condition (WhereClauseCondition)    ── simple
compoundExpression (Compound...Expression) ── complex (AND/OR/NOT)
```

Use `condition` for a single `[dataset].[variable] [comparator] [value]`
filter. Use `compoundExpression` for two or more conditions combined with
`AND`, `OR`, or `NOT`. Never both.

### `ExtensibleTerminologyTerm`

```
controlledTerm (string)   ── value from the CDISC enum
sponsorTermId (string)    ── reference to a sponsor-defined SponsorTerm
```

If the value is one of the standard CDISC enum values, use `controlledTerm`.
If the value is a sponsor extension, use `sponsorTermId` and define the
extension in `ReportingEvent.terminologyExtensions`.

### `PageRef` (one of, depending on `refType`)

```
refType: "PhysicalRef"   → pageNumbers OR (firstPage AND lastPage)
refType: "NamedDestination" → pageNames
```

---

## 6. Ordered Slots — `order` and `level`

Several classes carry an integer `order` field (and some carry `level`).
These dictate display sequence — they are NOT scope identifiers.

| Class | Field(s) | Used for |
|-------|----------|----------|
| `Operation` | `order` | Sequence of statistics within a method (n, Mean, SD, …) |
| `OrderedGroupingFactor` | `order` | Sequence of grouping factors within an analysis |
| `OrderedDisplay` | `order` | Sequence of displays within an output |
| `OrderedDisplaySubSection` | `order` | Sequence of subsections within a display section |
| `OrderedListItem` | `order`, `level` | Position in a `ListOfContents` (level = nesting depth) |
| `AnalysisSet`, `DataSubset`, `Group` | `order`, `level` | Hierarchical organization in tooling |

**Numbering convention:** `1`-based, sequential. Don't start at `0`. Don't
skip numbers without reason. Validators commonly accept gaps but flag them
as warnings.

---

## 7. Strings, Numbers, Booleans, Dates

- **All identifiers and result values are `String`.** This includes
  `rawValue` and `formattedValue` on `OperationResult` — both are stored as
  strings even though `rawValue` is numeric in meaning. Reason: precision
  preservation (`"84.44444444"` round-trips exactly; a JSON number might
  silently lose precision).
- **`order`, `level`, `version`, `firstPage`, `lastPage`, `pageNumbers[]`
  are `Integer`.**
- **`dataDriven`, `resultsByGroup` are `Boolean`** (lowercase `true` /
  `false` in JSON, no quotes).
- **`location` (on `ReferenceDocument`, `OutputFile`) is `Uri`** — a string
  that should be a valid URI/URL/path.
- **No formal date type.** Dates live inside free-text `description` /
  `label` fields. If you need machine-readable dates, encode them as
  ISO 8601 strings (`"2025-04-15"`) inside `description`.

---

## 8. Required-by-class Quick Reference

When building a minimal valid `ReportingEvent`, you must include at least:

```json
{
  "id": "RE001",
  "version": 1,
  "name": "...",
  "mainListOfContents": {
    "name": "Main List",
    "contentsList": { "listItems": [] }
  }
}
```

To do anything useful, you add `analysisSets`, `methods`, `analyses`, and
`outputs`. Each requires its own minimal scaffolding documented in the
table in §4.

---

## 9. Anti-Patterns to Avoid

- **Wrapping single references in arrays.** `"analysisSetId": ["AS002"]`
  is wrong because `analysisSetId` is a singular reference (string). The
  array form would be `"analysisSetIds"`.
- **Writing references as nested objects.** `"analysisSet": { "id": "AS002" }`
  is wrong — the field is `analysisSetId` (string), not `analysisSet`
  (nested object). The model uses by-id references throughout to prevent
  duplication.
- **Capitalizing comparators or logical operators inconsistently.** The
  enum values are uppercase exactly: `EQ`, `NE`, `GT`, `GE`, `LT`, `LE`,
  `IN`, `NOTIN`, `AND`, `OR`, `NOT`. Lowercase variants are not accepted.
- **Embedding `value` as a string when it should be a list.**
  `"value": "Y"` is wrong; it must be `"value": ["Y"]`. (The list form
  supports `IN`/`NOTIN` with multiple values, and the LDM uses one
  consistent shape.)
- **Forgetting `version` integer on `ReportingEvent`, `Analysis`, `Output`,
  `OutputDisplay`.** These four classes require it.
