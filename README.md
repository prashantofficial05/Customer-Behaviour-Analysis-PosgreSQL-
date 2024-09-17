### Customer Behavior Analysis PostgreSQL-
                                                       

    Project Overview
    This project is part of a case study that analyzes customer behavior at Danny’s Diner, a small Japanese 
    restaurant serving sushi, curry, and ramen. The goal is to uncover patterns, trends, and insights into customer 
    preferences, purchasing habits, and potential areas for improvement in the restaurant’s menu and marketing 
    strategies. By leveraging data, the project aims to help Danny make informed business decisions to improve 
    customer satisfaction and boost restaurant performance.

   **Background:**
    At the start of 2021, Danny opened a cozy diner offering his three favorite Japanese dishes. To keep his 
    restaurant thriving, he needs to better understand his customers’ spending behavior and menu preferences. The 
    diner has gathered some basic data but cannot turn it into actionable insights. With this project, we analyze 
    the data to provide recommendations on expanding the customer loyalty program and refining menu offerings.

  **Problem:**
    Danny is looking to answer critical questions about his customers:

    1] What are the visiting patterns of the customers?
    2] How much have they spent?
    3] Which menu items are their favorites?
    Using this information, Danny plans to enhance the customer loyalty program and improve the overall dining 
    experience.

  **Key Objectives:**
  
    1] Analyze customer visit patterns and spending.
    
    2] Identify customer favorites on the menu.
    
    3] Could you provide recommendations to improve menu offerings and the loyalty program?

 **Skills Applied:**
 
    1] Window Functions 
    
    2] CTEs
    
    3] Aggregations 
    
    4] JOINs 
    
    5] Write scripts to generate basic reports that can be run every period 

  **Questions Explored:**

    1] What is the total amount each customer spent at the restaurant?
    2] How many days has each customer visited the restaurant?
    3] What was the first item from the menu purchased by each customer?
    4] What is the most purchased item on the menu and how many times was it purchased by all customers?
    5] Which item was the most popular for each customer?
    6] Which item was purchased first by the customer after they became a member?
    7] Which item was purchased just before the customer became a member?
    8] What is the total items and amount spent for each member before they became a member?
    9] If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each 
       customer have?
    10]In the first week after a customer joins the program (including their join date) they earn 2x points on all 
       items, not just sushi - how many points do customers A and B have at the end of January?


**Some interesting queries**
Q5 - Which item was the most popular for each customer?

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

Q10 - In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customers A and B have at the end of January?

    SELECT s.customer_id, SUM(
    CASE 
        WHEN s.order_date BETWEEN mb.join_date AND DATEADD(day, 7, mb.join_date) THEN m.price*20
        WHEN m.product_name = 'sushi' THEN m.price*20 
        ELSE m.price*10 
    END) AS total_points
    FROM sales s
    JOIN menu m ON s.product_id = m.product_id
    LEFT JOIN members mb ON s.customer_id = mb.customer_id
    WHERE s.customer_id IN ('A', 'B') AND s.order_date <= '2021-01-31'
    --WHERE s.customer_id = mb.customer_id AND s.order_date <= '2021-01-31'
    GROUP BY s.customer_id;

Bonus Q2 - Danny also requires further information about the ranking of products. he purposely does not need the ranking of non-member purchases so he expects NULL ranking values for customers who are not yet part of the loyalty program.

  
    WITH customers_data AS (
    SELECT 
    s.customer_id, s.order_date,  m.product_name, m.price,
    CASE
      WHEN s.order_date < mb.join_date THEN 'N'
      WHEN s.order_date >= mb.join_date THEN 'Y'
      ELSE 'N' END AS member
    FROM sales s
    LEFT JOIN members mb
    ON s.customer_id = mb.customer_id
    JOIN menu m
    ON s.product_id = m.product_id
    )
    SELECT 
  *, 
    
    CASE
    WHEN member = 'N' THEN NULL
    ELSE RANK () OVER(
      PARTITION BY customer_id, member
      ORDER BY order_date) END AS ranking
    FROM customers_data
    ORDER BY customer_id, order_date;

**Insights:**

    -- Customer B is the most frequent visitor with 6 visits in Jan 2021.
  
    -- Danny’s Diner’s most popular item is ramen, followed by curry and sushi.
  
    -- Customer A loves ramen, Customer C loves only ramen whereas Customer B seems to enjoy sushi, curry, and 
        ramen equally.
     
    -- The last items ordered by Customers A and B before they became members are sushi and curry. Does it mean 
       both of these items are the deciding factor?    
        


    
