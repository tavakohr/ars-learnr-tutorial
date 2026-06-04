# CDISC Analysis Results Standard (ARS) — Training Curriculum

**Author:** Prepared for Hamid Tavakoli, MD, MSc  
**Purpose:** Self-study curriculum to build working knowledge of ARS v1.0 before building the `arsbridge` R package  
**Source:** CDISC ARS v1.0 official specification (https://cdisc-org.github.io/analysis-results-standard/)  
**Date:** June 2026

---

## How to Use This Curriculum

Work through the chapters in order. Each chapter builds on the previous one. By Chapter 7 you will have the knowledge needed to begin coding.

| Chapter | Title | What You Will Know After |
|---------|-------|--------------------------|
| 01 | Why ARS Exists | The industry problem, regulatory motivation, where annotated shells fit |
| 02 | The ARS Data Model | The two-part model (ARM-TS + ARD), the object hierarchy, how pieces connect |
| 03 | ARM-TS Deep Dive | Every object type, all fields, JSON examples mapped to annotated shell concepts |
| 04 | ARD Deep Dive | ARD structure, variable definitions, how results are stored |
| 05 | The Traceability Chain | Full worked example: SAP → ARM-TS → ADaM → R code → ARD → display |
| 06 | R Ecosystem and Tools | cards, cardx, gtsummary, datasetjson — what each covers and where gaps are |
| 07 | Package Design Roadmap | arsbridge concept, v0.1 scope, function signatures, JSON-to-shell field mapping |

---

## Prerequisites

- Familiarity with ADaM structure (ADSL, BDS, ADTTE)
- Experience reading/writing annotated TLF shells
- Basic R programming
- No prior ARS knowledge required

---

## Key References

- [ARS v1.0 Specification](https://cdisc-org.github.io/analysis-results-standard/)
- [ARS GitHub Repository](https://github.com/cdisc-org/analysis-results-standard)
- [CDISC 360i Initiative](https://www.cdisc.org/cdisc-360i)
- [cards R package](https://insightsengineering.github.io/cards/)
- [CDISC Pilot Study (reference datasets)](https://github.com/cdisc-org/sdtm-adam-pilot-project)
