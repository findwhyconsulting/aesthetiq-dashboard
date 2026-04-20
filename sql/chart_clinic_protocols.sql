WITH protocol_counts AS (
  SELECT
    FORMAT_DATE('%Y-%m', DATE(c.createdAt))                     AS month,
    FORMAT_DATE('%B %Y', DATE_TRUNC(DATE(c.createdAt), MONTH))  AS month_label,
    c.clinicId,
    u.clinicName                                                AS clinic_name,
    p.packageName                                               AS protocol,
    COUNT(*)                                                    AS count
  FROM `aesthetiq-490506.Prod_data.Consultations` c
  JOIN `aesthetiq-490506.Prod_data.Packages` p ON c.recommandation = p._id
  JOIN `aesthetiq-490506.Prod_data.Users` u    ON c.clinicId       = u._id
  WHERE c.isDeleted = FALSE
  GROUP BY month, month_label, c.clinicId, clinic_name, p.packageName
),

clinic_totals AS (
  SELECT month, clinicId, SUM(count) AS total
  FROM protocol_counts
  GROUP BY month, clinicId
)

SELECT
  pc.month,
  pc.month_label,
  pc.clinicId,
  pc.clinic_name,
  pc.protocol,
  pc.count,
  ROUND(pc.count * 100.0 / ct.total, 1) AS pct
FROM protocol_counts pc
JOIN clinic_totals ct
  ON pc.month = ct.month AND pc.clinicId = ct.clinicId
ORDER BY pc.month DESC, pc.clinic_name, pc.count DESC
