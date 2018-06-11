-- solution:
-- q1
create materialized view sales.q1_materialized 
  (customer_id, quantity_sold, dollar_value)
  as
  select * from sales.q1;

-- q4
create materialized view sales.q4_materialized 
  (customer_id, customer_name, product_id, quantity_sold, dollar_value, state_id, category_id)
  as
  select * from sales.q4;

create index q4_materialized_customer_category_idx 
  on sales.q4_materialized(customer_id,category_id);

-- top_category without limit 20
create materialized view sales.top_category_materialized 
  (category_id, dollar_value)
  as
  SELECT c.category_id,
         coalesce (SUM (q.dollar_value), 0.0) AS dollar_value
  FROM sales.category c LEFT JOIN sales.q4_materialized q ON c.category_id = q.category_id
  GROUP BY  c.category_id
  ORDER BY dollar_value DESC;


-- new query to be used:
SET search_path TO sales;

SELECT ca.category_id, cu.customer_id, 
   coalesce (SUM (q.quantity_sold), 0) AS quantity_sold,
   coalesce (SUM (q.dollar_value), 0.0) AS dollar_value
FROM (
      (SELECT customer_id
       FROM q1_materialized
       ORDER BY dollar_value DESC
       LIMIT 20) cu
      CROSS JOIN 
       (SELECT * FROM top_category_materialized LIMIT 20) ca
    )
    LEFT JOIN q4_materialized q 
              ON q.customer_id = cu.customer_id AND q.category_id = ca.category_id
GROUP BY  ca.category_id, cu.customer_id;

/*
Explanation:
  Problem3 has following views involved which I put in a tree structure.
  q6 -
     |-- top_customer -- q1
     |-- top_category -- q5 -- q4
     |-- q4

  I choose to materialize q1, q4 and top_category based on following consideration:
  a> Materialized q1 and q4 can directly benefit other queries like q1, q4 and q5
  b> top_customer is just the first 20 top rows of q1. Materializ this table won't gain extra benefit than materializing q1.
  c> top_category is materialized by droping 'limit 20', so we can get top N categories on fly. And since top categories should be stable due to product's nature and should be a small table. So it's worth to materialize it to save the computation of aggregation and sorting.
  d> An compound index is set up on q4_materialized that benefit on final left join.

Run time messured:
  no index, no materialized view: 508
  with materialized view: 190
  with index and materialized view: 170
*/

