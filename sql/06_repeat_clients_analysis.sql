WITH first_credit AS (
SELECT
    loan_id,
    client_id,
    issue_date,
    loan_amount,
	ROW_NUMBER() OVER (
    PARTITION BY client_id
    ORDER BY issue_date, loan_id) AS rn
FROM loans
)

SELECT 
	DATE_TRUNC('month', issue_date)::date AS issue_month,
	COUNT(DISTINCT loan_id) AS issued_loans,
	COUNT(DISTINCT client_id) AS unique_clients,
	COUNT(DISTINCT client_id) FILTER (WHERE rn = 1) AS new_clients,
	COUNT(DISTINCT client_id) FILTER (WHERE rn > 1) AS repeat_clients,
	COALESCE(SUM(loan_amount), 0) AS total_issued_amount,
	ROUND(AVG(loan_amount), 2) AS avg_loan_amount,
	ROUND(COUNT(DISTINCT client_id) FILTER (WHERE rn > 1)::numeric / NULLIF(COUNT(DISTINCT client_id), 0), 
	4) AS repeat_client_share
FROM first_credit 
GROUP BY DATE_TRUNC('month', issue_date)::date
ORDER BY issue_month;
