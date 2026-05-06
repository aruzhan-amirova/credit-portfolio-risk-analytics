WITH not_doubling AS
(SELECT
l.loan_id,
MAX(
	CASE 
		WHEN p.overdue_days > 30 THEN 1 
		ELSE 0 END) AS cnt_30
FROM loans AS l
LEFT JOIN payments AS p
ON l.loan_id = p.loan_id
GROUP BY l.loan_id
),

dpd30 AS
(SELECT 
	DATE_TRUNC('month', l.issue_date)::date AS issue_month,
	l.product_name,
	COUNT(DISTINCT l.loan_id) AS issued_loans,
	COALESCE(SUM(l.loan_amount),0) AS total_issued_amount,
	COALESCE(COUNT(nd.cnt_30),0) AS dpd30_loans
FROM loans AS l
JOIN not_doubling AS nd
	ON l.loan_id = nd.loan_id
GROUP BY DATE_TRUNC('month', l.issue_date)::date,
l.product_name
)
SELECT
	issue_month,
	product_name,
	issued_loans,
	total_issued_amount,
	dpd30_loans,
	ROUND(dpd30.dpd30_loans::numeric / NULLIF(issued_loans, 0)
	,4) AS dpd30_rate
FROM dpd30
ORDER BY issue_month, product_name
