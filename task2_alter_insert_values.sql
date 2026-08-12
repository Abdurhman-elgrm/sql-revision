-- SQL Server does NOT allow the keyword "COLUMN" when ADDING columns
ALTER TABLE employees ADD commission_pct DECIMAL(4,2);

-- Column renaming in SQL Server uses the sp_rename system stored procedure
EXEC sp_rename 'employees.commission_pct', 'commission_rate', 'COLUMN';

INSERT INTO departments (dept_name, region) VALUES
    ('Sales', 'East'),
    ('Engineering', 'West');

INSERT INTO employees (name, dept_id, manager_id, salary, hire_date) VALUES
    ('Alice Hassan', 1, NULL, 90000, '2020-01-15'),
    ('Omar Said',    1, 1,    55000, '2021-03-01')

INSERT INTO customers (name, city, segment) VALUES
    ('Nour Fathy', 'Cairo', 'Retail'),
    ('Karim Adel', 'Giza', 'Enterprise'),
    ('Laila Samir', 'Cairo', 'Retail');


INSERT INTO orders (emp_id, customer_id, order_date, amount, status) VALUES
    (1, 1, '2024-01-05', 1200.00, 'completed'),
    (1, 2, '2024-01-20', 4300.00, 'completed'),
    (2, 1, '2024-02-02',  800.00, 'cancelled'),
    (2, 3, '2024-02-15', 2200.00, 'completed'),
    (1, 3, '2024-03-01', 1500.00, 'pending');