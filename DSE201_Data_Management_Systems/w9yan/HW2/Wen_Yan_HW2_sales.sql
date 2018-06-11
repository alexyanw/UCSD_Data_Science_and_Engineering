-- 1. Show the total sales (quantity sold and dollar value) for each customer.
SELECT c.customer_id, c.customer_name, sum(s.quantity * s.price) total_sales
FROM sales.customer c, sales.sale s
WHERE c.customer_id = s.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY c.customer_id
;

-- 2. Show the total sales for each state.
SELECT st.state_id, st.state_name, sum(s.quantity * s.price) total_sales
FROM sales.customer c, sales.sale s, sales.state st
WHERE c.customer_id = s.customer_id AND c.state_id = st.state_id
GROUP BY st.state_id, st.state_name
ORDER BY st.state_id
;

-- 3. Show the total sales for each product, for a given customer. 
-- Only products that were actually bought by the given customer are listed order by dollarvalue.
SELECT c.customer_id, c.customer_name, p.product_id, p.product_name, sum(s.quantity * s.price) total_sales
FROM sales.customer c, sales.sale s,sales.product p
WHERE c.customer_id = s.customer_id AND s.product_id = p.product_id AND c.customer_name = 'X'
GROUP BY c.customer_id, c.customer_name, p.product_id, p.product_name
ORDER BY c.customer_id,total_sales DESC
;

-- 4. Show the total sales for each product and customer. Order by dollar value.
WITH customer_product AS
(SELECT c.customer_id, c.customer_name, p.product_id, p.product_name
FROM sales.customer c, sales.product p)
SELECT cp.product_id, cp.product_name, cp.customer_id, cp.customer_name, COALESCE(SUM(s.quantity * s.price), 0) total_sale
FROM customer_product cp LEFT OUTER JOIN sales.sale s 
  ON cp.product_id = s.product_id AND cp.customer_id = s.customer_id
GROUP BY cp.product_id, cp.product_name, cp.customer_id, cp.customer_name
ORDER BY total_sale DESC
;

-- 5. Show the total sales for each product category and state.
SELECT cat.category_id, cat.category_name, st.state_id, st.state_name, sum(s.quantity * s.price) total_sale
FROM sales.customer c, sales.sale s, sales.product p, sales.state st, sales.category cat
WHERE c.customer_id = s.customer_id AND c.state_id = st.state_id AND s.product_id = p.product_id AND cat.category_id = p.category_id
GROUP BY cat.category_id, cat.category_name, st.state_id, st.state_name
ORDER BY cat.category_id, st.state_id
;

-- 6. For each one of the top 20 product categories and top 20 customers, 
-- return a tuple (top product category, top customer, quantity sold, dollar value)
WITH top_category_customer AS
(SELECT cat.category_id, cat.category_name, c.customer_id, c.customer_name
FROM sales.category cat, sales.customer c
WHERE cat.category_id IN (SELECT top_cat.category_id
                          FROM sales.category top_cat, sales.product top_p, sales.sale top_ps
                          WHERE top_cat.category_id = top_p.category_id AND top_p.product_id = top_ps.product_id
                          GROUP BY top_cat.category_id
                          ORDER BY sum(top_ps.quantity * top_ps.price) DESC LIMIT 20)
  AND c.customer_id IN (SELECT top_c.customer_id
                        FROM sales.customer top_c, sales.sale top_cs
                        WHERE top_c.customer_id = top_cs.customer_id
                        GROUP BY top_c.customer_id
                        ORDER BY sum(top_cs.quantity * top_cs.price) DESC LIMIT 20)
                        )
SELECT t.category_id, t.category_name, t.customer_id, t.customer_name, COALESCE(SUM(s.quantity),0) quantity_sold, COALESCE(SUM(s.quantity * s.price), 0) dollar_value
FROM (sales.sale s JOIN sales.product p ON s.product_id = p.product_id) RIGHT OUTER JOIN top_category_customer t
 ON p.category_id = t.category_id AND s.customer_id = t.customer_id
GROUP BY t.category_id, t.category_name, t.customer_id, t.customer_name
ORDER BY t.category_id, t.customer_id
;
