-- Areas of Concern — two result sets sharing the same base CTE.
-- Run Query A for the Face Map chart.
-- Run Query B for the Top Area Combinations chart.
-- Source: Consultations only.

-- ─────────────────────────────────────────────────────────────────────────────
-- SHARED BASE (copy this CTE into both queries below when running separately)
-- ─────────────────────────────────────────────────────────────────────────────
-- WITH base AS (
--   SELECT _id, DATE(createdAt) AS sub_date, ...areasOfConcern fields...
--   FROM `aesthetiq-490506.Prod_data.Consultations` WHERE isDeleted = FALSE
-- )

-- ═════════════════════════════════════════════════════════════════════════════
-- QUERY A — Areas of Concern Face Map
-- Output: one row per (month, area_name) with count and % of submissions
-- ═════════════════════════════════════════════════════════════════════════════

WITH base AS (
  SELECT
    _id,
    DATE(createdAt) AS sub_date,
    areasOfConcern_0_partName,
    areasOfConcern_1_partName,
    areasOfConcern_2_partName,
    areasOfConcern_3_partName,
    areasOfConcern_4_partName,
    areasOfConcern_5_partName,
    areasOfConcern_6_partName,
    areasOfConcern_7_partName,
    areasOfConcern_8_partName,
    areasOfConcern_9_partName,
    areasOfConcern_10_partName
  FROM `aesthetiq-490506.Prod_data.Consultations`
  WHERE isDeleted = FALSE
),

-- Unpivot all 11 area columns into individual rows
areas_unpivoted AS (
  SELECT _id, sub_date, area
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

-- Total submissions per month (denominator for %)
monthly_totals AS (
  SELECT
    FORMAT_DATE('%Y-%m', sub_date)   AS month,
    COUNT(DISTINCT _id)              AS total_submissions
  FROM base
  GROUP BY month
)

SELECT
  FORMAT_DATE('%Y-%m', au.sub_date)                                              AS month,
  FORMAT_DATE('%B %Y', DATE_TRUNC(au.sub_date, MONTH))                          AS month_label,
  au.area                                                                        AS area_name,
  COUNT(DISTINCT au._id)                                                         AS count,
  ROUND(COUNT(DISTINCT au._id) * 100.0 / mt.total_submissions, 1)               AS pct
FROM areas_unpivoted au
JOIN monthly_totals mt ON FORMAT_DATE('%Y-%m', au.sub_date) = mt.month
GROUP BY month, month_label, au.area, mt.total_submissions
ORDER BY month DESC, pct DESC


-- ═════════════════════════════════════════════════════════════════════════════
-- QUERY B — Top Area Combinations
-- Output: one row per (month, sorted_area_combo) with count and %
-- Only includes consultations with 2+ areas selected
-- ═════════════════════════════════════════════════════════════════════════════

/*
WITH base AS (
  SELECT
    _id,
    DATE(createdAt) AS sub_date,
    areasOfConcern_0_partName,  areasOfConcern_1_partName,
    areasOfConcern_2_partName,  areasOfConcern_3_partName,
    areasOfConcern_4_partName,  areasOfConcern_5_partName,
    areasOfConcern_6_partName,  areasOfConcern_7_partName,
    areasOfConcern_8_partName,  areasOfConcern_9_partName,
    areasOfConcern_10_partName
  FROM `aesthetiq-490506.Prod_data.Consultations`
  WHERE isDeleted = FALSE
),

-- Build a sorted combo string per consultation (alphabetical order)
combos AS (
  SELECT
    _id,
    sub_date,
    ARRAY_TO_STRING(
      ARRAY(
        SELECT a
        FROM UNNEST([
          areasOfConcern_0_partName,  areasOfConcern_1_partName,
          areasOfConcern_2_partName,  areasOfConcern_3_partName,
          areasOfConcern_4_partName,  areasOfConcern_5_partName,
          areasOfConcern_6_partName,  areasOfConcern_7_partName,
          areasOfConcern_8_partName,  areasOfConcern_9_partName,
          areasOfConcern_10_partName
        ]) AS a
        WHERE a IS NOT NULL AND a != ''
        ORDER BY a
      ),
      ' + '
    )                              AS area_combo,
    (CASE WHEN areasOfConcern_0_partName  != '' THEN 1 ELSE 0 END) +
    (CASE WHEN areasOfConcern_1_partName  != '' THEN 1 ELSE 0 END) +
    (CASE WHEN areasOfConcern_2_partName  != '' THEN 1 ELSE 0 END) +
    (CASE WHEN areasOfConcern_3_partName  != '' THEN 1 ELSE 0 END) +
    (CASE WHEN areasOfConcern_4_partName  != '' THEN 1 ELSE 0 END) +
    (CASE WHEN areasOfConcern_5_partName  != '' THEN 1 ELSE 0 END) +
    (CASE WHEN areasOfConcern_6_partName  != '' THEN 1 ELSE 0 END) +
    (CASE WHEN areasOfConcern_7_partName  != '' THEN 1 ELSE 0 END) +
    (CASE WHEN areasOfConcern_8_partName  != '' THEN 1 ELSE 0 END) +
    (CASE WHEN areasOfConcern_9_partName  != '' THEN 1 ELSE 0 END) +
    (CASE WHEN areasOfConcern_10_partName != '' THEN 1 ELSE 0 END) AS area_count
  FROM base
),

monthly_totals AS (
  SELECT FORMAT_DATE('%Y-%m', sub_date) AS month, COUNT(*) AS total_multi
  FROM combos WHERE area_count >= 2
  GROUP BY month
)

SELECT
  FORMAT_DATE('%Y-%m', c.sub_date)                                              AS month,
  FORMAT_DATE('%B %Y', DATE_TRUNC(c.sub_date, MONTH))                          AS month_label,
  c.area_combo,
  COUNT(*)                                                                      AS count,
  ROUND(COUNT(*) * 100.0 / mt.total_multi, 1)                                  AS pct
FROM combos c
JOIN monthly_totals mt ON FORMAT_DATE('%Y-%m', c.sub_date) = mt.month
WHERE c.area_count >= 2
GROUP BY month, month_label, c.area_combo, mt.total_multi
ORDER BY month DESC, count DESC
*/
