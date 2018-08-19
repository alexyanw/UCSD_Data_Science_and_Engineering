-- Option "Overall Likes": The Top-10 cat videos are the ones that have collected the highest numbers of likes, overall.
SELECT v.video_id, v.video_name, COUNT(*) like_count
FROM cats.video v, cats.likes l
WHERE v.video_id = l.video_id
GROUP BY v.video_id
ORDER BY like_count DESC LIMIT 10
;

-- Option "Friend Likes": The Top-10 cat videos are the ones that have collected the highest numbers of likes from the friends of X.
SELECT v.video_id, v.video_name, COUNT(*) like_count
FROM cats.video v, cats.likes l
WHERE v.video_id = l.video_id 
  AND l.user_id IN (SELECT f.friend_id
                    FROM cats.user u, cats.friend f
                    WHERE u.user_id = f.user_id AND u.user_name = 'X')
GROUP BY v.video_id
ORDER BY like_count DESC LIMIT 10
;

-- Option "Friends-of-Friends Likes": The Top-10 cat videos are the ones that have collected the highest numbers of likes from 
-- friends and friends-of-friends
SELECT v.video_id, v.video_name, COUNT(*) like_count
FROM cats.video v, cats.likes l
WHERE v.video_id = l.video_id 
  AND l.user_id IN ((select f.friend_id
                    FROM cats.user u, cats.friend f
                    WHERE u.user_id = f.user_id
                      AND u.user_name = 'X'
                   ) UNION
                   (SELECT ff.friend_id
                    FROM cats.user u, cats.friend f, cats.friend ff
                    WHERE u.user_id = f.user_id AND f.friend_id = ff.user_id 
                      AND u.user_name = 'X'
                   ))
GROUP BY v.video_id
ORDER BY like_count DESC LIMIT 10
;

-- Option "My kind of cats": The Top-10 cat videos are the ones that have collected the most likes
-- from users who have liked at least one cat video that was liked by X.
SELECT v.video_id, v.video_name, COUNT(*) like_count
FROM cats.video v, cats.likes l
WHERE v.video_id = l.video_id 
  AND l.user_id IN (select l1.user_id
                    FROM cats.likes l1, cats.likes l2, cats.user u
                    WHERE l1.video_id = l2.video_id AND l2.user_id = u.user_id AND u.user_name = 'X'
                   )
GROUP BY v.video_id
ORDER BY like_count DESC LIMIT 10
;

-- Option "My kind of cats - with preference"
WITH user_weight AS
(SELECT l.user_id, LOG(1+COUNT(*)) AS weight
 FROM cats.likes l
 WHERE l.video_id in (SELECT xl.video_id
                      FROM cats.user u, cats.likes xl
                      WHERE u.user_id = xl.user_id
                      AND u.user_name = 'X')
 GROUP BY l.user_id)
SELECT v.video_id, v.video_name, SUM(w.weight) score
FROM user_weight w, cats.likes l, cats.video v
WHERE w.user_id = l.user_id AND v.video_id = l.video_id
GROUP BY v.video_id
ORDER BY score DESC
LIMIT 10
