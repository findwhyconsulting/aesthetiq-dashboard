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
