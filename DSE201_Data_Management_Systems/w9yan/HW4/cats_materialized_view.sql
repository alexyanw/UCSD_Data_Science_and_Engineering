-- solution:
create materialized view cats.inner_product_materialized 
  (x, y, prod)
  as
  select * from cats.inner_product;

create index inner_product_materialized_idx 
  on cats.inner_product_materialized(x);

-- new query to be used:
SET search_path TO cats;

select vid, sum(verdict) as rank
from (select  u.user_id as uid, l.video_id as vid, log(1+i.prod) as verdict
      from cats.user u, inner_product_materialized i, likes l
      where u.user_id = i.x and l.user_id = i.y) o
where o.uid = 1 and 
      not exists (select 1 from watch w where w.user_id = o.uid and w.video_id = o.vid) and
      not exists (select 1 from likes l where l.user_id = o.uid and l.video_id = o.vid) 
group by vid
order by rank desc
limit    10;

/*
Explanation:
  Comparing the 3 existing views to choose to materialize from.
  cats.commonLikes: No
    storage cost: product of any same likes from 2 different users.
    computation saved: nothing else than the joining
    maintenance cost: any change to user, likes need an update on this table
    index opportunity: None
  cats.inner_product: Yes
    storage cost: product of different users
    computation saved: aggregate 'sum' can be precomputed in this table
    maintenance cost: any change to user, likes need an update
    index opportunity: index on inner_product.x can benefit on later joining
  cats.weightedMyKindLikes: No
    size: product of user, neighbour and neighbour's likes
    computation saved: aggregate 'sum', and function 'log'
    maintenance cost: any change to user, likes need an update
    index opportunity: None
  
  From above, cats.inner_product is my choice to materialize due to consideration of both the cost and computation saved.

Run time messured:
  no index, no materialized view: 228
  with index(HW3): 210
  with materialized view: 4000
  with index and materialized view: 309 
The performance drop with materialized view vs index solution in HW3 is probably because the materialized view is big in size and the memory is not properly configured for postgresql.
*/
