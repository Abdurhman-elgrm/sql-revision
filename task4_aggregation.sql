select sum(amount) as total_amount , avg(amount) as avg_amount , COUNT(*) as order_count
from orders ;


select status , sum(amount) as total_amount 
from orders
group by status ;

select dept_id , count(*) as emp_count
from employees 
where salary > 50000 
group by dept_id 
having count(*) > 5 ;

select c.name , count(o.order_id) as order_count 
from customers c 
join orders o 
on c.customer_id = o.customer_id 
where c.city = 'Cairo'
group by c.name , c.customer_id
having count(o.order_id) > 3;


select o.order_id , e.name , o.amount 
from orders o 
inner join employees e  on e.emp_id =o.emp_id ;


SELECT e.name, d.dept_name
FROM employees e
FULL OUTER JOIN departments d ON e.dept_id = d.dept_id;

SELECT e.name AS employee_name, m.name AS manager_name
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.emp_id;


SELECT e1.name AS emp1, e2.name AS emp2, e1.dept_id, e1.salary
FROM employees e1
JOIN employees e2
  ON e1.dept_id = e2.dept_id
 AND e1.salary = e2.salary
 AND e1.emp_id < e2.emp_id;


 select name , salary 
 from employees 
 where salary > (select AVG(salary) from employees);