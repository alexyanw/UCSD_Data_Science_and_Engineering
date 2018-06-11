/* NOTE:
1. I don't cover index for primary key for all queries, since they're created by default
2. For the cold run, I stop and restart postgresql service. Run time is messured in unit of milliseconds, and taken average value by 3 times.
3. Data set is from Kyle.
  <table>: <count>
  friend: 19780
  likes: 9998
  login: 19998
  suggestion: 4999
  user: 4999
  video: 2999
  watch: 19998
4. Run this SQL file will create all index.
*/

-- query1: overall likes
-- index solution:
CREATE INDEX likes_uid on cats.likes(user_id);
CREATE INDEX watch_uid on cats.watch(user_id);
/*
Experiment on index but not taken.
-- CREATE INDEX likes_vid on cats.likes(video_id);
-- CREATE INDEX watch_vid on cats.watch(video_id);
-- DROP INDEX cats.likes_vid;
-- DROP INDEX cats.watch_vid;
  Tried above 2 indices in hope for improving on below conditions, but not actually happen.
  	 not exists (select 1 from watch w where w.user_id = o.uid and w.video_id = o.vid) and
	 not exists (select 1 from likes l where l.user_id = o.uid and l.video_id = o.vid) 
Explanation:
  The index on likes.user_id and watch.user_Id will help on subquery condition 'where w.user_id = o.uid' and 'where l.user_id = o.uid'
  The 2 indices will benefit all queries below due to the 2 conditions are shared by all of them. I won't mention them again due to same reason.
Run time:
  Without index:  230
  with index: 225

*/  

-- query2: friend likes
-- index solution:
CREATE INDEX friend_uid on cats.friend(user_id);
--CREATE INDEX likes_uid on cats.likes(user_id);  -- already created for query1
/*
Explanation:
  index 'friend_uid' helps on view 'friendLikes' condition 'f.user_id = u.user_id' given user_id is an input.
  index 'likes_uid' helps on view 'friendLikes' joining likes and friends on l.user_id = f.friend_id
Run time:
  without index: 242
  with index: 231
*/

-- query3: friends of friends likes
-- index solution: no more index is needed
/*
Experiment but not taken
  CREATE INDEX friend_fid on cats.friend(friend_id);
Explanation:
  This query does extra work on getting subquery of fof likes than query2(friendLikes).
  The view 'cats.fof' already utilized index 'friend_uid' created previously. 
  And tentative try on index friend.friend_id doesn't change plan for below subquery
      'not exists (select 1 from friend g where g.user_id = u.user_id and g.friend_id = fof.friend_id);'
  So no more index need be added.
Run time:
  Without index: 251
  with index: : 221
*/

-- query4: my kinds likes
-- index solution:
CREATE INDEX likes_vid on cats.likes(video_id);
/*
Explanation:
  The extra work for this query than overallLikes is adding view 'mykindofUsers' and 'mykindLikes'.
  The 2 views already benefit on index 'likes_uid' created in previous query. 
  And the index 'likes_vid' improve query plan for view 'mykindofUsers' on 'ul.video_id = ol.video_id;', 
    which changed the hash inner join to nested loop inner join.
Run time:
  without index: 242
  with index: 212
*/

-- query5: weighted my kind likes
-- index solution:
--CREATE INDEX likes_vid on cats.likes(video_id);  -- duplicate: already created in query4
--CREATE INDEX likes_uid on cats.likes(user_id);   -- duplicate: already created in query1
/*
Explanation:
  The 'likes_vid' will benefit on view 'cats.commonLikes' joining condition 'l1.video_id = l2.video_id'.
  And 'likes_uid' will benefit on view 'cats.weightedMykindLikes' joining condition 'l.user_id = i.y'. 
Run time:
  without index: 228
  with index: 210
*/
