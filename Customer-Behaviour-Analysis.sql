CREATE DATABASE dannys_diner;

USE dannys_diner;

CREATE TABLE sales(
	customer_id VARCHAR(1),
	order_date DATE,
	product_id INTEGER
);


INSERT INTO sales
	(customer_id, order_date, product_id)
VALUES
	('A', '2021-01-01', 1),
	('A', '2021-01-01', 2),
	('A', '2021-01-07', 2),
	('A', '2021-01-10', 3),
	('A', '2021-01-11', 3),
	('A', '2021-01-11', 3),
	('B', '2021-01-01', 2),
	('B', '2021-01-02', 2),
	('B', '2021-01-04', 1),
	('B', '2021-01-11', 1),
	('B', '2021-01-16', 3),
	('B', '2021-02-01', 3),
	('C', '2021-01-01', 3),
	('C', '2021-01-01', 3),
	('C', '2021-01-07', 3);
	
CREATE TABLE menu(
	product_id INTEGER,
	product_name VARCHAR(5),
	price INTEGER);
	
INSERT INTO menu
	(product_id, product_name, price)
VALUES
	(1, 'sushi', 10),
    (2, 'curry', 15),
    (3, 'ramen', 12);	
	
	
CREATE TABLE members(
	customer_id VARCHAR(1),
	join_date DATE
);	

-- Still works without specifying the column names explicitly
INSERT INTO members
	(customer_id, join_date)
VALUES
	('A', '2021-01-07'),
    ('B', '2021-01-09');
	
--1. What is the total amount each customer spent at the restaurant?
-- Corrected query without schema specification
SELECT s.customer_id, SUM(m.price) AS total_spent
FROM sales s
INNER JOIN menu m
ON s.product_id = m.product_id
GROUP BY s.customer_id;

-- 2. How many days has each customer visited the restaurant?	
SELECT s.customer_id, COUNT(DISTINCT s.order_date) AS days_visited
FROM sales s
GROUP BY s.customer_id;	
	
 -- 3. What was the first item from the menu purchased by each customer?
with customer_first_purchase as(
        select s.customer_id, min(s.order_date) as first_purchase_date
        from sales s
	    group by s.customer_id 
)	
 select cfp.customer_id, cfp.first_purchase_date,m.product_name
 from customer_first_purchase cfp
 inner join sales s on s.customer_id = cfp.customer_id
 and cfp.first_purchase_date = s.order_date
 inner join menu m on m.product_id = s.product_id;
 
--4. What is the most purchased item on the menu and 
--how many times was it purchased by all customers? 

SELECT m.product_name, COUNT(s.product_id) AS total_purchased
FROM sales s
INNER JOIN menu m ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY total_purchased DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer? 
WITH customer_popularity AS (
	SELECT s.customer_id, m.product_name, COUNT(*) AS purchase_count,
	       DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY COUNT(*) DESC) AS rank
	FROM sales s 
	INNER JOIN menu m ON s.product_id = m.product_id
	GROUP BY s.customer_id, m.product_name
)
SELECT customer_id, product_name, purchase_count
FROM customer_popularity
WHERE rank = 1;

 
 -- 6. Which item was purchased first by the customer after they became a member?
 
 with first_purchase_after_membership as (
	 select s.customer_id, min(s.order_date) as first_purchase_date
	 from sales s
	 join members mb on s.customer_id = mb.customer_id
	 where s.order_date >= mb.join_date
	 group by s.customer_id
 )
 select fpam.customer_id, m.product_name
 from first_purchase_after_membership fpam
 join sales s on fpam.customer_id = s.customer_id
 and fpam.first_purchase_date = s.order_date
 join menu m on s.product_id = m.product_id
 
-- 7. Which item was purchased just before the customer became a member? 
 SELECT s.customer_id, m.product_name
FROM sales s
JOIN members mb ON s.customer_id = mb.customer_id
JOIN menu m ON s.product_id = m.product_id
WHERE s.order_date = (
    SELECT MAX(s2.order_date)
    FROM sales s2
    WHERE s2.customer_id = s.customer_id
    AND s2.order_date < mb.join_date
);

-- 8. What is the total items and amount spent for each member before they became a member?
select s.customer_id, count(*) as  total_items, sum(m.price) as total_spent
from sales s
join menu m on s.product_id = m.product_id
join members mb on s.customer_id = mb.customer_id
where s.order_date < mb.join_date
group by s.customer_id;
	
-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier 
-- how many points would each customer have?	
select s.customer_id, sum(
	case  
	      when m.product_name = 'sushi' then m.price*20
	      else m.price*10 end) as total_points

from sales s 
join menu m on s.product_id = m.product_id
group by customer_id;
	
/* 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - 
how many points do customer A and B have at the end of January?*/
SELECT s.customer_id, 
       SUM(
           CASE 
               -- 2x points during the first week after joining (including join date)
               WHEN s.order_date BETWEEN mb.join_date AND mb.join_date + INTERVAL '7 days' THEN m.price * 20
               -- 2x points for sushi at all times
               WHEN m.product_name = 'sushi' THEN m.price * 20
               -- Regular points (10x)
               ELSE m.price * 10
           END
       ) AS total_points
FROM sales s
JOIN menu m ON s.product_id = m.product_id
LEFT JOIN members mb ON s.customer_id = mb.customer_id
WHERE s.order_date <= '2021-01-31'
  AND s.customer_id IN ('A', 'B') -- Only customers A and B
GROUP BY s.customer_id;

--11. Recreate the table output using the available data	
select s.customer_id, s.order_date, m.product_id,m.price,
case when s.order_date >= mb.join_date then 'Y'
else 'N' end as member
from sales s
join menu m on s.product_id = m.product_id
left join members mb on s.customer_id = mb.customer_id
order by s.customer_id, s.order_date;
	
--12. Rank all the things:
WITH customer_data AS (
    SELECT s.customer_id, 
           s.order_date, 
           m.product_name, 
           m.price,  -- Fixed aliasing issue
           CASE    
               WHEN s.order_date < mb.join_date THEN 'N'
               WHEN s.order_date >= mb.join_date THEN 'Y'
               ELSE 'N' 
           END AS member
    FROM sales s
    LEFT JOIN members mb ON s.customer_id = mb.customer_id
    JOIN menu m ON s.product_id = m.product_id
)
SELECT *,
       CASE 
           WHEN member = 'N' THEN NULL
           ELSE RANK() OVER (PARTITION BY customer_id, member ORDER BY order_date)
       END AS ranking
--12. Rank all the things:	   
WITH customer_data AS (
    SELECT s.customer_id, 
           s.order_date, 
           m.product_name, 
           m.price,  -- Fixed aliasing issue
           CASE    
               WHEN s.order_date < mb.join_date THEN 'N'
               WHEN s.order_date >= mb.join_date THEN 'Y'
               ELSE 'N' 
           END AS member
    FROM sales s
    LEFT JOIN members mb ON s.customer_id = mb.customer_id
    JOIN menu m ON s.product_id = m.product_id
)
SELECT *,
       CASE 
           WHEN member = 'N' THEN NULL
           ELSE RANK() OVER (PARTITION BY customer_id, member ORDER BY order_date)
       END AS ranking
FROM customer_data
ORDER BY customer_id, order_date;

	
	
	
	
	
	
	
	
	
	
	
