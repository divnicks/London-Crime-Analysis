# Analysis of Crime Rates, Deprivation, and Police Force Impact Across London (2015–2025)

A data engineering and analytics project examining crime trends across London's 32 boroughs, exploring the relationship between social deprivation, police force strength, and crime outcomes using a full ETL pipeline, Hadoop/Hive data warehouse, and Tableau dashboards.

> **Note:** This repository contains the CSV files and the Tableau, R, and HiveQL scripts used for the analysis. The full dataset was processed and stored in a local Hadoop/Hive data warehouse environment and is not included here due to size constraints (~10.4 million rows).

---

## Table of Contents

- [Overview](#overview)
- [Business Questions](#business-questions)
- [Datasets](#datasets)
- [Technologies Used](#technologies-used)
- [Architecture & Methodology](#architecture--methodology)
- [ETL Pipeline](#etl-pipeline)
- [Data Warehouse Design](#data-warehouse-design)
- [Key Findings](#key-findings)
- [Analysis & Visualizations](#analysis--visualizations)
- [Recommendations](#recommendations)
- [References](#references)


---

## Overview

- **Motivation:** London's crime rate stands approximately 35% above the UK national average, with violent and sexual offences as the most common serious crimes. Understanding how deprivation and policing resources interact with crime patterns is critical for policymakers, law enforcement, and community services.
- **Objective:** Analyse 10 years of crime data (2015–2025) across London boroughs, enriched with social deprivation indices and Metropolitan Police staffing records, to identify actionable patterns and test five specific business questions.
- **Learning Outcomes:** End-to-end data engineering using R, Hadoop, and Hive; Kimball-based dimensional modelling; data quality validation at scale; and translating analytical findings into policy recommendations.

---

## Business Questions

| # | Question | Type |
|---|----------|------|
| Q1 | Which types of crime were reported most frequently across London monthly from 2015 to 2025? | General |
| Q2 | What are the monthly crime rates in areas of London with higher and lower social deprivation levels, between 2015 and 2025? | General |
| Q3 | What category of crimes had the highest annual unsolved case rates across London from 2015 to 2025? | Specific |
| Q4 | What are the total annual incidents of violent and sexual offences across London, and how do these vary based on levels of social deprivation from 2015 to 2025? | Specific |
| Q5 | What changes in police force strength have occurred across London from 2015 to 2025, and how have these changes impacted monthly crime solve rates? | Specific |

Each question follows a **WHO / WHAT / WHERE / WHEN** framework and maps to a dedicated fact table in the data warehouse.

---

## Datasets

### Primary Dataset — Street-Level Crime Data
- **Source:** [data.police.uk](https://data.police.uk/data/archive/)
- **Coverage:** March 2015 – March 2025, all London boroughs
- **Raw size:** 11,738,142 rows × 6 columns (after appending monthly files)
- **Cleaned size:** 10,436,071 rows × 18 columns (after merging, cleaning, and joining)
- **Key fields used:** `crime_id`, `month`, `crime_type`, `last_outcome_category`, `lsoa_code`, `lsoa_name`

### Secondary Dataset 1 — English Indices of Deprivation (IMD 2019)
- **Source:** [UK Government / Gov.UK](https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/845345/File_7_-_All_IoD2019_ScoresRanks_Deciles_and_Population_Denominators_3.csv)
- **Coverage:** 32,844 LSOAs across England
- **Key fields used:** `lsoa_code`, `lsoa_name`, `imd_score`, `imd_rank`, `imd_decile`
- **Join method:** Left join on `lsoa_code` + `lsoa_name`

### Secondary Dataset 2 — Metropolitan Police Force Strength
- **Source:** [data.london.gov.uk](https://data.london.gov.uk/dataset/police-force-strength)
- **Coverage:** Monthly FTE staffing records (police officers, civilian staff, PCSOs)
- **Key fields used:** `date`, `police_officer_strength`, `police_staff_strength`, `pcso_strength`
- **Join method:** Left join on `month` (crime) ↔ `date` (police), filtered to March 2015–March 2025

---

## Technologies Used

<p>
  <img src="https://img.shields.io/badge/R-276DC3?style=for-the-badge&logo=r&logoColor=white" alt="R">
  <img src="https://img.shields.io/badge/Apache%20Hadoop-66CCFF?style=for-the-badge&logo=apachehadoop&logoColor=black" alt="Hadoop">
  <img src="https://img.shields.io/badge/Apache%20Hive-FDEE21?style=for-the-badge&logo=apachehive&logoColor=black" alt="Hive">
  <img src="https://img.shields.io/badge/Tableau-E97627?style=for-the-badge&logo=tableau&logoColor=white" alt="Tableau">
  <img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker">
</p>

| Tool | Role |
|------|------|
| **RStudio (R)** | Data extraction, cleaning, transformation, validation (`dplyr`, `tidyr`, `lubridate`, `janitor`) |
| **Apache Hadoop (HDFS)** | Distributed storage for large transformed datasets; intermediate staging area |
| **Apache Hive (HiveQL)** | Data warehouse layer; dimension and fact table creation, SQL-like querying |
| **Tableau** | Interactive dashboards and business intelligence visualisations, connected via Cloudera connector |
| **Docker** | Containerised Hadoop/Hive environment for reproducible local deployment |

---

## Architecture & Methodology

### Data Warehouse Methodology — Kimball (Bottom-Up)
The project uses the **Kimball bottom-up approach**, chosen for its speed of delivery, flexibility with multiple data sources, and strong alignment with the five defined business questions. Data marts were built incrementally around specific analytical needs rather than a centralised, fully normalised enterprise model.

### Integration Strategy — ETL
All data transformation occurs **before** loading into HDFS/Hive, making this a traditional ETL (Extract → Transform → Load) pipeline. This ensures data governance and quality control upstream of the warehouse.

```
[data.police.uk CSVs]  ──┐
[IMD 2019 CSV]           ├──► R (Extract + Clean + Transform) ──► HDFS (Staging) ──► Hive (Warehouse) ──► Tableau
[Police Strength CSV]  ──┘
```

---

## ETL Pipeline

### Extract
- Monthly crime CSV files downloaded and appended using R (`bind_rows`)
- Social deprivation and police force CSVs loaded directly

### Transform (R / RStudio)
- Standardise column names (`janitor::clean_names`)
- Filter crime data to London boroughs only
- Create time-based variables: `year`, `quarter`, `month_name`, `year_and_month`
- Convert IMD scores to a 5-tier categorical `DeprivationLevel`: `Very Low` / `Low` / `Medium` / `High` / `Very High` (thresholds informed by histogram and boxplot analysis)
- Classify crime outcomes into `case_status`: `Solved`, `Unsolved`, `Unknown`
- Auto-generate `crime_id` replacements for the ~4 million missing entries
- Replace missing `last_outcome_category` with `"No outcome recorded"`
- Left-join all three datasets on `lsoa_code` / `month`

### Load (HiveQL)
- Data loaded into a **staging (raw) external table** (all columns as STRING, OpenCSVSerde for quote/comma handling)
- Cleaned and cast into a **curated (managed) ORC table** with correct data types
- Dimension and fact tables created and validated in Hive

---

## Data Warehouse Design

A **Fact Constellation (Galaxy) Schema** was implemented — multiple star schemas sharing common dimension tables.

### Dimension Tables

| Table | Key Fields |
|-------|-----------|
| `dim_time` | `time_id`, `year`, `month`, `month_name` |
| `dim_location` | `location_id`, `lsoa_code`, `lsoa_name`, `longitude`, `latitude` |
| `dim_crime_type` | `crime_id`, `crime_type` |
| `dim_deprivation` | `deprivation_id`, `deprivation_level`, `imd_decile` |
| `dim_police_force` | `police_force_id`, `police_force_name` |
| `dim_outcome` | `outcome_id`, `outcome_category`, `case_status` |

### Fact Tables

| Table | Business Question | Key Metrics |
|-------|-------------------|-------------|
| `fact_table_1` | Q1 — Crime frequency by type | `crime_count` |
| `fact_table_2` | Q2 — Crime rate by deprivation level | `crime_count` |
| `fact_table_3` | Q3 — Unsolved crime rates by type | `unsolved_crime_rate` |
| `fact_table_4` | Q4 — Violent & sexual offences by deprivation | `crime_count` |
| `fact_table_5` | Q5 — Police strength vs. solve rate | `solved_rate`, `average_total_officers` |

---

## Data Quality

Six dimensions of data quality were enforced throughout:

1. **Completeness** — Missing values handled via imputation or removal; `crime_id` nulls auto-generated
2. **Uniqueness** — Duplicate records removed (`distinct(crime_id, .keep_all = TRUE)`)
3. **Consistency** — Standardised crime type labels, LSOA names, and date formats
4. **Validity** — Correct data types enforced; categorical variables factored and ordered
5. **Accuracy** — Noise removed, text trimmed, title-cased
6. **Timeliness** — Dataset filtered to exact March 2015–March 2025 window

**Final cleaned dataset:** 10,436,071 rows × 18 columns, 0 missing values, 0 duplicate crime IDs.

Post-load Hive validation confirmed row counts matched across all 5 fact tables (each: 10,436,071 rows).

---

## Key Findings

**Q1 — Most Frequent Crime Types**
Anti-social behaviour dominated throughout most of the period, surging in 2020 during COVID-19 lockdowns. Violence & Sexual Offences overtook it from late 2024, becoming the most reported category by 2025. Seasonal peaks consistently occur in summer months.

**Q2 — Crime and Deprivation**
A strong positive correlation exists between deprivation level and crime volume. Very high deprivation areas recorded over 500,000 incidents in some years. Westminster, City of London, and Hillingdon were the top local hotspots.

**Q3 — Unsolved Cases**
Vehicle Crime has the highest unsolved volume across the decade, with a sharp spike in 2020. Violence & Sexual Offences are second. Both categories should be the focus of additional forensic and investigative resources.

**Q4 — Violent & Sexual Offences by Deprivation**
Incidents are strongly concentrated in High and Very High deprivation LSOAs. Specific hotspot areas include Westminster 018A, Newham 013G, and Lambeth 011B. Post-2021 volumes increased slightly as COVID restrictions lifted.

**Q5 — Police Strength vs. Solve Rates**
Police staffing remained broadly stable (2015–2025), yet crime solve rates declined sharply and consistently from around 2016 onwards. By 2025, solve rates had fallen to a fraction of their 2015 values, suggesting systemic challenges beyond headcount — including rising case complexity and resource allocation issues.

---



---

## Analysis & Visualizations

| Dashboard | Description |
|-----------|-------------|
| Crime Count per Month | Stacked bar chart showing monthly crime volumes by type (2015–2025) |
| Monthly Crime Reports by Type | Line chart tracking individual crime type trends over time |
| Crime Rate by Deprivation Level | Bar charts comparing annual crime counts across the 5 deprivation bands |
| Crime Rate by Location & Deprivation | LSOA-level breakdown showing local hotspots |
| Unsolved Crime Rate by Category | Table and bar chart of annual unsolved volumes per crime type |
| Unsolved Crime Rate Over Time | Area chart showing temporal evolution of unsolved cases |
| Violent & Sexual Offences by Deprivation | Stacked bar by deprivation level and time |
| Police Strength vs. Solve Rate | Dual-axis line chart comparing avg police staff with monthly solve rates |

---

## Recommendations

**Addressing Deprivation-Driven Crime:** Prioritise social investment (housing, employment, youth services) in high-deprivation boroughs; integrate real-time IMD data as it becomes available.

**Tackling High-Impact Categories:** Expand community policing for anti-social behaviour; develop specialist victim support units for Violence & Sexual Offences; improve evidence collection and tracking technology for Vehicle Crime.

**Improving Investigative Effectiveness:** Allocate additional forensic resources and create cross-borough taskforces for the highest-volume unsolved crime categories; invest in predictive analytics, ANPR, and CCTV.

**Smarter Resource Deployment:** Adopt seasonal staffing models to anticipate summer crime spikes; monitor staffing levels closely given the observed correlation with solve rate decline.

**Future Scaling:** Incorporate real-time data feeds (CCTV, IoT, emergency calls); add machine learning forecasting models; automate ETL orchestration with tools like Apache Airflow; expand dashboards to ward-level drilldowns.

---


---

## References

- data.police.uk. (2025). Police recorded crime open data. https://data.police.uk/data/archive/
- data.london.gov.uk. (2025). Metropolitan Police force strength. https://data.london.gov.uk/dataset/police-force-strength
- Greater London Authority. (2024). *Social deprivation statistics in London*. London Data Commission.
- Metropolitan Police Service. (2025). *Annual Report 2025*. London: MPS.
- Nimbus Intelligence. (2024). Kimball vs Inmon. https://nimbusintelligence.com/2024/01/unpacking-data-warehousing-philosophies-kimball-vs-inmon/
- Office for National Statistics. (2025). *Crime in England and Wales: London figures 2024/25*. ONS.
- UK Government. (2019). English Indices of Deprivation 2019. https://opendatacommunities.org/data/societal-wellbeing/imd2019/indices

---


---

