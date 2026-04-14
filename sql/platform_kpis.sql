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

period_defs AS (
  SELECT 'all_time'     AS period, DATE('2000-01-01')                         AS period_start
  UNION ALL
  SELECT 'last_90_days' AS period, DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)  AS period_start
  UNION ALL
  SELECT 'last_30_days' AS period, DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)  AS period_start
  UNION ALL
  SELECT 'last_7_days'  AS period, DATE_SUB(CURRENT_DATE(), INTERVAL 7  DAY)  AS period_start
)

SELECT
  p.period,
  p.period_start,
  CURRENT_DATE()                                                                 AS period_end,
  COUNT(*)                                                                       AS total_submissions,
  ROUND(COUNTIF(b.isConsultationSaved = TRUE) * 100.0 / NULLIF(COUNT(*), 0), 1) AS completion_rate,
  ROUND(AVG(b.area_count), 1)                                                    AS avg_areas_per_consultation,
  FORMAT_TIMESTAMP('%Y-%m-%dT%H:%M:%SZ', CURRENT_TIMESTAMP())                   AS last_updated
FROM period_defs p
JOIN base b ON b.submission_date >= p.period_start
GROUP BY p.period, p.period_start
ORDER BY
  CASE p.period
    WHEN 'all_time'     THEN 1
    WHEN 'last_90_days' THEN 2
    WHEN 'last_30_days' THEN 3
    WHEN 'last_7_days'  THEN 4
  END
