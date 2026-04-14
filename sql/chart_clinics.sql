-- Clinic Breakdown table
-- Output: one row per (month, clinic) with submissions, top area, top protocol, avg age
-- JOIN: Consultations → Users (clinic name) → Packages (protocol name)
-- NOTE: Location (city/suburb) is not yet in the Users table.
--       Add a `city` and `state` column to Users to enable the Submissions by Location chart.

WITH base AS (
  SELECT
    c._id,
    c.clinicId,
    c.recommandation,
    c.ageRange,
    DATE(c.createdAt)                                AS sub_date,
    FORMAT_DATE('%Y-%m', DATE(c.createdAt))          AS month,
    -- Midpoint of age range for avg age estimate
    CASE c.ageRange
      WHEN '18-25' THEN 21.5
      WHEN '26-35' THEN 30.5
      WHEN '36-45' THEN 40.5
      WHEN '46-59' THEN 52.5
      WHEN '60+'   THEN 65.0
      ELSE NULL
    END                                              AS age_midpoint,
    areasOfConcern_0_partName,  areasOfConcern_1_partName,
    areasOfConcern_2_partName,  areasOfConcern_3_partName,
    areasOfConcern_4_partName,  areasOfConcern_5_partName,
    areasOfConcern_6_partName,  areasOfConcern_7_partName,
    areasOfConcern_8_partName,  areasOfConcern_9_partName,
    areasOfConcern_10_partName
  FROM `aesthetiq-490506.Prod_data.Consultations` c
  WHERE c.isDeleted = FALSE
),

-- Unpivot areas for top-area-per-clinic calculation
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

-- Rank areas by frequency within each (month, clinic)
area_ranks AS (
  SELECT
    month, clinicId, area,
    COUNT(DISTINCT _id)  AS cnt,
    ROW_NUMBER() OVER (PARTITION BY month, clinicId ORDER BY COUNT(DISTINCT _id) DESC) AS rn
  FROM areas_unpivoted
  GROUP BY month, clinicId, area
),

-- Rank protocols by frequency within each (month, clinic)
protocol_ranks AS (
  SELECT
    b.month, b.clinicId, p.packageName,
    COUNT(*)             AS cnt,
    ROW_NUMBER() OVER (PARTITION BY b.month, b.clinicId ORDER BY COUNT(*) DESC) AS rn
  FROM base b
  JOIN `aesthetiq-490506.Prod_data.Packages` p ON b.recommandation = p._id
  GROUP BY b.month, b.clinicId, p.packageName
)

SELECT
  b.month,
  FORMAT_DATE('%B %Y', DATE_TRUNC(b.sub_date, MONTH))                          AS month_label,
  u.clinicName                                                                  AS clinic_name,
  COUNT(DISTINCT b._id)                                                         AS total_submissions,
  MAX(IF(ar.rn = 1, ar.area, NULL))                                             AS top_area,
  MAX(IF(pr.rn = 1, pr.packageName, NULL))                                      AS top_protocol,
  ROUND(AVG(b.age_midpoint), 0)                                                 AS avg_age,
  FORMAT_TIMESTAMP('%Y-%m-%dT%H:%M:%SZ', CURRENT_TIMESTAMP())                  AS last_updated
FROM base b
JOIN `aesthetiq-490506.Prod_data.Users` u
  ON b.clinicId = u._id
LEFT JOIN area_ranks ar
  ON b.month = ar.month AND b.clinicId = ar.clinicId
LEFT JOIN protocol_ranks pr
  ON b.month = pr.month AND b.clinicId = pr.clinicId
GROUP BY b.month, DATE_TRUNC(b.sub_date, MONTH), u.clinicName
ORDER BY b.month DESC, total_submissions DESC
