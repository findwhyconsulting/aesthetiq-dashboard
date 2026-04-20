WITH base AS (
  SELECT
    c._id,
    c.clinicId,
    c.recommandation,
    c.isConsultationSaved,
    DATE(c.createdAt)                                AS sub_date,
    FORMAT_DATE('%Y-%m', DATE(c.createdAt))          AS month,
    CASE c.ageRange
      WHEN '18-25' THEN 21.5
      WHEN '26-35' THEN 30.5
      WHEN '36-45' THEN 40.5
      WHEN '46-59' THEN 52.5
      WHEN '60+'   THEN 65.0
      ELSE NULL
    END                                              AS age_midpoint,
    (CASE WHEN c.areasOfConcern_0_partName  != '' THEN 1 ELSE 0 END) +
    (CASE WHEN c.areasOfConcern_1_partName  != '' THEN 1 ELSE 0 END) +
    (CASE WHEN c.areasOfConcern_2_partName  != '' THEN 1 ELSE 0 END) +
    (CASE WHEN c.areasOfConcern_3_partName  != '' THEN 1 ELSE 0 END) +
    (CASE WHEN c.areasOfConcern_4_partName  != '' THEN 1 ELSE 0 END) +
    (CASE WHEN c.areasOfConcern_5_partName  != '' THEN 1 ELSE 0 END) +
    (CASE WHEN c.areasOfConcern_6_partName  != '' THEN 1 ELSE 0 END) +
    (CASE WHEN c.areasOfConcern_7_partName  != '' THEN 1 ELSE 0 END) +
    (CASE WHEN c.areasOfConcern_8_partName  != '' THEN 1 ELSE 0 END) +
    (CASE WHEN c.areasOfConcern_9_partName  != '' THEN 1 ELSE 0 END) +
    (CASE WHEN c.areasOfConcern_10_partName != '' THEN 1 ELSE 0 END) AS area_count,
    c.areasOfConcern_0_partName,  c.areasOfConcern_1_partName,
    c.areasOfConcern_2_partName,  c.areasOfConcern_3_partName,
    c.areasOfConcern_4_partName,  c.areasOfConcern_5_partName,
    c.areasOfConcern_6_partName,  c.areasOfConcern_7_partName,
    c.areasOfConcern_8_partName,  c.areasOfConcern_9_partName,
    c.areasOfConcern_10_partName
  FROM `aesthetiq-490506.Prod_data.Consultations` c
  WHERE c.isDeleted = FALSE
),

areas_unpivoted AS (
  SELECT _id, clinicId, month, area
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

area_counts AS (
  SELECT month, clinicId, area, COUNT(DISTINCT _id) AS cnt
  FROM areas_unpivoted
  GROUP BY month, clinicId, area
),

area_ranks AS (
  SELECT
    month, clinicId, area, cnt,
    ROW_NUMBER() OVER (PARTITION BY month, clinicId ORDER BY cnt DESC) AS rn
  FROM area_counts
),

protocol_counts AS (
  SELECT b.month, b.clinicId, p.packageName, COUNT(*) AS cnt
  FROM base b
  JOIN `aesthetiq-490506.Prod_data.Packages` p ON b.recommandation = p._id
  GROUP BY b.month, b.clinicId, p.packageName
),

protocol_ranks AS (
  SELECT
    month, clinicId, packageName, cnt,
    ROW_NUMBER() OVER (PARTITION BY month, clinicId ORDER BY cnt DESC) AS rn
  FROM protocol_counts
),

clinic_monthly_stats AS (
  SELECT
    month,
    DATE_TRUNC(sub_date, MONTH)                                                    AS period_start,
    clinicId,
    COUNT(DISTINCT _id)                                                            AS total_submissions,
    ROUND(COUNTIF(isConsultationSaved = TRUE) * 100.0 / NULLIF(COUNT(*), 0), 1)   AS completion_rate,
    ROUND(AVG(area_count), 1)                                                      AS avg_areas_per_consultation,
    ROUND(AVG(age_midpoint), 0)                                                    AS avg_age
  FROM base
  GROUP BY month, period_start, clinicId
),

top_areas AS (
  SELECT month, clinicId, area AS top_area
  FROM area_ranks
  WHERE rn = 1
),

top_protocols AS (
  SELECT month, clinicId, packageName AS top_protocol
  FROM protocol_ranks
  WHERE rn = 1
)

SELECT
  cms.month,
  FORMAT_DATE('%B %Y', cms.period_start)                                         AS month_label,
  cms.clinicId,
  u.clinicName                                                                   AS clinic_name,
  cms.total_submissions,
  cms.completion_rate,
  cms.avg_areas_per_consultation,
  ta.top_area,
  tp.top_protocol,
  cms.avg_age,
  FORMAT_TIMESTAMP('%Y-%m-%dT%H:%M:%SZ', CURRENT_TIMESTAMP())                   AS last_updated
FROM clinic_monthly_stats cms
JOIN `aesthetiq-490506.Prod_data.Users` u ON cms.clinicId = u._id
LEFT JOIN top_areas ta     ON cms.month = ta.month     AND cms.clinicId = ta.clinicId
LEFT JOIN top_protocols tp ON cms.month = tp.month     AND cms.clinicId = tp.clinicId
ORDER BY cms.month DESC, cms.total_submissions DESC
