-- Age Group × Area of Concern Cross Analysis heatmap
-- Output: one row per (month, age_range, area_name)
-- pct = % of submissions in that age group that tapped that area
-- Source: Consultations only.

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

-- Denominator: total submissions per (month, age group)
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
