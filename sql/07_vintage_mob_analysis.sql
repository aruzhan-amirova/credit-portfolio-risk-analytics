WITH mob_payments AS(
SELECT
	l.loan_id,
	DATE_TRUNC('month', l.issue_date)::date AS issue_month,
	DATE_PART('year', AGE(p.payment_date, l.issue_date)) * 12 
	+ (DATE_PART('month', AGE(p.payment_date, l.issue_date)))::int AS mob,
	p.overdue_days
FROM loans AS l
LEFT JOIN payments AS p
	ON l.loan_id = p.loan_id
WHERE p.payment_date IS NOT NULL
),

first_dpd30 AS (
SELECT
	loan_id,
	issue_month,
	MIN(mob) FILTER (WHERE overdue_days > 30) AS first_dpd30_mob
FROM mob_payments
GROUP BY 
	loan_id,
	issue_month
),

vintage AS(
SELECT 
	DATE_TRUNC('month', issue_date)::date AS issue_month,
	COUNT(loan_id) AS issued_loans
FROM loans
GROUP BY DATE_TRUNC('month', issue_date)::date
),

mob_list AS(
SELECT DISTINCT
	issue_month,
	mob
FROM mob_payments
WHERE mob >= 1
)

SELECT
	ml.issue_month,
	ml.mob,
	v.issued_loans,
	COUNT(fd.loan_id)
		FILTER(WHERE fd.first_dpd30_mob IS NOT NULL
		AND fd.first_dpd30_mob <= ml.mob) AS dpd30_loans,
	ROUND(COUNT(fd.loan_id)
		FILTER(WHERE fd.first_dpd30_mob IS NOT NULL
		AND fd.first_dpd30_mob <= ml.mob)::numeric /
	NULLIF(v.issued_loans, 0), 4) AS dpd30_rate
FROM mob_list AS ml
JOIN vintage AS v
	ON ml.issue_month = v.issue_month
LEFT JOIN first_dpd30 AS fd
	ON ml.issue_month = fd.issue_month
GROUP BY 
	ml.issue_month,
	ml.mob,
	v.issued_loans
ORDER BY
	ml.issue_month,
	ml.mob
