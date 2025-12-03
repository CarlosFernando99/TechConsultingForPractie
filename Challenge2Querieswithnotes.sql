-- CARLOS FERNANDO ARRIOLA GUTIERREZ
-- 1. What is the total amount each customer spent at the restaurant?
SELECT
	s.customer_id,
    SUM(m.price) AS total_spent
FROM sales s
JOIN menu m ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;
-- 2. How many days has each customer visited the restaurant?
SELECT
	s.customer_id,
    count(DISTINCT order_date) AS customer_visits
FROM sales s
GROUP BY s.customer_id
ORDER BY s.customer_id;

-- 3. What was the first item from the menu purchased by each customer?
WITH RankedSales AS (
    SELECT
        s.customer_id,
        m.product_name,
        s.order_date,
        ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS purchase_rank
    FROM
        sales s
    JOIN
        menu m ON s.product_id = m.product_id
)
SELECT
    customer_id,
    product_name
FROM
    RankedSales
WHERE
    purchase_rank = 1;
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT
    s.customer_id,
    m.product_name,
    COUNT(s.product_id) AS times_purchased
FROM
    sales s
JOIN
    menu m ON s.product_id = m.product_id
WHERE
    s.product_id = (
        -- Subconsulta para encontrar el ID del producto más comprado
        SELECT
            product_id
        FROM
            sales
        GROUP BY
            product_id
        ORDER BY
            COUNT(product_id) DESC
        LIMIT 1
    )
GROUP BY
    s.customer_id, m.product_name
ORDER BY
    s.customer_id;

-- 5. Which item was the most popular for each customer?
WITH CustomerPopularity AS (
    SELECT
        s.customer_id,
        m.product_name,
        COUNT(s.product_id) AS item_count,
        RANK() OVER (PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC) AS rank_popularity
    FROM
        sales s
    JOIN
        menu m ON s.product_id = m.product_id
    GROUP BY
        s.customer_id, m.product_name
)
SELECT
    customer_id,
    product_name,
    item_count
FROM
    CustomerPopularity
WHERE
    rank_popularity = 1;

-- 6. Which item was purchased first by the customer after they became a member?
WITH MemberFirstPurchase AS (
    SELECT
        s.customer_id,
        s.order_date,
        m.product_name,
        ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS rn
    FROM
        sales s
    JOIN
        members mem ON s.customer_id = mem.customer_id
    JOIN
        menu m ON s.product_id = m.product_id
    WHERE
        s.order_date >= mem.join_date
)
SELECT
    customer_id,
    product_name,
    order_date
FROM
    MemberFirstPurchase
WHERE
    rn = 1;

-- 7. Which item was purchased just before the customer became a member?
WITH BeforeMemberPurchase AS (
    SELECT
        s.customer_id,
        s.order_date,
        m.product_name,
        ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS rn
    FROM
        sales s
    JOIN
        members mem ON s.customer_id = mem.customer_id
    JOIN
        menu m ON s.product_id = m.product_id
    WHERE
        s.order_date < mem.join_date
)
SELECT
    customer_id,
    product_name,
    order_date
FROM
    BeforeMemberPurchase
WHERE
    rn = 1;

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT
    s.customer_id,
    COUNT(s.product_id) AS total_items,
    SUM(m.price) AS total_spent
FROM
    sales s
JOIN
    members mem ON s.customer_id = mem.customer_id
JOIN
    menu m ON s.product_id = m.product_id
WHERE
    s.order_date < mem.join_date
GROUP BY
    s.customer_id
ORDER BY
    s.customer_id;
    
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT
    s.customer_id,
    SUM(
        CASE
            WHEN m.product_name = 'sushi' THEN m.price * 2 * 10 -- 2x por sushi * 10 puntos por $1
            ELSE m.price * 10                                  -- 10 puntos por $1
        END
    ) AS total_points
FROM
    sales s
JOIN
    menu m ON s.product_id = m.product_id
GROUP BY
    s.customer_id
ORDER BY
    s.customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT
    s.customer_id,
    SUM(
        CASE
            -- Caso 1: Primera semana (2x en todo)
            WHEN s.order_date >= mem.join_date
                 AND s.order_date < DATE_ADD(mem.join_date, INTERVAL 6 DAY) -- DATE(mem.join_date, '+7 day') -- o DATE_ADD(mem.join_date, INTERVAL 6 DAY) dependiendo de tu dialecto SQL
            THEN m.price * 2 * 10
            -- Caso 2: Sushi (2x) fuera de la primera semana
            WHEN m.product_name = 'sushi'
            THEN m.price * 2 * 10
            -- Caso 3: Todo lo demás (1x)
            ELSE m.price * 10
        END
    ) AS total_points_january
FROM
    sales s
JOIN
    menu m ON s.product_id = m.product_id
LEFT JOIN
    members mem ON s.customer_id = mem.customer_id
WHERE
    s.customer_id IN ('A', 'B') -- Solo clientes A y B
    AND s.order_date <= '2021-01-31' -- Solo hasta el final de enero
GROUP BY
    s.customer_id
ORDER BY
    s.customer_id;