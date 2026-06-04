# Object ID Conventions

Every object in an ARS reporting event has an `id` field. IDs are the glue
that holds the model together — `analysisSetId`, `methodId`, `groupingId`,
`operationId`, `groupId`, `referenceDocumentId`, `analysisId`, `outputId`,
`subSectionId` all point back at an `id` defined somewhere in the
`ReportingEvent`.

This chapter documents the rules — what the standard mandates, what is
industry convention, and what is sponsor choice.

---

## 1. What the Standard Mandates

The ARS LDM (Logical Data Model) declares the `id` field on every class as:

- **Type:** `String`
- **Cardinality:** required (1..1) for almost every class that has it
- **Constraint:** must be **unique within scope**

That is the *entire* normative requirement. CDISC does not prescribe a
specific format for IDs. They can be UUIDs, sequential integers, sponsor
codes, or human-readable strings. The single rule is uniqueness within scope.

### What "within scope" means in practice

| Class | Uniqueness scope |
|-------|------------------|
| `ReportingEvent.id` | Global (across sponsor / submission) — conventionally one per CSR |
| `AnalysisSet.id`, `DataSubset.id`, `GroupingFactor.id`, `AnalysisMethod.id`, `Analysis.id`, `Output.id`, `ReferenceDocument.id` | Unique **within** the enclosing `ReportingEvent` |
| `Group.id` | Unique **within** the enclosing `GroupingFactor` (often unique across all groups too, by convention) |
| `Operation.id` | Unique **within** the enclosing `AnalysisMethod` (often globally unique by convention) |
| `OutputDisplay.id`, `DisplaySubSection.id` | Unique within the enclosing `Output` |
| `SponsorTerm.id` | Unique within the enclosing `TerminologyExtension` |

When in doubt, **make every ID globally unique within the entire
`ReportingEvent`**. It costs nothing and prevents subtle bugs when objects
are referenced cross-class (e.g., an `Analysis.documentRefs` referencing a
`ReferenceDocument.id` from a `Group.id` by accident).

---

## 2. Industry-Standard Prefix Conventions

The CDISC examples and the dominant industry usage attach a two-to-four
letter prefix indicating the object class, followed by a zero-padded
sequence number. None of this is mandated, but adopting it everywhere makes
ARM-TS JSON enormously easier to read.

| Object class | Convention | Examples |
|--------------|-----------|----------|
| `ReportingEvent` | `RE` + 3-digit number | `RE001`, `RE_XYZ001_CSR_FINAL` |
| `ReferenceDocument` (SAP, etc.) | `SAP` + number (for SAPs); `PROG`, `PROT`, `CRF` for others | `SAP001`, `PROG001`, `PROT001` |
| `AnalysisSet` | `AS` + 3-digit number | `AS001` (ITT), `AS002` (Safety), `AS003` (Per-Protocol) |
| `DataSubset` | `DS` + 3-digit number | `DS001`, `DS002` |
| `GroupingFactor` | `GF` + 3-digit number | `GF001` (Treatment Arm), `GF002` (Visit) |
| `Group` | `G` + 3-digit number | `G001` (Drug A), `G002` (Placebo) |
| `AnalysisMethod` | `M` + 3-digit number | `M001` (continuous summary), `M002` (count + %) |
| `Operation` | `O` + 3-digit number | `O001` (n), `O002` (Mean), `O008` (Percentage) |
| `Analysis` | `AN` + 3-digit number | `AN001`, `AN042` |
| `Output` | `OUT` + 3-digit number | `OUT001`, `OUT_T_14_1_1` |
| `OutputDisplay` | `DISP` + 3-digit number | `DISP001`, `DISP_14_1_1` |
| `DisplaySubSection` | `TITLE`, `HDR`, `FN`, `ABBR`, `FTR` + number | `TITLE001`, `FN001`, `ABBR001` |
| `ReferencedOperationRelationship` | `ROR` + 3-digit number | `ROR001` |
| `AnalysisOutputCategorization` | `CAT` + 3-digit number | `CAT001` |
| `AnalysisOutputCategory` | `C` + 3-digit number | `C001` (Safety), `C002` (Efficacy) |
| `SponsorTerm` | `ST` + 3-digit number | `ST001` |

### Two equally common naming styles

**Style A — sequential code** (machine-friendly, dense):
```
AS001, AS002, AS003
GF001
M001, M002
AN001, AN002, … AN045
```

**Style B — descriptive code** (human-friendly, longer):
```
AS_ITT, AS_SAFETY, AS_PP
GF_TRT01A
M_SUMM_CONT, M_COUNT_PCT
AN_AGE_BY_TRT, AN_AE_PT_BY_TRT
```

Both are valid. The CDISC reference examples use **Style A**; some sponsor
implementations prefer Style B for the easier code-review experience. Pick
one **and apply it consistently to the entire `ReportingEvent`** — mixing
styles within one file is the hardest pattern to read.

---

## 3. ID Field Rules — Validator Checklist

A robust validator (the kind `arsbridge::validate_ard()` will become) checks:

1. **Presence.** Every required `id` is present and non-empty.
2. **Uniqueness.** No two objects within the same scope share an `id`.
3. **Resolution.** Every `*Id` reference resolves to an existing object.
   - `Analysis.analysisSetId` must match an `AnalysisSet.id`
   - `Analysis.methodId` must match an `AnalysisMethod.id`
   - `OperationResult.operationId` must match an `Operation.id`
   - `ResultGroup.groupingId` must match a `GroupingFactor.id`
   - `ResultGroup.groupId` must match a `Group.id` defined inside that factor
   - …and so on for every `*Id` field
4. **Stability.** Once published, IDs should not be renamed. Add new IDs
   instead of repurposing old ones. (Versioning: bump `ReportingEvent.version`
   if structural changes happen.)
5. **No collisions across classes.** Even though some classes are scoped,
   most sponsors enforce *globally unique* IDs across the entire
   `ReportingEvent` for sanity.

---

## 4. Anti-Patterns to Avoid

- **Spaces or special characters in IDs.** `"AS 001"` or `"AS-001"` are
  technically allowed by the LDM (string), but downstream tooling
  (especially URL encoding for `pageNames`, file references) breaks on
  spaces. **Stick to `[A-Za-z0-9_]`**.
- **IDs that encode mutable facts.** `AS_SAFETY_v1.2` is brittle — when the
  population definition is corrected, you must rename the ID and update
  every reference, breaking traceability. Use opaque IDs (`AS002`) and put
  the version in the `version` field.
- **Two AnalysisSets with the same condition but different IDs.** Define the
  set **once** and reference it many times (Principle 1, "Reuse over
  repetition"). Duplicating the same `WhereClauseCondition` under different
  IDs makes audit impossible.
- **Re-using IDs across documents.** `AS001` should not mean ITT in one
  study's ARM-TS and Safety in another's. If your shop has a master ARS
  library, namespace the IDs (`STUDY01_AS001` vs `STUDY02_AS001`).
- **Numbering gaps you can't explain.** Gaps in `AN001, AN003, AN004, AN007`
  are fine — they reflect deletions during development. But document them
  in `description` so reviewers know the gap is intentional and not a
  missing object.

---

## 5. Working Example — Running Case Study

The sample `reporting_event.json` used in this tutorial uses:

| Object | ID | What it points at |
|--------|----|-------------------|
| `ReportingEvent` | `RE001` | The CDISC pilot CSR |
| `ReferenceDocument` | `SAP001` | The SAP PDF |
| `AnalysisSet` | `AS001`, `AS002` | ITT, Safety populations |
| `GroupingFactor` | `GF001` | Treatment Arm |
| `Group` | `G001`, `G002` | High Dose, Placebo |
| `AnalysisMethod` | `M001` | n, Mean, SD, Median, Min, Max |
| `Operation` | `O001` – `O006` | The six summary statistics |
| `Analysis` | `AN001` | Age summary by treatment arm |

This is **Style A**, applied uniformly. As you build your own ARM-TS files,
mimic this scheme or define a sponsor variant — and document the choice in
the project README so reviewers understand the convention at a glance.
