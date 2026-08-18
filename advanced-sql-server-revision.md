# Advanced SQL Server Revision Guide

Topics: Subqueries · CTEs · GROUPING SETS · CASE WHEN Conditional Aggregation · Window Functions

Each section has: **Concept explanation → Syntax → Example → Practice tasks (no answers, so you can self-test)**.
An answer key section is at the bottom. A "What to Learn Next" section lists more advanced topics to extend this file.

---

## Sample Schema (used in all examples/tasks)

```sql
CREATE TABLE Employees (
    EmployeeID   INT PRIMARY KEY,
    FullName     VARCHAR(100),
    DepartmentID INT,
    ManagerID    INT NULL,
    Salary       DECIMAL(10,2),
    HireDate     DATE
);

CREATE TABLE Departments (
    DepartmentID   INT PRIMARY KEY,
    DepartmentName VARCHAR(50)
);

CREATE TABLE Orders (
    OrderID     INT PRIMARY KEY,
    EmployeeID  INT,
    CustomerID  INT,
    OrderDate   DATE,
    Amount      DECIMAL(10,2)
);
```

---

## 1. Subqueries

### Concept
A subquery is a query nested inside another query. Types:
- **Scalar subquery** – returns a single value, used where an expression is expected.
- **Multi-row subquery** – used with `IN`, `ANY`, `ALL`.
- **Correlated subquery** – references a column from the outer query; runs once per outer row.
- **EXISTS / NOT EXISTS** – checks for row existence, often faster than `IN` for large sets.
- **Derived table** – a subquery in the `FROM` clause, treated as a temporary table.

### Syntax
```sql
-- Scalar subquery
SELECT FullName, Salary,
       (SELECT AVG(Salary) FROM Employees) AS CompanyAvgSalary
FROM Employees;

-- Correlated subquery
SELECT e.FullName, e.Salary, e.DepartmentID
FROM Employees e
WHERE e.Salary > (
    SELECT AVG(e2.Salary)
    FROM Employees e2
    WHERE e2.DepartmentID = e.DepartmentID
);

-- EXISTS
SELECT d.DepartmentName
FROM Departments d
WHERE EXISTS (
    SELECT 1 FROM Employees e WHERE e.DepartmentID = d.DepartmentID
);

-- Derived table
SELECT dept_avg.DepartmentID, dept_avg.AvgSalary
FROM (
    SELECT DepartmentID, AVG(Salary) AS AvgSalary
    FROM Employees
    GROUP BY DepartmentID
) AS dept_avg
WHERE dept_avg.AvgSalary > 50000;
```

### Practice Tasks
1. Write a query to find all employees whose salary is above the overall company average (use a scalar subquery).
2. Write a correlated subquery to find employees who earn more than the average salary **in their own department**.
3. Use `EXISTS` to list departments that have **at least one** employee earning more than 100,000.
4. Use `NOT EXISTS` to list departments that have **no employees at all**.
5. Use a derived table to find the department with the highest average salary.
6. Rewrite task 3 using `IN` instead of `EXISTS`, then explain (in a comment) when `EXISTS` performs better than `IN`.

---

## 2. Common Table Expressions (CTEs / `WITH` clause)

### Concept
A CTE is a named temporary result set defined with `WITH`, scoped to the single statement that follows it. Benefits: readability, reusability within the same query, and enabling **recursion**.

- **Non-recursive CTE** – like a named subquery, can simplify layered logic.
- **Recursive CTE** – has an anchor member (base case) and a recursive member (self-reference), combined with `UNION ALL`. Common for hierarchies (org charts, bill of materials, category trees).
- **Multiple CTEs** – chain several CTEs, each can reference the ones defined before it.

### Syntax
```sql
-- Basic CTE
WITH DeptAvg AS (
    SELECT DepartmentID, AVG(Salary) AS AvgSalary
    FROM Employees
    GROUP BY DepartmentID
)
SELECT e.FullName, e.Salary, d.AvgSalary
FROM Employees e
JOIN DeptAvg d ON e.DepartmentID = d.DepartmentID
WHERE e.Salary > d.AvgSalary;

-- Recursive CTE: employee hierarchy
WITH EmpHierarchy AS (
    -- Anchor: top-level managers (no manager)
    SELECT EmployeeID, FullName, ManagerID, 0 AS Level
    FROM Employees
    WHERE ManagerID IS NULL

    UNION ALL

    -- Recursive: employees reporting to previous level
    SELECT e.EmployeeID, e.FullName, e.ManagerID, eh.Level + 1
    FROM Employees e
    JOIN EmpHierarchy eh ON e.ManagerID = eh.EmployeeID
)
SELECT * FROM EmpHierarchy
ORDER BY Level, FullName
OPTION (MAXRECURSION 100);
```

### Practice Tasks
1. Write a CTE that calculates total order amount per employee, then select only employees whose total exceeds 500,000.
2. Rewrite the correlated subquery from Task 2 (Section 1) using a CTE instead.
3. Write a recursive CTE to display the full management chain (reporting hierarchy) with a `Level` column starting at 0 for top-level managers.
4. Extend the recursive CTE above to also produce an indented `FullName` path, e.g. `-- -- John Smith` for level 2.
5. Use two chained CTEs: the first computes department totals, the second ranks departments by total salary spend (don't use window functions yet — use a subquery or self-join for the rank).
6. What's the difference between a CTE and a temp table (`#Temp`) in SQL Server? Write 3–4 bullet points as a comment in your revision file.

---

## 3. GROUPING SETS, ROLLUP, and CUBE

### Concept
These extend `GROUP BY` to produce **multiple levels of aggregation in a single query**, avoiding multiple `UNION`-ed queries.

- **GROUPING SETS** – explicitly define which combinations of columns to group by (including `()` for a grand total).
- **ROLLUP** – produces a hierarchy of subtotals, from most detailed to grand total (order of columns matters).
- **CUBE** – produces subtotals for **every possible combination** of the grouping columns.
- **GROUPING()** function – tells you whether a NULL in the result is a "real" NULL or a subtotal marker.

### Syntax
```sql
-- GROUPING SETS
SELECT DepartmentID, YEAR(HireDate) AS HireYear, COUNT(*) AS Cnt
FROM Employees
GROUP BY GROUPING SETS (
    (DepartmentID, YEAR(HireDate)),
    (DepartmentID),
    (YEAR(HireDate)),
    ()
);

-- ROLLUP
SELECT DepartmentID, YEAR(HireDate) AS HireYear, COUNT(*) AS Cnt
FROM Employees
GROUP BY ROLLUP (DepartmentID, YEAR(HireDate));

-- CUBE
SELECT DepartmentID, YEAR(HireDate) AS HireYear, COUNT(*) AS Cnt
FROM Employees
GROUP BY CUBE (DepartmentID, YEAR(HireDate));

-- Distinguishing subtotal rows
SELECT
    DepartmentID,
    YEAR(HireDate) AS HireYear,
    COUNT(*) AS Cnt,
    GROUPING(DepartmentID) AS IsDeptSubtotal,
    GROUPING(YEAR(HireDate)) AS IsYearSubtotal
FROM Employees
GROUP BY ROLLUP (DepartmentID, YEAR(HireDate));
```

### Practice Tasks
1. Write a query using `ROLLUP` to show total order `Amount` by `EmployeeID`, with a grand total row.
2. Write the same report using `GROUPING SETS` explicitly (department subtotal, year subtotal, grand total, and the detail level) and compare the result to `ROLLUP`.
3. Use `CUBE` to produce total sales for every combination of `DepartmentID` and order year — how many more rows does `CUBE` produce vs `ROLLUP` for the same data, and why?
4. Add a `GROUPING()` column to your query from Task 1 and use `CASE WHEN` to replace subtotal `NULL`s with the label `'All Departments'`.
5. In your own words (as a comment): when would you choose `GROUPING SETS` over `ROLLUP`?

---

## 4. CASE WHEN Conditional Aggregation

### Concept
`CASE WHEN` inside an aggregate function lets you **pivot data manually** — turning row values into columns — without using the `PIVOT` operator. Very common for building reports like "count of orders per status" or "sales by quarter" as columns.

### Syntax
```sql
SELECT
    DepartmentID,
    COUNT(CASE WHEN Salary > 80000 THEN 1 END) AS HighEarners,
    COUNT(CASE WHEN Salary <= 80000 THEN 1 END) AS OtherEarners,
    SUM(CASE WHEN Salary > 80000 THEN Salary ELSE 0 END) AS HighEarnerPayroll,
    AVG(CASE WHEN DATEDIFF(YEAR, HireDate, GETDATE()) >= 5 THEN Salary END) AS AvgSalaryTenured5Plus
FROM Employees
GROUP BY DepartmentID;

-- Manual pivot: orders per quarter, per employee
SELECT
    EmployeeID,
    SUM(CASE WHEN DATEPART(QUARTER, OrderDate) = 1 THEN Amount ELSE 0 END) AS Q1,
    SUM(CASE WHEN DATEPART(QUARTER, OrderDate) = 2 THEN Amount ELSE 0 END) AS Q2,
    SUM(CASE WHEN DATEPART(QUARTER, OrderDate) = 3 THEN Amount ELSE 0 END) AS Q3,
    SUM(CASE WHEN DATEPART(QUARTER, OrderDate) = 4 THEN Amount ELSE 0 END) AS Q4
FROM Orders
GROUP BY EmployeeID;
```

### Practice Tasks
1. Write a query that shows, per department, the count of employees hired **before 2020** vs **2020 or later**, as two separate columns.
2. Build a manual pivot: total order `Amount` per `EmployeeID`, broken into columns `Under100`, `Between100And500`, `Over500` based on `Amount` ranges.
3. Write a query showing per-employee: total orders count, and the **percentage** of orders over 500 (hint: combine `SUM(CASE WHEN...)` with `COUNT(*)` and cast to decimal).
4. Combine conditional aggregation with a CTE: first build a CTE of yearly order totals per employee, then pivot years into columns in the outer query.
5. What's the key difference between using `CASE WHEN` for pivoting vs. using the native `PIVOT` operator? Note one advantage of each as a comment.

---

## 5. Window Functions

### Concept
Window functions perform a calculation across a set of rows ("window") related to the current row, **without collapsing rows** like `GROUP BY` does. Defined with `OVER (PARTITION BY ... ORDER BY ... [ROWS/RANGE ...])`.

- **ROW_NUMBER()** – unique sequential number per partition; ties get different numbers.
- **RANK()** – same rank for ties, but leaves gaps afterward (1,1,3).
- **DENSE_RANK()** – same rank for ties, no gaps (1,1,2).
- **LEAD(col, n)** – value from n rows ahead in the ordered partition.
- **LAG(col, n)** – value from n rows behind.
- **Running totals** – `SUM(...) OVER (PARTITION BY ... ORDER BY ... ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)`.
- **Frame clauses** – `ROWS BETWEEN ... AND ...` controls exactly which rows are included (e.g. moving averages).

### Syntax
```sql
-- ROW_NUMBER / RANK / DENSE_RANK
SELECT
    FullName, DepartmentID, Salary,
    ROW_NUMBER() OVER (PARTITION BY DepartmentID ORDER BY Salary DESC) AS RowNum,
    RANK()       OVER (PARTITION BY DepartmentID ORDER BY Salary DESC) AS SalaryRank,
    DENSE_RANK() OVER (PARTITION BY DepartmentID ORDER BY Salary DESC) AS SalaryDenseRank
FROM Employees;

-- LEAD / LAG
SELECT
    EmployeeID, OrderDate, Amount,
    LAG(Amount, 1)  OVER (PARTITION BY EmployeeID ORDER BY OrderDate) AS PrevOrderAmount,
    LEAD(Amount, 1) OVER (PARTITION BY EmployeeID ORDER BY OrderDate) AS NextOrderAmount,
    Amount - LAG(Amount, 1) OVER (PARTITION BY EmployeeID ORDER BY OrderDate) AS ChangeFromPrev
FROM Orders;

-- Running total
SELECT
    EmployeeID, OrderDate, Amount,
    SUM(Amount) OVER (
        PARTITION BY EmployeeID
        ORDER BY OrderDate
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS RunningTotal
FROM Orders;

-- Moving average (3-row window)
SELECT
    EmployeeID, OrderDate, Amount,
    AVG(Amount) OVER (
        PARTITION BY EmployeeID
        ORDER BY OrderDate
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS MovingAvg3
FROM Orders;
```

### Practice Tasks
1. For each employee, rank their orders by `Amount` (highest first) using `ROW_NUMBER()`, then select only the **top 3 orders per employee**.
2. Repeat Task 1 with `RANK()` and `DENSE_RANK()` instead — create test data with tied amounts and explain the difference in output.
3. Write a query that shows each employee's salary alongside the **next-highest-paid employee's salary in the same department** (use `LEAD`).
4. Calculate the month-over-month change in total order amount per employee (aggregate orders by month first, then use `LAG`).
5. Write a running total of `Amount` per `EmployeeID` ordered by `OrderDate`, and also show what percentage each order contributes to the running total.
6. Write a 3-order moving average of `Amount` per employee.
7. Find the department's highest earner using `ROW_NUMBER() OVER (PARTITION BY DepartmentID ORDER BY Salary DESC) = 1` inside a CTE, then compare this approach to using `MAX()` with `GROUP BY`. When would you need the window function approach instead of `MAX()`?
8. Combine everything: write one query using a CTE + window function to find, per department, the top 2 earners, their rank, and how far behind (in salary) they are from the department's #1 earner (use `FIRST_VALUE()` as a bonus).

---

## 6. `WITH` Table Hints and Indexing

### Concept
This `WITH` is unrelated to the CTE `WITH` clause from Section 2 — this one attaches **hints** directly to a table reference to override the optimizer's default behavior (locking, index choice, etc.). Used sparingly, usually for troubleshooting or very specific performance needs.

Common hints:
- **`WITH (NOLOCK)`** – reads without taking shared locks (allows dirty reads); fast but can return uncommitted/inconsistent data. Same as `READUNCOMMITTED`.
- **`WITH (INDEX(index_name))`** or **`WITH (INDEX(0))`/`INDEX(1)`** – forces the optimizer to use a specific index (or force a table/clustered index scan with `0`/`1`).
- **`WITH (FORCESEEK)` / `WITH (FORCESCAN)`** – forces a seek or scan operation.
- **`WITH (ROWLOCK)` / `WITH (TABLOCK)` / `WITH (UPDLOCK)` / `WITH (HOLDLOCK)`** – control locking granularity/duration.
- Hints should generally be a **last resort** — the query optimizer's cost-based choices are usually better than manual overrides. Overuse can make queries brittle across data growth or SQL Server upgrades.

### Indexing Fundamentals (needed to use hints meaningfully)
- **Clustered index** – defines the physical storage order of the table; a table can have only **one**. Usually the primary key by default.
- **Nonclustered index** – a separate structure with pointers back to the clustered index (or heap); a table can have **many**. Good for columns frequently used in `WHERE`, `JOIN`, `ORDER BY`.
- **Covering index** – a nonclustered index that includes all columns a query needs (via key columns + `INCLUDE`), so SQL Server never has to look up the base table ("key lookup" avoided).
- **`INCLUDE` columns** – non-key columns added to a nonclustered index leaf level to make it "covering" without bloating the index key itself.
- **Seek vs. Scan** – a seek uses the index's B-tree to jump directly to matching rows (fast, selective); a scan reads the whole index/table (fine for large result sets, bad for selective queries missing an index).
- **Index on window function / CTE columns** – a `PARTITION BY` + `ORDER BY` combination in a window function benefits enormously from an index matching those columns, since SQL Server can avoid a separate sort operation.
- **Statistics** – SQL Server uses column statistics (row count estimates) to choose seek vs scan and join strategies; stale statistics are a common hidden cause of "the optimizer picked a bad plan."

### Syntax
```sql
-- Table hint: force a specific index
SELECT FullName, Salary
FROM Employees WITH (INDEX(IX_Employees_DepartmentID))
WHERE DepartmentID = 3;

-- Table hint: NOLOCK for a fast, dirty read (use with caution)
SELECT COUNT(*) FROM Orders WITH (NOLOCK);

-- Creating a nonclustered index to support a common filter
CREATE NONCLUSTERED INDEX IX_Employees_DepartmentID_Salary
ON Employees (DepartmentID, Salary DESC);

-- Covering index using INCLUDE (avoids key lookups)
CREATE NONCLUSTERED INDEX IX_Orders_EmployeeID_OrderDate
ON Orders (EmployeeID, OrderDate)
INCLUDE (Amount);

-- Checking whether an index is actually used
SET STATISTICS IO ON;
SELECT EmployeeID, OrderDate, Amount
FROM Orders WITH (FORCESEEK)
WHERE EmployeeID = 12
ORDER BY OrderDate;
```

### Practice Tasks
1. Create a nonclustered index on `Orders(EmployeeID, OrderDate)` and rerun the running-total query from Section 5, Task 5. Turn on `SET STATISTICS IO ON` and note the logical reads before and after adding the index.
2. Write a query using `WITH (INDEX(...))` to force use of a specific index, then use `WITH (INDEX(0))` to force a table/clustered scan instead — compare the execution plans.
3. Create a **covering index** for a query that selects `EmployeeID, OrderDate, Amount` filtered by `EmployeeID` — use `INCLUDE` for the non-key column(s). Confirm in the execution plan that the "Key Lookup" operator disappears.
4. Explain (as a comment) the risk of using `WITH (NOLOCK)` on a financial reporting query, and describe a safer alternative (e.g. `READ COMMITTED SNAPSHOT` isolation).
5. Take the department-ranking window function query from Section 5, Task 7. Design an index that would best support its `PARTITION BY DepartmentID ORDER BY Salary DESC` clause, and explain why column order in the index matters here.
6. Look up (or test) the difference between `FORCESEEK` and simply creating a better index — why is `FORCESEEK` considered a hint of last resort rather than a fix?

---

## Answer Key Notes (self-check approach)

This file intentionally does **not** include full solutions — that's part of the revision exercise. Suggested self-check method:
1. Build the sample schema in a local SQL Server instance (or Azure Data Studio / SSMS with LocalDB).
2. Insert 15–20 rows of sample data covering edge cases: ties in salary, NULL ManagerID, employees with no orders, multiple years of HireDate.
3. Run each task, then verify row counts and spot-check 2–3 rows manually.

---

## What to Learn Next (Advanced Topics to Add)

Once comfortable with the above, extend this file with:

| Topic | Why it matters |
|---|---|
| `PIVOT` / `UNPIVOT` operators | Native alternative to `CASE WHEN` pivoting |
| `CROSS APPLY` / `OUTER APPLY` | Row-by-row correlated table-valued execution (e.g. top-N per group, calling TVFs) |
| `FIRST_VALUE()` / `LAST_VALUE()` / `NTH_VALUE()` | More window function variants |
| `NTILE(n)` | Splitting rows into n buckets (e.g. quartiles) |
| Frame clauses in depth (`RANGE` vs `ROWS`, `PRECEDING`/`FOLLOWING`) | Precise control of window boundaries |
| `MERGE` statement | Upsert logic in a single statement |
| Recursive CTEs for graphs/BOM structures | Beyond simple hierarchies — cycles, multi-parent structures |
| Execution plans (Actual Execution Plan, operator costs) | Diagnosing slow queries in more depth |
| Temporal Tables (`FOR SYSTEM_TIME`) | Querying historical row versions |
| `STRING_AGG()` / `JSON` functions (`FOR JSON`, `OPENJSON`) | String aggregation and JSON handling |
| Dynamic SQL (`sp_executesql`) | Building queries at runtime safely |
| Table-Valued Parameters & Table-Valued Functions | Passing sets of data into procedures |
| Isolation levels & locking hints | Concurrency control |
| Columnstore indexes & partitioning | Large-scale analytical workloads |

---

*Revision file generated for Microsoft SQL Server (T-SQL) practice. Add solutions and new sections as you progress.*
