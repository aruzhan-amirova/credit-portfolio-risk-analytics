DROP VIEW IF EXISTS bi_monthly_funnel;
CREATE VIEW bi_monthly_funnel AS
  
SELECT
    DATE_TRUNC('month', la.application_date)::date AS application_month,
    COUNT(la.application_id) AS total_applications,
    COUNT(la.application_id) FILTER (WHERE la.status = 'approved') AS approved_applications,
    COUNT(l.loan_id) AS issued_loans,
    SUM(la.requested_amount) AS requested_amount,
    SUM(l.loan_amount) AS issued_amount,
    ROUND(COUNT(la.application_id) FILTER (
    WHERE la.status = 'approved')::numeric
    / NULLIF(COUNT(la.application_id), 0),4) AS approval_rate,
    ROUND(COUNT(l.loan_id)::numeric
    / NULLIF(COUNT(la.application_id), 0), 4) AS issue_rate
FROM loan_applications AS la
LEFT JOIN loans AS l
    ON la.application_id = l.application_id
GROUP BY
    DATE_TRUNC('month', la.application_date)::date;



DROP VIEW IF EXISTS bi_product_risk;
CREATE VIEW bi_product_risk AS

WITH loan_level AS (
SELECT
    l.loan_id,
    l.application_id,
    l.loan_amount,
    MAX(p.overdue_days) AS max_dpd
FROM loans AS l
LEFT JOIN payments AS p
    ON l.loan_id = p.loan_id
GROUP BY
    l.loan_id,
    l.application_id,
    l.loan_amount)
  
SELECT
    la.product_type,
    COUNT(la.application_id) AS total_applications,
    COUNT(la.application_id) FILTER (WHERE la.status = 'approved') AS approved_applications,
    COUNT(ll.loan_id) AS issued_loans,
    SUM(ll.loan_amount) AS issued_amount,
    COUNT(ll.loan_id) FILTER (WHERE ll.max_dpd >= 30) AS dpd30_loans,
    COALESCE(SUM(ll.loan_amount) FILTER (WHERE ll.max_dpd >= 30), 0) AS dpd30_amount,
    ROUND(COUNT(ll.loan_id) 
	FILTER (WHERE ll.max_dpd >= 30)::numeric
    / NULLIF(COUNT(ll.loan_id), 0),4) AS dpd30_rate,
    ROUND(SUM(ll.loan_amount) 
	FILTER (WHERE ll.max_dpd >= 30)::numeric
    / NULLIF(SUM(ll.loan_amount), 0),4) AS dpd30_amount_share
FROM loan_applications AS la
LEFT JOIN loan_level AS ll
    ON la.application_id = ll.application_id
GROUP BY
    la.product_type;



DROP VIEW IF EXISTS bi_client_segments;
CREATE VIEW bi_client_segments AS

WITH loan_level AS(
SELECT 
	l.application_id,
	l.loan_id, 
	l.loan_amount,
	MAX(p.overdue_days) AS max_dpd
FROM loans AS l
LEFT JOIN payments AS p
	ON l.loan_id = p.loan_id
GROUP BY
	l.application_id,
	l.loan_id, 
	l.loan_amount),
	
client_level AS(
SELECT
	client_id,
CASE
	WHEN credit_score >= 700
		THEN 'High score'
	WHEN credit_score >= 500
		THEN 'Medium score'
	ELSE 'Low score'
	END AS score_segment,
	credit_score,
	income,
	registration_date,
	birth_date
	FROM clients AS c
),

client_segment_stats AS(
SELECT
	score_segment,
	COUNT(DISTINCT client_id) AS client_count,
	AVG(credit_score) AS avg_credit_score, 
	AVG(income) AS avg_income,
	AVG(EXTRACT(YEAR FROM AGE
	(registration_date, birth_date::date))) AS avg_age
FROM client_level AS c
GROUP BY score_segment),

application_stats AS(
SELECT 
	cl.score_segment,
	COUNT(la.application_id) AS total_applications,
	COUNT(la.application_id) FILTER(WHERE la.status = 'approved') AS approved_applications,
	COUNT(ll.loan_id) AS issued_loans,
	COALESCE(SUM(ll.loan_amount), 0) AS issued_amount,
	COUNT(ll.loan_id) FILTER (WHERE ll.max_dpd >= 30) AS dpd30_loans,
   COALESCE(SUM(ll.loan_amount) FILTER (WHERE ll.max_dpd >= 30), 0) AS dpd30_amount,
	ROUND(COUNT(ll.loan_id) 
		FILTER (WHERE ll.max_dpd >= 30) :: numeric /
		NULLIF(COUNT(ll.loan_id), 0),4) AS dpd30_rate,
	ROUND(SUM(ll.loan_amount) 
		FILTER(WHERE ll.max_dpd >= 30) :: numeric / 
		NULLIF(COALESCE(SUM(ll.loan_amount), 0),0),4) AS dpd30_amount_share
FROM loan_applications AS la
LEFT JOIN loan_level AS ll
  ON la.application_id = ll.application_id
LEFT JOIN client_level AS cl
  ON cl.client_id = la.client_id
GROUP BY
	cl.score_segment)

SELECT 
	c.score_segment,
	client_count,
	c.avg_credit_score, 
	c.avg_income,
	c.avg_age,
	a.total_applications,
	a.approved_applications,
	a.issued_loans,
	a.issued_amount,
	a.dpd30_loans,
	a.dpd30_rate,
	a.dpd30_amount_share
FROM client_segment_stats AS c
LEFT JOIN application_stats AS a
  ON c.score_segment = a.score_segment;



DROP VIEW IF EXISTS bi_vintage_mob;
CREATE VIEW bi_vintage_mob AS
  
WITH mob_payments AS(
SELECT
	l.loan_id,
	l.loan_amount,
	DATE_TRUNC('month', l.issue_date)::date AS vintage_month,
	DATE_TRUNC('month', p.payment_date)::date AS payment_month,
	DATE_PART('year',AGE(p.payment_date, l.issue_date)) * 12 +
	DATE_PART('month', AGE(p.payment_date, l.issue_date))::int AS mob,
	p.overdue_days
FROM loans AS l
LEFT JOIN payments AS p
  ON l.loan_id = p.loan_id),

loan_mob_level AS(
SELECT 
	loan_id, 
	loan_amount,
	vintage_month,
	mob,
	MAX(overdue_days) AS max_dpd
FROM mob_payments
GROUP BY
	loan_id, 
	loan_amount,
	vintage_month,
	mob)

SELECT
	vintage_month,
	mob,
	COUNT(DISTINCT loan_id) AS issued_loans,
	COUNT(DISTINCT loan_id) FILTER (WHERE max_dpd >= 30) AS dpd30_loans,
	ROUND(COUNT(DISTINCT loan_id) 
		FILTER (WHERE max_dpd >= 30) :: numeric /
		NULLIF(COUNT(DISTINCT loan_id), 0), 4) AS dpd30_rate,
	COALESCE(SUM(loan_amount), 0) AS issued_amount,
	COALESCE(SUM(loan_amount) FILTER (WHERE max_dpd >= 30),0) AS dpd30_amount,
	ROUND(COALESCE(SUM(loan_amount)
		FILTER(WHERE max_dpd >= 30), 0) :: numeric / 
		NULLIF(COALESCE(SUM(loan_amount), 0),0),4) AS dpd30_amount_share
FROM loan_mob_level
GROUP BY
	vintage_month,
	mob;
