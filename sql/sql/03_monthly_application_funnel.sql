WITH monthly_funnel AS
(
SELECT 
  DATE_TRUNC('month', la.application_date)::date AS application_month,
  COUNT(la.application_id) AS applications,
  COUNT(la.application_id) FILTER (WHERE la.status = 'approved') AS approved_applications,
  COUNT(DISTINCT l.loan_id) AS issued_loans,
  SUM(la.requested_amount) AS total_requested_amount,
  COALESCE(SUM(l.loan_amount),0) AS total_issued_amount
FROM loan_applications AS la
LEFT JOIN loans AS l
ON la.application_id = l.application_id
GROUP BY DATE_TRUNC('month', la.application_date)::date
)
SELECT
  application_month,
  applications,
  approved_applications,
  issued_loans,
  total_requested_amount,
  total_issued_amount,
  ROUND(
  approved_applications::numeric / NULLIF(applications, 0),
  4) AS approval_rate,
  ROUND(
  issued_loans::numeric/ NULLIF(applications, 0),
  4) AS issue_rate
FROM monthly_funnel 
ORDER BY application_month
