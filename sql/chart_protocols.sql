-- Protocol Recommendations — donut chart
-- Output: one row per (month, protocol_name) with count and %
-- JOIN: Consultations → Packages via Consultations.recommandation = Packages._id

WITH protocol_counts AS (
  SELECT
    FORMAT_DATE('%Y-%m', DATE(c.createdAt))             AS month,
    FORMAT_DATE('%B %Y', DATE_TRUNC(DATE(c.createdAt), MONTH)) AS month_label,
    p.packageName                                        AS protocol,
    COUNT(*)                                             AS count
  FROM `aesthetiq-490506.Prod_data.Consultations` c
  JOIN `aesthetiq-490506.Prod_data.Packages` p
    ON c.recommandation = p._id
  WHERE c.isDeleted = FALSE
  GROUP BY month, month_label, p.packageName
),

monthly_totals AS (
  SELECT month, SUM(count) AS total
  FROM protocol_counts
  GROUP BY month
)

SELECT
  pc.month,
  pc.month_label,
  pc.protocol,
  pc.count,
  ROUND(pc.count * 100.0 / mt.total, 1) AS pct
FROM protocol_counts pc
JOIN monthly_totals mt ON pc.month = mt.month
ORDER BY pc.month DESC, pc.count DESC
