SELECT 'clients' AS table_name, COUNT(*) AS rows_count FROM clients
UNION ALL
SELECT 'loan_applications', COUNT(*) FROM loan_applications
UNION ALL
SELECT 'loans', COUNT(*) FROM loans
UNION ALL
SELECT 'payments', COUNT(*) FROM payments;

SELECT 
    MIN(application_date) AS min_application_date,
    MAX(application_date) AS max_application_date
FROM loan_applications;

SELECT 
    MIN(issue_date) AS min_issue_date,
    MAX(issue_date) AS max_issue_date
FROM loans;

SELECT 
    MIN(payment_date) AS min_payment_date,
    MAX(payment_date) AS max_payment_date
FROM payments;

SELECT COUNT(*) AS applications_without_client
FROM loan_applications AS la
LEFT JOIN clients AS c
    ON la.client_id = c.client_id
WHERE c.client_id IS NULL;

SELECT COUNT(*) AS loans_without_application
FROM loans AS l
LEFT JOIN loan_applications AS la
    ON l.application_id = la.application_id
WHERE la.application_id IS NULL;

SELECT COUNT(*) AS payments_without_loan
FROM payments AS p
LEFT JOIN loans AS l
    ON p.loan_id = l.loan_id
WHERE l.loan_id IS NULL;
