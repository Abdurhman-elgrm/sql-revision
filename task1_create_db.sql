--TASK1 CREATE DATABASE AND TABLE -- 


create database company_db;
USE company_db;
create table departments (
	dept_id INT identity(1,1) PRIMARY KEY ,
	dept_name VARCHAR(50)  NOT NULL,
	region VARCHAR(50) 

);

CREATE TABLE employees (
    emp_id      INT identity(1,1)  PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    dept_id     INT,
    manager_id  INT,
    salary      DECIMAL(10,2) CHECK (salary >= 0),
    hire_date   DATE NOT NULL DEFAULT (CURRENT_DATE),
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id),
    FOREIGN KEY (manager_id) REFERENCES employees(emp_id)   -- self-referencing FK
);




CREATE TABLE customers (
    customer_id INT identity(1,1)  PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    city        VARCHAR(50),
    segment     VARCHAR(20)
);


create table orders (
	order_id int  PRIMARY KEY ,
	emp_id int ,
	customer_id int ,
	order_date date not null ,
	amount decimal(10,2) check(amount >= 0),
	status varchar(50) default 'pending',
	foreign key (emp_id) references employees(emp_id) ,
    foreign key (customer_id) references customers(customer_id),
);