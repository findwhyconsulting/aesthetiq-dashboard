WITH base AS (
  SELECT
    c._id,
    DATE(c.createdAt) AS sub_date,
    c.clinicId,
    u.clinicName      AS clinic_name,
    c.ageRange
  FROM `aesthetiq-490506.Prod_data.Consultations` c
  JOIN `aesthetiq-490506.Prod_data.Users` u ON c.clinicId = u._id
  WHERE c.isDeleted = FALSE
    AND c.ageRange IS NOT NULL AND c.ageRange != ''
),

clinic_totals AS (
  SELECT
    FORMAT_DATE('%Y-%m', sub_date) AS month,
    clinicId,
    COUNT(*)                       AS total
  FROM base
  GROUP BY month, clinicId
)

SELECT
  FORMAT_DATE('%Y-%m', b.sub_date)                              AS month,
  FORMAT_DATE('%B %Y', DATE_TRUNC(b.sub_date, MONTH))          AS month_label,
  b.clinicId,
  b.clinic_name,
  b.ageRange,
  COUNT(*)                                                      AS count,
  ROUND(COUNT(*) * 100.0 / ct.total, 1)                        AS pct
FROM base b
JOIN clinic_totals ct
  ON FORMAT_DATE('%Y-%m', b.sub_date) = ct.month
  AND b.clinicId = ct.clinicId
GROUP BY month, month_label, b.clinicId, b.clinic_name, b.ageRange, ct.total
ORDER BY month DESC, b.clinic_name, b.ageRange
