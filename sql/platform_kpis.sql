-- KPI metrics grouped by month.
-- Outputs one row per month: totals, rates, active clinics, most common protocol.
-- JOIN: Consultations → Packages (for most_common_protocol)

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
),

-- Most common protocol per month (rank 1 = top)
protocol_ranks AS (
  SELECT
    FORMAT_DATE('%Y-%m', DATE(c.createdAt)) AS month,
    p.packageName,
    COUNT(*)                                                            AS cnt,
    ROW_NUMBER() OVER (
      PARTITION BY FORMAT_DATE('%Y-%m', DATE(c.createdAt))
      ORDER BY COUNT(*) DESC
    )                                                                   AS rn
  FROM `aesthetiq-490506.Prod_data.Consultations` c
  JOIN `aesthetiq-490506.Prod_data.Packages` p ON c.recommandation = p._id
  WHERE c.isDeleted = FALSE
  GROUP BY month, p.packageName
)

SELECT
  FORMAT_DATE('%Y-%m', b.submission_date)                                        AS month,
  FORMAT_DATE('%B %Y', DATE_TRUNC(b.submission_date, MONTH))                     AS month_label,
  DATE_TRUNC(b.submission_date, MONTH)                                           AS period_start,
  LAST_DAY(b.submission_date, MONTH)                                             AS period_end,
  COUNT(*)                                                                       AS total_submissions,
  ROUND(COUNTIF(b.isConsultationSaved = TRUE) * 100.0 / NULLIF(COUNT(*), 0), 1) AS completion_rate,
  ROUND(AVG(b.area_count), 1)                                                    AS avg_areas_per_consultation,
  COUNT(DISTINCT b.clinicId)                                                     AS active_clinics,
  MAX(IF(pr.rn = 1, pr.packageName, NULL))                                       AS most_common_protocol,
  FORMAT_TIMESTAMP('%Y-%m-%dT%H:%M:%SZ', CURRENT_TIMESTAMP())                   AS last_updated
FROM base b
LEFT JOIN protocol_ranks pr
  ON FORMAT_DATE('%Y-%m', b.submission_date) = pr.month
GROUP BY
  FORMAT_DATE('%Y-%m', b.submission_date),
  DATE_TRUNC(b.submission_date, MONTH),
  LAST_DAY(b.submission_date, MONTH)
ORDER BY period_start DESC
