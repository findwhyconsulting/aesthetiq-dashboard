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

monthly_stats AS (
  SELECT
    FORMAT_DATE('%Y-%m', submission_date)                                          AS month,
    DATE_TRUNC(submission_date, MONTH)                                             AS period_start,
    LAST_DAY(submission_date, MONTH)                                               AS period_end,
    COUNT(*)                                                                       AS total_submissions,
    ROUND(COUNTIF(isConsultationSaved = TRUE) * 100.0 / NULLIF(COUNT(*), 0), 1)   AS completion_rate,
    ROUND(AVG(area_count), 1)                                                      AS avg_areas_per_consultation,
    COUNT(DISTINCT clinicId)                                                       AS active_clinics
  FROM base
  GROUP BY month, period_start, period_end
),

protocol_counts AS (
  SELECT
    FORMAT_DATE('%Y-%m', DATE(c.createdAt)) AS month,
    p.packageName,
    COUNT(*)                                AS cnt
  FROM `aesthetiq-490506.Prod_data.Consultations` c
  JOIN `aesthetiq-490506.Prod_data.Packages` p ON c.recommandation = p._id
  WHERE c.isDeleted = FALSE
  GROUP BY month, p.packageName
),

protocol_ranks AS (
  SELECT
    month,
    packageName,
    cnt,
    ROW_NUMBER() OVER (PARTITION BY month ORDER BY cnt DESC) AS rn
  FROM protocol_counts
),

top_protocols AS (
  SELECT month, packageName AS most_common_protocol
  FROM protocol_ranks
  WHERE rn = 1
)

SELECT
  m.month,
  FORMAT_DATE('%B %Y', m.period_start)                                           AS month_label,
  m.period_start,
  m.period_end,
  m.total_submissions,
  m.completion_rate,
  m.avg_areas_per_consultation,
  m.active_clinics,
  t.most_common_protocol,
  FORMAT_TIMESTAMP('%Y-%m-%dT%H:%M:%SZ', CURRENT_TIMESTAMP())                   AS last_updated
FROM monthly_stats m
LEFT JOIN top_protocols t ON m.month = t.month
ORDER BY m.period_start DESC
