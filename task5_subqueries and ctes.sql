-- Scalar subquery
select name , salary , (select avg(salary) from employees ) as companyavgsalarly
from employees;

--exists 
select d.dept_name
from departments d 
where exists ( 
	select 1 from employees e where e.dept_id = d.dept_id);

--derived 

select dept_avg.dept_id , dept_avg.avgsalary 
from (
	select dept_id , AVG(salary) as avgsalary
	from employees
	group by dept_id
) as dept_avg
where dept_avg.avgsalary > 50000;



select e.name , e.salary 
from employees e
where  (select AVG(salary) from employees ) < e.salary;


select e.name , e.salary , d.dept_name
from employees e 
join departments d on d.dept_id =e.dept_id
where e.salary > (
	select AVG(e2.salary)
	from employees e2 
	where e2.dept_id = e.dept_id
);

select d.dept_name 
from departments d 
where exists (
		select 1 from employees e where
		e.dept_id = d.dept_id
		and
		e.salary >100000
	);

--basic ctes 

WITH DeptAvg AS (
    SELECT dept_id, AVG(Salary) AS AvgSalary
    FROM Employees
    GROUP BY dept_id
)
SELECT e.name, e.Salary, d.AvgSalary
FROM Employees e
JOIN DeptAvg d ON e.dept_id = d.dept_id
WHERE e.Salary > d.AvgSalary;

-- Recursive CTE: employee hierarchy
WITH EmpHierarchy AS (
    -- Anchor: top-level managers (no manager)
    SELECT emp_id , name, manager_id, 0 AS Level
    FROM Employees
    WHERE manager_id IS NULL

    UNION ALL

    SELECT e.emp_id, e.name, e.manager_id, eh.Level + 1
    FROM Employees e
    JOIN EmpHierarchy eh ON e.manager_id = eh.emp_id
)
SELECT * FROM EmpHierarchy
ORDER BY Level, name
OPTION (MAXRECURSION 100);