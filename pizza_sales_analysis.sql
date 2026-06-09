--Database created

create database pizzahut


-- imported all the tables from spreadsheet and modified columns as per requirement
-- database name > tasks > import flat file > select spreadsheet

-- data type altered to nvarchar(max) in place of text

alter table pizzas
alter column pizza_id nvarchar(max);

alter table order_details
alter column pizza_id nvarchar(max);

-- when the data is too big to import, we will create table manually and import data e.g.

/*use pizzahut

create table orders(
order_id int not null,
order_date date not null,
order_time time not null,
primary key(order_id));*/


select top 5* from pizzas;
select top 5* from pizza_types;
select top 5* from orders;
select top 5* from order_details;


/*Basic:
Retrieve the total number of orders placed.
Calculate the total revenue generated from pizza sales.
Identify the highest-priced pizza.
Identify the most common pizza size ordered.
List the top 5 most ordered pizza types along with their quantities.*/


--Retrieve the total number of orders placed.

select count(order_id) as total_orders from orders;
-- 21350


-- Calculate the total revenue generated from pizza sales.

select
round(sum(order_details.quantity*pizzas.price),2) as total_revenue 
from order_details join pizzas 
on pizzas.pizza_id = order_details.pizza_id;

-- Identify the highest-priced pizza.

select top 1 pizza_types.name,round(pizzas.price,2)
from pizza_types join pizzas
on pizza_types.pizza_type_id = pizzas.pizza_type_id
order by pizzas.price desc;


-- Identify the most common pizza size ordered.

-- Pizzas sold
select pizzas.size,sum(order_details.quantity) as pizzas_sold
from pizzas join order_details
on pizzas.pizza_id = order_details.pizza_id
group by pizzas.size
order by pizzas_sold desc;

-- Pizzas ordered

select pizzas.size,count(order_details.order_details_id) as times_ordered
from pizzas join order_details
on pizzas.pizza_id = order_details.pizza_id
group by pizzas.size
order by times_ordered desc;


--List the top 5 most ordered pizza types along with their quantities.

select top 5 pizza_types.name,sum(order_details.quantity) as pizzas_sold
from pizza_types join pizzas
on pizza_types.pizza_type_id = pizzas.pizza_type_id
join order_details
on pizzas.pizza_id = order_details.pizza_id
group by pizza_types.name
order by pizzas_sold desc;


/*Intermediate:
Join the necessary tables to find the total quantity of each pizza category ordered.
Determine the distribution of orders by hour of the day.
Join relevant tables to find the category-wise distribution of pizzas.
Group the orders by date and calculate the average number of pizzas ordered per day.
Determine the top 3 most ordered pizza types based on revenue.*/

--Join the necessary tables to find the total quantity of each pizza category ordered.

select pizza_types.category, sum(order_details.quantity) as pizzas_sold
from pizza_types join pizzas
on pizza_types.pizza_type_id = pizzas.pizza_type_id
join order_details
on pizzas.pizza_id = order_details.pizza_id
group by pizza_types.category;

--Determine the distribution of orders by hour of the day.

select datepart(hour,orders.time) from orders;


select * from orders
order by datepart(hour,time);

select * from order_details 
where order_id = 19176

-- Distribution of orders received

select datepart(hour,orders.time) as order_hour,count(order_details.order_id) as orders_received
from orders join order_details
on orders.order_id = order_details.order_id
group by datepart(hour,orders.time)
order by datepart(hour,orders.time);

--Distribution of number of pizzas ordered

select datepart(hour,orders.time) as order_hour,sum(order_details.quantity) as pizza_quantity
from orders join order_details
on orders.order_id = order_details.order_id
group by datepart(hour,orders.time)
order by datepart(hour,orders.time);


--Find the category-wise distribution of pizzas.

select category,count(name) 
from pizza_types
group by category;


--Group the orders by date and calculate the average number of pizzas ordered per day.


select avg(pizza_quantity) as Avg_daily_pizza_ordered 
from (select orders.date, sum(order_details.quantity) as pizza_quantity
from orders join order_details
on orders.order_id = order_details.order_id
group by orders.date) as daily_pizzas_ordered;

--Determine the top 3 most ordered pizza types based on revenue.

select top 3 pizza_types.name, sum(order_details.quantity*pizzas.price) as total_revenue
from pizza_types join pizzas
on pizza_types.pizza_type_id = pizzas.pizza_type_id
join order_details
on pizzas.pizza_id = order_details.pizza_id
group by pizza_types.name
order by total_revenue desc;



/*Advanced:
Calculate the percentage contribution of each pizza type to total revenue.
Calculate the percentage contribution of each pizza category to total revenue.
Analyze the cumulative revenue generated over time.
Determine the top 3 most ordered pizza types based on revenue for each pizza category.*/

--Calculate the percentage contribution of each pizza type to total revenue.

select pizza_types.name,
round((sum(order_details.quantity*pizzas.price) * 100/ (select sum(order_details.quantity*pizzas.price)
from order_details join pizzas
on order_details.pizza_id = pizzas.pizza_id)),2) as percentage_contribution
from pizza_types join pizzas
on pizza_types.pizza_type_id = pizzas.pizza_type_id
join order_details
on order_details.pizza_id = pizzas.pizza_id
group by pizza_types.name
order by percentage_contribution desc;

--Calculate the percentage contribution of each pizza category to total revenue.

select pizza_types.category,round((sum(order_details.quantity * pizzas.price) * 100 /
(select sum(order_details.quantity * pizzas.price)
from order_details join pizzas
on order_details.pizza_id = pizzas.pizza_id)),2) as percent_contribution
from pizza_types join pizzas
on pizza_types.pizza_type_id = pizzas.pizza_type_id
join order_details
on order_details.pizza_id = pizzas.pizza_id
group by pizza_types.category;

--Analyze the cumulative revenue generated over time.

select date,sum(daily_revenue) over(order by date) as cum_revenue
from
(select orders.date,sum(order_details.quantity * pizzas.price) as daily_revenue
from order_details join pizzas
on order_details.pizza_id = pizzas.pizza_id
join orders
on orders.order_id = order_details.order_id
group by orders.date) as sales;

--Alternative

SELECT orders.date,
SUM(order_details.quantity * pizzas.price) AS daily_revenue,
SUM(SUM(order_details.quantity * pizzas.price)) 
OVER (ORDER BY orders.date) AS cum_revenue
FROM orders JOIN order_details
ON orders.order_id = order_details.order_id
JOIN pizzas
ON order_details.pizza_id = pizzas.pizza_id
GROUP BY orders.date
ORDER BY orders.date;

--Determine the top 3 most ordered pizza types based on revenue for each pizza category.

select category, name, revenue 
from
(select category, name, revenue, rank() over(partition by category order by revenue desc) as rnk
from
(select pizza_types.category, pizza_types.name,sum(order_details.quantity*pizzas.price) as revenue
from pizza_types join pizzas
on pizza_types.pizza_type_id = pizzas.pizza_type_id
join order_details
ON order_details.pizza_id = pizzas.pizza_id
group by pizza_types.category, pizza_types.name) as A) as B
where rnk<=3;
