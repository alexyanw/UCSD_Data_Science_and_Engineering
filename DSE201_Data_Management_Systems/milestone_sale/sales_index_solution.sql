/* NOTE:
1. I don't cover index for primary key for all queries, since they're created by default
2. For the cold run, I run 'DISCARD ALL' cmd. Run time is messured in unit of milliseconds, and taken average value by 3 times.
3. Data set is from Tony.
  <table>: <count>
  customer: 10
  product: 10
  category: 10
  sale: 1000
  state: 50
4. Run this SQL file will create all index.
*/


-- query1: 
/*
Index solution: no more index is needed.
Explanation: 
  The plan is doing a left join on 'customer c' to 'sale s' based on 'c.customer_id=s.customer_id' which is already a primary key in customer.
  'customer.customer_id' is already been used as index for this left join. So no more index is needed here.
  Run time:
    without index: 184
    with index: same
*/

-- query2: 
/*
Index solution: no more index is needed.
Explanation: 
  This plan is doing 3 left joins, which are 
  1> left join from q1: 'customer' to 'sale' on 'c.customer_id=s.customer_id'
  2> 'state s' to 'customer c' on 's.state_id=c.state_id' which is already a primary key in 'state', and already been used for hash join from the plan.
  3> left join on results of 2> to 1> on 'c.customer_id=c1.customer_id', which is again the primary key in 'customer'.
  So no more index is needed here.
Run time:
  without index: 174
  with index: same
*/

-- query3:
-- index solution
CREATE INDEX sales_cid on sales.sale(customer_id);
/* 
Explanation:
The plan is doing aggregation on a single table 'sale' based on querying condition 'customer_id=?'
So setup index on sale.customer_id will improve the search performance in most likely case that there is not big portion of sale records satisfying the condition.
Run time:
  without index: 155
  with index: 150
*/

-- query4:
/*
Index solution:
  Probably no index is needed here.
  tentatively tried a compound index on sale(customer_id, product_id) as below, but didn't see any change in plan.
    CREATE INDEX sales_cpid on sales.sale(customer_id, product_id);
Explanation:
  The plan is doing cross join on 'customer' and 'product', then left join the result to 'sale' on c.customer_id = s.customer_id AND p.product_id = s.product_id
  As 1st round, the cross join need nested loop anyway, so no index can help here.
  In 2nd round, the plan is sorting both side of the left join and then doing merge join, which is already the optimized plan as I can think of.
  I tentatively tried a compound index on sale(customer_id, product_id) to see whether the plan could change to hash merge in 2nd round, but not really happen as expected.
  A compound index is not winning here probably because the tables to be join are big and index of the smaller table may not be loaded into memory in just once, 
  which will result in multiple loop. Let alone the cost of compound index itself.
Run time:
  without index: 7000
  with index: same
*/

-- query5
/*
Index solution:
  No index is needed here.
Explanation:
  The plan can be described by function: left_join(cross_join(state, category), q4)
  This is basically same thing with query4, just with one more cross join on 'state' and 'category', and left join on top of query4.
  So again, nothing can be done on the cross join on 'state' and 'category', and plan chooses to do sorting and merge join on the subquery results and query4.
  Same reason as query4, this 'sorting and merge' is already kind of optimized plan that setting index on 'customer.state_id' or 'product.category_id' 
    won't benefit the plan to change to hash join.
  Well, the 'group by' and 'order by' in query4 seem redundant for query5, removing them from query4 may reduce one aggregate and sort from query5, 
    but doesn't change the plan generally, and produce same runtime.
Run time:
  without index: 440
  with index: same
*/

-- query6
/*
Index solution:
  No index is needed here.
Explanation:
  The plan is can be described by function:
    left_join(cross_join(q1, q5), q4)), which is left_join(cross_join(q1, left_join(cross_join(state, category), q4)), q4)).
  As discovered in previous queries, no index can improve performance on q1, q4. And no index can help on cross_join(state, category) either.
  But we noticed subquery q4 appeared twice in the plan. In the plan flow chart, I see q4 is expanded in both cases. 
  I'm not sure whether the DB engine will be smart enough to execute q4 only once and cache the result if possible. 
  Without introducing materialized view, I can't find a way to help improve the plan by just adding index.
Run time:
  without index: 508
  With index: same
*/
