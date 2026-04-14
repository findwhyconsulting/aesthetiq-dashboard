-- Demographics — two result sets sharing the same base CTE.
-- Run Query A for Age Distribution chart.
-- Run Query B for Age Group × Area of Concern cross-analysis heatmap.
-- Source: Consultations only.

-- ═════════════════════════════════════════════════════════════════════════════
-- QUERY A — Age Distribution
-- Output: one row per (month, age_range) with count and %
-- ageRange values in data: "18-25", "26-35", "36-45", "46-59", "60+"
-- ═════════════════════════════════════════════════════════════════════════════

WITH base AS (
  SELECT
    _id,
    DATE(createdAt) AS sub_date,
    ageRange
  FROM `aesthetiq-490506.Prod_data.Consultations`
  WHERE isDeleted = FALSE
    AND ageRange IS NOT NULL
    AND ageRange != ''
),

monthly_totals AS (
  SELECT FORMAT_DATE('%Y-%m', sub_date) AS month, COUNT(*) AS total
  FROM base
  GROUP BY month
)

SELECT
  FORMAT_DATE('%Y-%m', b.sub_date)                              AS month,
  FORMAT_DATE('%B %Y', DATE_TRUNC(b.sub_date, MONTH))          AS month_label,
  b.ageRange,
  COUNT(*)                                                      AS count,
  ROUND(COUNT(*) * 100.0 / mt.total, 1)                        AS pct
FROM base b
JOIN monthly_totals mt ON FORMAT_DATE('%Y-%m', b.sub_date) = mt.month
GROUP BY month, month_label, b.ageRange, mt.total
ORDER BY month DESC, b.ageRange


-- ═════════════════════════════════════════════════════════════════════════════
-- QUERY B — Age Group × Area of Concern Cross Analysis
-- Output: one row per (month, age_range, area_name)
-- pct = % of submissions in that age group that tapped that area
-- ═════════════════════════════════════════════════════════════════════════════

/*
WITH base AS (
  SELECT
    _id,
    DATE(createdAt) AS sub_date,
    ageRange,
    areasOfConcern_0_partName,  areasOfConcern_1_partName,
    areasOfConcern_2_partName,  areasOfConcern_3_partName,
    areasOfConcern_4_partName,  areasOfConcern_5_partName,
    areasOfConcern_6_partName,  areasOfConcern_7_partName,
    areasOfConcern_8_partName,  areasOfConcern_9_partName,
    areasOfConcern_10_partName
  FROM `aesthetiq-490506.Prod_data.Consultations`
  WHERE isDeleted = FALSE
    AND ageRange IS NOT NULL AND ageRange != ''
),

areas_unpivoted AS (
  SELECT _id, sub_date, ageRange, area
  FROM base
  CROSS JOIN UNNEST([
    areasOfConcern_0_partName,  areasOfConcern_1_partName,
    areasOfConcern_2_partName,  areasOfConcern_3_partName,
    areasOfConcern_4_partName,  areasOfConcern_5_partName,
    areasOfConcern_6_partName,  areasOfConcern_7_partName,
    areasOfConcern_8_partName,  areasOfConcern_9_partName,
    areasOfConcern_10_partName
  ]) AS area
  WHERE area IS NOT NULL AND area != ''
),

-- Total submissions per (month, age group) — the denominator
age_group_totals AS (
  SELECT
    FORMAT_DATE('%Y-%m', sub_date) AS month,
    ageRange,
    COUNT(DISTINCT _id)            AS total_in_group
  FROM base
  GROUP BY month, ageRange
)

SELECT
  FORMAT_DATE('%Y-%m', au.sub_date)                                              AS month,
  FORMAT_DATE('%B %Y', DATE_TRUNC(au.sub_date, MONTH))                          AS month_label,
  au.ageRange,
  au.area                                                                        AS area_name,
  COUNT(DISTINCT au._id)                                                         AS count,
  ROUND(COUNT(DISTINCT au._id) * 100.0 / agt.total_in_group, 1)                 AS pct
FROM areas_unpivoted au
JOIN age_group_totals agt
  ON FORMAT_DATE('%Y-%m', au.sub_date) = agt.month
  AND au.ageRange = agt.ageRange
GROUP BY month, month_label, au.ageRange, au.area, agt.total_in_group
ORDER BY month DESC, au.ageRange, pct DESC
*/
