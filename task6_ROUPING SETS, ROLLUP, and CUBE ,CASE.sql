--group sets 
select dept_id , YEAR(hire_date) as hire_year , 
COUNT(*) as cnt 
from employees 
group by grouping sets (
(dept_id , YEAR(hire_date)),
(dept_id),
(YEAR(hire_date)),
()
);

--rollup 
select dept_id , YEAR(hire_date) as hire_year ,
count(*) as cnt 
from employees 
group by rollup (dept_id ,YEAR(hire_date))


-- CUBE
SELECT dept_id, YEAR(hire_date) AS HireYear, COUNT(*) AS Cnt
FROM employees
GROUP BY CUBE (dept_id, YEAR(hire_date));

--case when conditional aggregation 
SELECT
    dept_id,
    COUNT(CASE WHEN salary > 80000 THEN 1 END) AS HighEarners,
    COUNT(CASE WHEN salary <= 80000 THEN 1 END) AS OtherEarners,
    SUM(CASE WHEN salary > 80000 THEN salary ELSE 0 END) AS HighEarnerPayroll,
    AVG(CASE WHEN DATEDIFF(YEAR, hire_date, GETDATE()) >= 5 THEN salary END) AS AvgSalaryTenured5Plus
FROM employees
GROUP BY dept_id;

