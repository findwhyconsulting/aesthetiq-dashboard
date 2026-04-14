WITH base AS (
  SELECT
    _id,
    DATE(createdAt) AS sub_date,
    areasOfConcern_0_partName,  areasOfConcern_1_partName,
    areasOfConcern_2_partName,  areasOfConcern_3_partName,
    areasOfConcern_4_partName,  areasOfConcern_5_partName,
    areasOfConcern_6_partName,  areasOfConcern_7_partName,
    areasOfConcern_8_partName,  areasOfConcern_9_partName,
    areasOfConcern_10_partName,
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
  FROM `aesthetiq-490506.Prod_data.Consultations`
  WHERE isDeleted = FALSE
),

combos AS (
  SELECT
    _id,
    sub_date,
    area_count,
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
    ) AS area_combo
  FROM base
  WHERE area_count >= 2
),

monthly_totals AS (
  SELECT FORMAT_DATE('%Y-%m', sub_date) AS month, COUNT(*) AS total_multi
  FROM combos
  GROUP BY month
)

SELECT
  FORMAT_DATE('%Y-%m', c.sub_date)                              AS month,
  FORMAT_DATE('%B %Y', DATE_TRUNC(c.sub_date, MONTH))          AS month_label,
  c.area_combo,
  COUNT(*)                                                      AS count,
  ROUND(COUNT(*) * 100.0 / mt.total_multi, 1)                  AS pct
FROM combos c
JOIN monthly_totals mt ON FORMAT_DATE('%Y-%m', c.sub_date) = mt.month
GROUP BY month, month_label, c.area_combo, mt.total_multi
ORDER BY month DESC, count DESC
