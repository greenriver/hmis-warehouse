# Project Scorecard — Scoring Methodology

This document describes how projects are scored on the Project Scorecard. It is
intended to be shared with stakeholders for review and validation.

## Overview

Each project is evaluated across **four scoring categories**, each with a fixed
weight toward the final score:

| Category                        | Weight |
|---------------------------------|--------|
| Project Performance             | 50%    |
| HMIS Data Quality               | 20%    |
| Coordinated Entry Participation | 20%    |
| Grant Management & Financials   | 10%    |

A fifth section, **Review Only**, displays additional metrics but does **not**
count toward the total score.

### How the total score is calculated

Within each category, every line item earns a point value. The category's points
are summed, divided by the maximum points available for that category, and
multiplied by the category weight:

```
Category Percentage = (Points Earned / Max Points Available) × Weight × 100
```

The four category percentages are then added together:

```
Total Score = Performance % + Data Quality % + CE Participation % + Grant Mgmt %
```

A perfect score across all categories yields **100%**.

### Project type variations

Several line items use different thresholds depending on the project type:

- **PSH** — Permanent Supportive Housing
- **SH** — Safe Haven (scored identically to PSH in all cases)
- **RRH** — Rapid Re-Housing

Where scoring differs by project type, both sets of thresholds are shown. Line
items that apply to only one project type are marked accordingly.

---

## 1. Project Performance (50% weight)

### Scoring table

| # | Line Item | Applies To | High Points | High Threshold | Mid Points | Mid Threshold | Low Points |
|---|-----------|------------|-------------|----------------|------------|---------------|------------|
| 1 | Quarterly Occupancy Utilization Rate | All | — | — | — | — | — |
| 2 | Exit to Permanent Housing | PSH / SH | **5** | ≥ 98% | **3** | 90 – 97% | **0** |
| 2 | Exit to Permanent Housing | RRH / Other | **5** | ≥ 95% | **3** | 90 – 94% | **0** |
| 3 | Average Length of Stay (Leavers) | RRH only | **5** | 3 – 18 months | **3** | 19 – 24 months | **0** |
| 4 | Increased Employment Income at Exit | PSH / SH | **15** | ≥ 15% | **10** | 9 – 14% | **0** |
| 4 | Increased Employment Income at Exit | RRH | **15** | ≥ 56% | **10** | 50 – 55% | **0** |
| 5 | Increased Other Cash Income at Exit | PSH / SH | **10** | ≥ 61% | **5** | 55 – 60% | **0** |
| 5 | Increased Other Cash Income at Exit | RRH | **10** | ≥ 21% | **5** | 15 – 20% | **0** |
| 6 | Returns to Homelessness | All | **15** | 0 – 5% | **10** | 6 – 15% | **0** |

### Notes

- **Utilization (row 1)** — The utilization percentage is calculated and displayed
  but is **not currently scored**. It does not contribute points.
- **Average LOS (row 3)** — Only applies to RRH projects. PSH/SH projects do not
  receive this line item and it is excluded from their maximum points.
- **Returns to Homelessness (row 6)** — Sourced from the HUD SPM (Measure 2). If
  there are no qualifying exits in the reporting period, this metric returns no
  data. When that happens, the 15 points are removed from the maximum available
  rather than counted as zero.

### Maximum points available

| Project Type | Max Points | Breakdown |
|--------------|------------|-----------|
| PSH / SH | 45 | 5 + 15 + 10 + 15 |
| PSH / SH (no returns data) | 30 | 5 + 15 + 10 |
| RRH | 50 | 5 + 5 + 15 + 10 + 15 |
| RRH (no returns data) | 35 | 5 + 5 + 15 + 10 |

---

## 2. HMIS Data Quality (20% weight)

| # | Line Item | High (10 pts) | Mid (5 pts) | Low (0 pts) |
|---|-----------|---------------|-------------|-------------|
| 1 | PII Error Rate | 0 – 1% | 2 – 5% | > 5% |
| 2 | Universal Data Element (UDE) Error Rate | 0 – 1% | 2 – 5% | > 5% |
| 3 | Income & Housing Error Rate | 0 – 1% | 2 – 5% | > 5% |

**Maximum points available: 30** (all project types)

All three line items use identical thresholds. Error rates are calculated from
the HUD APR.

---

## 3. Coordinated Entry Participation (20% weight)

| # | Line Item | High (10 pts) | Mid (5 pts) | Low (0 pts) |
|---|-----------|---------------|-------------|-------------|
| 1 | Average Days to Lease-Up | 0 – 60 days | 61 – 75 days | > 75 days |
| 2 | Accepted Referral Rate | Any value (0%+) | — | — |

**Maximum points available: 20** (all project types)

### Notes

- **Accepted Referral Rate (row 2)** — Per the 2023 specification, all projects
  receive 10 points for this line item regardless of their referral acceptance
  rate, as long as data is present.

---

## 4. Grant Management & Financials (10% weight)

| # | Line Item | High Points | High Threshold | Mid Points | Mid Threshold | Low Points |
|---|-----------|-------------|----------------|------------|---------------|------------|
| 1 | Spend-Down Variance | **10** | 0 – 10% (absolute) | **5** | 11 – 15% (absolute) | **0** |
| 2 | Cost Efficiency per Participant | PSH / SH | | | | |
|   | | **10** | $0 – $8,999 | **5** | $9,000 – $11,000 | **0** |
| 2 | Cost Efficiency per Participant | RRH | | | | |
|   | | **10** | $0 – $2,499 | **5** | $2,500 – $5,400 | **0** |
| 3 | Recaptured Funds | **10** | 0 – 2% | **5** | 3 – 5% | **0** |
| 4 | Supportive Services Plan | **5** | Yes | — | — | **0** (No) |
| 5 | PIT Count Participation | **5** | Yes | — | — | **0** (No) |
| 6 | CoC Meetings Attended | **10** | ≥ 70% | **5** | 50 – 69% | **0** |

### Maximum points available

| Scenario | Max Points | Notes |
|----------|------------|-------|
| Standard | 50 | 10 + 10 + 10 + 5 + 5 + 10 |
| Expansion Year | 40 | Cost Efficiency is excluded (scores 0 automatically) |

### Notes

- **Spend-Down Variance (row 1)** — Compares actual spending to a pro-rated
  projection: `projected = amount_awarded × (months_since_start / 12)`. The
  variance is the absolute percentage difference between projected and actual.
- **Cost Efficiency (row 2)** — Calculated as
  `(budget + match) / participants_in_housing`. During an **expansion year**,
  this item automatically scores 0 and the maximum is reduced from 50 to 40.
  Safe Haven projects use the PSH thresholds.
- **Supportive Services (row 4) and PIT Participation (row 5)** — These are
  yes/no items worth a maximum of 5 points each (not 10).

---

## 5. Review Only (not scored)

These metrics are displayed on the scorecard for informational purposes but do
**not** contribute to the total score.

| # | Line Item | 10 pts | 5 pts | 0 pts |
|---|-----------|--------|-------|-------|
| 1 | CES Rejected Referral Rate | 0 – 10% | — | ≥ 11% |
| 2 | Site Monitoring | No Findings | Findings but Resolved | Finding with no Resolution |
| 3 | VI-SPDAT | — | — | — |

VI-SPDAT data (number of clients with assessments and average score) is displayed
for reference but has no point values or scoring thresholds.

---

## Appendix A: Worked example — PSH project (standard year)

Suppose a PSH project earns the following scores:

| Category | Points Earned | Max Points | Weight | Percentage |
|----------|---------------|------------|--------|------------|
| Project Performance | 35 | 45 | 50% | (35 / 45) × 50 = **38.9%** |
| Data Quality | 25 | 30 | 20% | (25 / 30) × 20 = **16.7%** |
| CE Participation | 20 | 20 | 20% | (20 / 20) × 20 = **20.0%** |
| Grant Mgmt & Financials | 40 | 50 | 10% | (40 / 50) × 10 = **8.0%** |
| **Total** | | | | **83.6%** |

Each category percentage is rounded to the nearest whole number before summing.

## Appendix B: Worked example — RRH project (expansion year)

Suppose an RRH project in an expansion year earns the following scores:

| Category | Points Earned | Max Points | Weight | Percentage |
|----------|---------------|------------|--------|------------|
| Project Performance | 40 | 50 | 50% | (40 / 50) × 50 = **40.0%** |
| Data Quality | 30 | 30 | 20% | (30 / 30) × 20 = **20.0%** |
| CE Participation | 15 | 20 | 20% | (15 / 20) × 20 = **15.0%** |
| Grant Mgmt & Financials | 30 | 40 | 10% | (30 / 40) × 10 = **7.5%** |
| **Total** | | | | **82.5%** |

Note the Grant Mgmt max is 40 (not 50) because Cost Efficiency is excluded
during expansion years.

## Appendix C: Complete point value summary by project type

### PSH / Safe Haven

| Line Item | High | Mid | Low | Max |
|-----------|------|-----|-----|-----|
| Exit to Permanent Housing | 5 (≥ 98%) | 3 (90–97%) | 0 | 5 |
| Employment Income | 15 (≥ 15%) | 10 (9–14%) | 0 | 15 |
| Other Cash Income | 10 (≥ 61%) | 5 (55–60%) | 0 | 10 |
| Returns to Homelessness | 15 (0–5%) | 10 (6–15%) | 0 | 15 |
| PII Errors | 10 (0–1%) | 5 (2–5%) | 0 | 10 |
| UDE Errors | 10 (0–1%) | 5 (2–5%) | 0 | 10 |
| Income/Housing Errors | 10 (0–1%) | 5 (2–5%) | 0 | 10 |
| Days to Lease-Up | 10 (0–60d) | 5 (61–75d) | 0 | 10 |
| Accepted Referrals | 10 (any) | — | — | 10 |
| Spend-Down Variance | 10 (0–10%) | 5 (11–15%) | 0 | 10 |
| Cost Efficiency | 10 (≤ $8,999) | 5 ($9k–$11k) | 0 | 10 |
| Recaptured Funds | 10 (0–2%) | 5 (3–5%) | 0 | 10 |
| Supportive Services | 5 (Yes) | — | 0 (No) | 5 |
| PIT Participation | 5 (Yes) | — | 0 (No) | 5 |
| CoC Meetings | 10 (≥ 70%) | 5 (50–69%) | 0 | 10 |

### RRH (Rapid Re-Housing)

| Line Item | High | Mid | Low | Max |
|-----------|------|-----|-----|-----|
| Exit to Permanent Housing | 5 (≥ 95%) | 3 (90–94%) | 0 | 5 |
| Avg LOS Leavers | 5 (3–18 mo) | 3 (19–24 mo) | 0 | 5 |
| Employment Income | 15 (≥ 56%) | 10 (50–55%) | 0 | 15 |
| Other Cash Income | 10 (≥ 21%) | 5 (15–20%) | 0 | 10 |
| Returns to Homelessness | 15 (0–5%) | 10 (6–15%) | 0 | 15 |
| PII Errors | 10 (0–1%) | 5 (2–5%) | 0 | 10 |
| UDE Errors | 10 (0–1%) | 5 (2–5%) | 0 | 10 |
| Income/Housing Errors | 10 (0–1%) | 5 (2–5%) | 0 | 10 |
| Days to Lease-Up | 10 (0–60d) | 5 (61–75d) | 0 | 10 |
| Accepted Referrals | 10 (any) | — | — | 10 |
| Spend-Down Variance | 10 (0–10%) | 5 (11–15%) | 0 | 10 |
| Cost Efficiency | 10 (≤ $2,499) | 5 ($2.5k–$5.4k) | 0 | 10 |
| Recaptured Funds | 10 (0–2%) | 5 (3–5%) | 0 | 10 |
| Supportive Services | 5 (Yes) | — | 0 (No) | 5 |
| PIT Participation | 5 (Yes) | — | 0 (No) | 5 |
| CoC Meetings | 10 (≥ 70%) | 5 (50–69%) | 0 | 10 |

### Key differences between PSH/SH and RRH

| Aspect | PSH / SH | RRH |
|--------|----------|-----|
| Exit to PH threshold (high) | ≥ 98% | ≥ 95% |
| Average LOS (Leavers) | Not scored | Scored (max 5 pts) |
| Employment Income threshold (high) | ≥ 15% | ≥ 56% |
| Other Cash Income threshold (high) | ≥ 61% | ≥ 21% |
| Cost Efficiency threshold (high) | ≤ $8,999 | ≤ $2,499 |
| Performance max points | 45 | 50 |

## Appendix D: Special conditions

| Condition | Effect |
|-----------|--------|
| **Expansion year** | Cost Efficiency automatically scores 0; Grant Mgmt max reduced from 50 to 40 |
| **No SPM returns data** | Returns to Homelessness is excluded; Performance max reduced by 15 |
| **Safe Haven projects** | Scored identically to PSH in all categories |
| **Other project types** | Use the RRH thresholds for Exit to PH; Employment Income, Other Cash Income, Cost Efficiency, and Avg LOS return no score. **However, the maximum points denominator is not reduced for these missing metrics**, so projects outside PSH/SH/RRH are scored against a maximum they cannot fully achieve |
