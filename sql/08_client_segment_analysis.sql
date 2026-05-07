WITH cnt_30 AS
(
SELECT
	l.loan_id,
	MAX (CASE
	WHEN p.overdue_days > 30 THEN 1 ELSE 0 END) AS dpd30
	FROM loans AS l
	LEFT JOIN payments AS p
	ON l.loan_id = p.loan_id
	GROUP BY l.loan_id),

score AS(
SELECT
	la.application_id,
	c.client_id,
	CASE
	WHEN c.credit_score BETWEEN 300 AND 499 
	THEN 'low score'
	WHEN c.credit_score BETWEEN 500 AND 649 
	THEN 'average score'
	WHEN c.credit_score BETWEEN 650 AND 749  
	THEN 'good score'
	WHEN c.credit_score >= 750 
	THEN 'high score'
	ELSE 'unknown'
	END AS score_segment,
	la.status,
	l.loan_id,
	l.loan_amount
FROM loan_applications AS la
LEFT JOIN loans AS l
	ON la.application_id = l.application_id
LEFT JOIN clients AS c
	ON c.client_id = la.client_id
),

up_to_dpd30 AS(
SELECT 
	s.score_segment,
	COUNT(s.application_id) AS applications,
	COUNT(s.application_id)
	FILTER(WHERE s.status = 'approved') AS approved_applications,
	COUNT(DISTINCT s.loan_id) AS issued_loans,
	COALESCE(SUM(loan_amount), 0) AS total_issued_amount,
	COALESCE(SUM(c.dpd30), 0) AS dpd30_loans	
FROM score AS s
LEFT JOIN cnt_30 AS c
	ON c.loan_id = s.loan_id
GROUP BY s.score_segment),

divisions AS(
SELECT
	score_segment,
	ROUND (approved_applications::numeric / NULLIF(applications, 0)
,4) AS approval_rate,
	ROUND (issued_loans::numeric / NULLIF(applications, 0)
,4) AS issue_rate,
	ROUND (dpd30_loans::numeric / NULLIF(issued_loans, 0)
,4) AS dpd30_rate
FROM up_to_dpd30
)

SELECT 
    u.score_segment,
    u.applications,
    u.approved_applications,
    u.issued_loans,
    u.total_issued_amount,
    u.dpd30_loans,
    d.approval_rate,
    d.issue_rate,
    d.dpd30_rate
FROM up_to_dpd30 AS u
JOIN divisions AS d
ON u.score_segment = d.score_segment
ORDER BY CASE 
  u.score_segment
	WHEN 'low_score' THEN 1
	WHEN 'average_score' THEN 1
	WHEN 'good_score' THEN 1
	WHEN 'high_score' THEN 1
ELSE 5 END;

	
