SELECT
  FORMAT_DATE('%Y-%m', DATE(createdAt))                                         AS month,
  FORMAT_DATE('%B %Y', DATE_TRUNC(DATE(createdAt), MONTH))                      AS month_label,
  DATE_TRUNC(DATE(createdAt), WEEK(MONDAY))                                     AS week_start,
  FORMAT_DATE('%b W%W', DATE(createdAt))                                        AS week_label,
  COUNT(*)                                                                      AS submissions
FROM `aesthetiq-490506.Prod_data.Consultations`
WHERE isDeleted = FALSE
GROUP BY month, month_label, week_start, week_label
ORDER BY month DESC, week_start
