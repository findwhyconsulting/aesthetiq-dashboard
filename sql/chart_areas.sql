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

monthly_totals AS (
  SELECT
    FORMAT_DATE('%Y-%m', sub_date) AS month,
    COUNT(DISTINCT _id)            AS total_submissions
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
