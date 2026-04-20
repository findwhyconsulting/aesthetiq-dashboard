SELECT
  FORMAT_DATE('%Y-%m', DATE(c.createdAt))                                         AS month,
  FORMAT_DATE('%B %Y', DATE_TRUNC(DATE(c.createdAt), MONTH))                      AS month_label,
  c.clinicId,
  u.clinicName                                                                    AS clinic_name,
  DATE_TRUNC(DATE(c.createdAt), WEEK(MONDAY))                                     AS week_start,
  FORMAT_DATE('%b W%W', DATE(c.createdAt))                                        AS week_label,
  COUNT(*)                                                                        AS submissions
FROM `aesthetiq-490506.Prod_data.Consultations` c
JOIN `aesthetiq-490506.Prod_data.Users` u ON c.clinicId = u._id
WHERE c.isDeleted = FALSE
GROUP BY month, month_label, c.clinicId, clinic_name, week_start, week_label
ORDER BY month DESC, clinic_name, week_start
