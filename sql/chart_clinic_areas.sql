WITH base AS (
  SELECT
    c._id,
    DATE(c.createdAt) AS sub_date,
    c.clinicId,
    u.clinicName      AS clinic_name,
    c.areasOfConcern_0_partName,  c.areasOfConcern_1_partName,
    c.areasOfConcern_2_partName,  c.areasOfConcern_3_partName,
    c.areasOfConcern_4_partName,  c.areasOfConcern_5_partName,
    c.areasOfConcern_6_partName,  c.areasOfConcern_7_partName,
    c.areasOfConcern_8_partName,  c.areasOfConcern_9_partName,
    c.areasOfConcern_10_partName
  FROM `aesthetiq-490506.Prod_data.Consultations` c
  JOIN `aesthetiq-490506.Prod_data.Users` u ON c.clinicId = u._id
  WHERE c.isDeleted = FALSE
),

areas_unpivoted AS (
  SELECT _id, sub_date, clinicId, clinic_name, area
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

clinic_totals AS (
  SELECT
    FORMAT_DATE('%Y-%m', sub_date) AS month,
    clinicId,
    COUNT(DISTINCT _id)            AS total_submissions
  FROM base
  GROUP BY month, clinicId
)

SELECT
  FORMAT_DATE('%Y-%m', au.sub_date)                                              AS month,
  FORMAT_DATE('%B %Y', DATE_TRUNC(au.sub_date, MONTH))                          AS month_label,
  au.clinicId,
  au.clinic_name,
  au.area                                                                        AS area_name,
  COUNT(DISTINCT au._id)                                                         AS count,
  ROUND(COUNT(DISTINCT au._id) * 100.0 / ct.total_submissions, 1)               AS pct
FROM areas_unpivoted au
JOIN clinic_totals ct
  ON FORMAT_DATE('%Y-%m', au.sub_date) = ct.month
  AND au.clinicId = ct.clinicId
GROUP BY month, month_label, au.clinicId, au.clinic_name, au.area, ct.total_submissions
ORDER BY month DESC, au.clinic_name, pct DESC
