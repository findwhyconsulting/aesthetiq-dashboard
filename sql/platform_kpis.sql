WITH base AS (
  SELECT
    *,
    DATE(createdAt) AS submission_date,
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
)

SELECT
  FORMAT_DATE('%Y-%m', submission_date)                                          AS month,
  FORMAT_DATE('%B %Y', DATE_TRUNC(submission_date, MONTH))                       AS month_label,
  DATE_TRUNC(submission_date, MONTH)                                             AS period_start,
  LAST_DAY(submission_date, MONTH)                                               AS period_end,
  COUNT(*)                                                                       AS total_submissions,
  ROUND(COUNTIF(isConsultationSaved = TRUE) * 100.0 / NULLIF(COUNT(*), 0), 1)   AS completion_rate,
  ROUND(AVG(area_count), 1)                                                      AS avg_areas_per_consultation,
  COUNT(DISTINCT clinicId)                                                       AS active_clinics,
  FORMAT_TIMESTAMP('%Y-%m-%dT%H:%M:%SZ', CURRENT_TIMESTAMP())                   AS last_updated
FROM base
GROUP BY month, month_label, period_start, period_end
ORDER BY period_start DESC
