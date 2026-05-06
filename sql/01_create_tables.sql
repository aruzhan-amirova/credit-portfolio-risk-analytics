CREATE TABLE clients (
    client_id INT PRIMARY KEY,
    birth_date DATE,
    gender VARCHAR(20),
    city VARCHAR(100),
    registration_date DATE,
    income NUMERIC(12, 2),
    employment_type VARCHAR(50),
    credit_score INT
);

CREATE TABLE loan_applications (
    application_id INT PRIMARY KEY,
    client_id INT,
    application_date DATE,
    product_name VARCHAR(100),
    requested_amount NUMERIC(12, 2),
    status VARCHAR(20),
    FOREIGN KEY (client_id) REFERENCES clients(client_id)
);

CREATE TABLE loans (
    loan_id INT PRIMARY KEY,
    application_id INT,
    client_id INT,
    issue_date DATE,
    product_name VARCHAR(100),
    loan_amount NUMERIC(12, 2),
    interest_rate NUMERIC(5, 2),
    term_months INT,
    FOREIGN KEY (application_id) REFERENCES loan_applications(application_id),
    FOREIGN KEY (client_id) REFERENCES clients(client_id)
);

CREATE TABLE payments (
    payment_id INT PRIMARY KEY,
    loan_id INT,
    payment_date DATE,
    paid_amount NUMERIC(12, 2),
    overdue_days INT,
    FOREIGN KEY (loan_id) REFERENCES loans(loan_id)
);
