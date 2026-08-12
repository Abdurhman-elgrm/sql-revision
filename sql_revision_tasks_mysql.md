# SQL Essentials for Enterprise Analytics — Revision Tasks (SQL Server / T-SQL Edition)

This set starts from creating the database itself and builds all the way up to window functions[cite: 1]. Work through it in order — later parts (JOINs, CTEs, window functions) reuse the exact schema and data you create in Part 0[cite: 1].

**Syntax is Microsoft SQL Server (T-SQL)**[cite: 1]. Places where SQL Server differs from standard SQL or MySQL (such as `IDENTITY` columns, `TOP`, native `FULL OUTER JOIN`, `GROUPING SETS`, and `sp_rename`) are highlighted in the commentary[cite: 1].

---

## PART 0 — Creating the Database & Tables (Foundations)

### Task 1: Create a database
Create a new database called `company_db` and switch to it[cite: 1].

**Answer:**
```sql
CREATE DATABASE company_db;
GO
USE company_db;
GO
```

### Task 2: Create a table with data types & constraints
Create a `departments` table with an auto-incrementing primary key[cite: 1].

**Answer:**
```sql
CREATE TABLE departments (
    dept_id     INT IDENTITY(1,1) PRIMARY KEY,
    dept_name   VARCHAR(50) NOT NULL,
    region      VARCHAR(50)
);
```

### Task 3: Create a table with a foreign key
Create an `employees` table that references `departments`, including a self-referencing manager column[cite: 1].

**Answer:**
```sql
CREATE TABLE employees (
    emp_id      INT IDENTITY(1,1) PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    dept_id     INT,
    manager_id  INT,
    salary      DECIMAL(10,2) CHECK (salary >= 0),
    hire_date   DATE NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id),
    FOREIGN KEY (manager_id) REFERENCES employees(emp_id)   -- self-referencing FK
);
```

### Task 4: Create the remaining tables
Create `customers` and `orders`, with `orders` referencing both `employees` and `customers`[cite: 1].

**Answer:**
```sql
CREATE TABLE customers (
    customer_id INT IDENTITY(1,1) PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    city        VARCHAR(50),
    segment     VARCHAR(20)
);

CREATE TABLE orders (
    order_id     INT IDENTITY(1,1) PRIMARY KEY,
    emp_id       INT,
    customer_id  INT,
    order_date   DATE NOT NULL,
    amount       DECIMAL(10,2) CHECK (amount >= 0),
    status       VARCHAR(20) DEFAULT 'pending',
    FOREIGN KEY (emp_id) REFERENCES employees(emp_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);
```
*This gives the exact schema used throughout the rest of this document:*[cite: 1]
```sql
employees(emp_id, name, dept_id, manager_id, salary, hire_date)
departments(dept_id, dept_name, region)
orders(order_id, emp_id, customer_id, order_date, amount, status)
customers(customer_id, name, city, segment)
```

### Task 5: Alter a table
Add a `commission_pct` column to `employees`, then rename it to `commission_rate`[cite: 1].

**Answer:**
```sql
-- SQL Server does NOT allow the keyword "COLUMN" when ADDING columns
ALTER TABLE employees ADD commission_pct DECIMAL(4,2);

-- Column renaming in SQL Server uses the sp_rename system stored procedure
EXEC sp_rename 'employees.commission_pct', 'commission_rate', 'COLUMN';
```

### Task 6: Insert data
Insert two departments and two employees (one reporting to the other)[cite: 1].

**Answer:**
```sql
INSERT INTO departments (dept_name, region) VALUES
    ('Sales', 'East'),
    ('Engineering', 'West');

INSERT INTO employees (name, dept_id, manager_id, salary, hire_date) VALUES
    ('Alice Hassan', 1, NULL, 90000, '2020-01-15'),
    ('Omar Said',    1, 1,    55000, '2021-03-01');
```

### Task 7: Bulk insert / seed realistic data
Insert 3 customers and 5 orders spanning two employees[cite: 1].

**Answer:**
```sql
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
```

### Task 8: Update data
Give every employee in department 1 a 10% raise[cite: 1].

**Answer:**
```sql
UPDATE employees
SET salary = salary * 1.10
WHERE dept_id = 1;
```

### Task 9: Delete data
Remove all orders with status `'cancelled'` and amount under 1000[cite: 1].

**Answer:**
```sql
DELETE FROM orders
WHERE status = 'cancelled' AND amount < 1000;
```

### Task 10: Basic SELECT, DISTINCT, ORDER BY
List distinct cities customers are from, alphabetically[cite: 1].

**Answer:**
```sql
SELECT DISTINCT city
FROM customers
ORDER BY city;
```

### Task 11: Basic SELECT with WHERE + TOP
Get the 3 most recent orders[cite: 1].

**Answer:**
```sql
SELECT TOP (3) *
FROM orders
ORDER BY order_date DESC;

```
*Note: SQL Server uses `TOP (n)` instead of `LIMIT n`.*[cite: 1]
-------------------------------------------------------------
### Task 12: Basic aggregation
Find total and average order amount across all orders[cite: 1].

**Answer:**
```sql
SELECT SUM(amount) AS total_amount, AVG(amount) AS avg_amount, COUNT(*) AS order_count
FROM orders;
```

### Task 13: GROUP BY basics
Find total order amount per status[cite: 1].

**Answer:**
```sql
SELECT status, SUM(amount) AS total_amount
FROM orders
GROUP BY status;
```

### Task 14: Constraints in practice
Try inserting an order with a negative amount and explain what happens[cite: 1].

**Answer:**
```sql
INSERT INTO orders (emp_id, customer_id, order_date, amount)
VALUES (1, 1, '2024-04-01', -50);
-- The INSERT statement conflicted with the CHECK constraint "CK__orders__amount...".
```
*The `CHECK (amount >= 0)` constraint from Task 4 rejects it.*[cite: 1]

---

## PART 1 — Core Queries & Aggregations

### Task 15: WHERE vs HAVING
Find departments with more than 5 employees earning above 50,000[cite: 1].

**Answer:**
```sql
SELECT dept_id, COUNT(*) AS emp_count
FROM employees
WHERE salary > 50000
GROUP BY dept_id
HAVING COUNT(*) > 5;
```
*WHERE filters rows before grouping; HAVING filters groups after aggregation.*[cite: 1]

### Task 16: WHERE vs HAVING
List customers from 'Cairo' who placed more than 3 orders[cite: 1].

**Answer:**
```sql
SELECT c.customer_id, c.name, COUNT(o.order_id) AS order_count
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE c.city = 'Cairo'
GROUP BY c.customer_id, c.name
HAVING COUNT(o.order_id) > 3;
```

### Task 17: INNER JOIN
List all orders with employee names who made the sale[cite: 1].

**Answer:**
```sql
SELECT o.order_id, e.name, o.amount
FROM orders o
INNER JOIN employees e ON o.emp_id = e.emp_id;
```

### Task 18: LEFT JOIN
List all employees and their orders, including employees with no orders[cite: 1].

**Answer:**
```sql
SELECT e.name, o.order_id, o.amount
FROM employees e
LEFT JOIN orders o ON e.emp_id = o.emp_id;
```

### Task 19: RIGHT JOIN
List all orders and matching customers, including orders with no customer match (data issue check)[cite: 1].

**Answer:**
```sql
SELECT o.order_id, c.name
FROM customers c
RIGHT JOIN orders o ON c.customer_id = o.customer_id;
```

### Task 20: FULL OUTER JOIN
Find all employees and departments, including departments with no employees and employees with no department assigned[cite: 1].

**Answer:**
```sql
SELECT e.name, d.dept_name
FROM employees e
FULL OUTER JOIN departments d ON e.dept_id = d.dept_id;
```
*SQL Server natively supports `FULL OUTER JOIN`.*[cite: 1]

### Task 21: Self-Join
Find each employee along with their manager's name[cite: 1].

**Answer:**
```sql
SELECT e.name AS employee_name, m.name AS manager_name
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.emp_id;
```

### Task 22: Self-Join
Find pairs of employees in the same department earning the same salary (avoid duplicate pairs)[cite: 1].

**Answer:**
```sql
SELECT e1.name AS emp1, e2.name AS emp2, e1.dept_id, e1.salary
FROM employees e1
JOIN employees e2
  ON e1.dept_id = e2.dept_id
 AND e1.salary = e2.salary
 AND e1.emp_id < e2.emp_id;
```

---

## PART 2 — Advanced SQL

### Task 23: Subquery (scalar)
Find employees earning more than the company average salary[cite: 1].

**Answer:**
```sql
SELECT name, salary
FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees);