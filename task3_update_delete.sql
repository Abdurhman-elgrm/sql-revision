update employees 
set salary = salary*1.10
where dept_id = 1 ;

select * from employees
select * from orders

delete from orders 
where status = 'cancelled' and amount < 1000 ;

select * from orders

select distinct city 
from customers 
order by city


/*Task 11: Basic SELECT with WHERE + TOP
Get the 3 most recent orders[cite: 1].*/

select top(3)*
from orders 
order by order_date desc;
