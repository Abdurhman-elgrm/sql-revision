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

--common table , cte

