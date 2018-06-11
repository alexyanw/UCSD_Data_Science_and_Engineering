-- I put all tables/query in schema 'final'
set search_path TO final;

-- i
SELECT count(*) AS wins 
FROM matches m 
WHERE m.hteam = 'San Diego Sockers' AND hscore > vscore OR 
      m.vteam = 'San Diego Sockers' AND hscore < vscore
;

-- ii
/*
Create a view 'matchpoints' for each (team, opponent and point earned) from 'matches', unioned with initial 0 point for each team.
Create a materialized view 'scoreboard' since it can be reused in (iv), and (vi) will add trigger to auto refresh this 'view'.
I need write this view with a real table since postgresql doesn't allow insert/update on materialized view. Equivalent materialized view included in comment.
CREATE MATERIALIZED VIEW scoreboard(team, points) AS
SELECT team, SUM(point) as points
FROM matchpoints
GROUP BY team;
*/
CREATE VIEW matchpoints(team, opponent, point) AS
SELECT name AS team, '' AS opponent, 0 AS point FROM teams
UNION ALL 
SELECT hteam AS name, vteam AS opponent, 2 AS point FROM matches WHERE hscore > vscore 
UNION ALL 
SELECT vteam AS name, hteam AS opponent, 3 AS point FROM matches WHERE hscore < vscore 
UNION ALL 
SELECT hteam AS name, vteam AS opponent, 1 AS point FROM matches WHERE hscore = vscore 
UNION ALL 
SELECT vteam AS name, hteam AS opponent, 1 AS point FROM matches WHERE hscore = vscore 
;

CREATE table scoreboard(
    team text,
    points int
);
INSERT INTO scoreboard
(SELECT team, SUM(point) as points
 FROM matchpoints
 GROUP BY team
);
SELECT team as name, points
FROM scoreboard
;

-- iii
/*
Explanation:
  To find undefeated coach, just find the coarch with the team that doesn't lose any match
  If a team lose a match, we will see a record in view 'matchpoints' that has point > 1, in that case
  matchpoints.team is winner and matchpoints.opponent is loser for that match.
*/
SELECT coach
FROM teams t
WHERE NOT EXISTS (SELECT 1
                  FROM matchpoints mp
                  WHERE t.name = mp.opponent AND mp.point > 1)
;

-- iv 
/*
Explanation:
  Create a utility view 'leaders' used as subquery in the final answer.
  To find the teams only defeated by leaders, we can find the teams that
  not lose a match to some team that is not in leaders.
*/ 
CREATE VIEW leaders (team) AS 
SELECT s.team FROM scoreboard s 
WHERE s.points = (SELECT MAX(points) FROM scoreboard)
;

SELECT t.name
FROM teams t
WHERE NOT EXISTS (
        SELECT 1
        FROM matchpoints mp
        WHERE t.name = mp.opponent AND mp.point > 1 AND
              mp.team NOT IN (SELECT team FROM leaders))
;

-- (v) For each query in Problems (i) through (iv), create useful indexes or
-- explain why there are none.
/* (i) index created as below
Explanation:
  If there're small number of teams and thus not big number of total matches, we don't need index,
  because the DB driver may optimized to do sequencial scan of whole match table for specified team.
  The indexes below assumes there're certain big number of teams and matches. And thus driver will choose
  to do index scan to locate specified team.
*/
CREATE INDEX matches_hteam_idx on matches(hteam);
CREATE INDEX matches_vteam_idx on matches(vteam);
/* (ii) no index
Explanation:
  The query is mainly an aggregate function on the view I built on top of matches, 
  and the query doesn't have any join or selective condition involved.
  So no index is needed here.
*/
/* (iii) no index
Explanation:
  The plan of the query I give is doing hash anti join of 'teams' and view 'matchpoints' on teams.name = matchpoints.opponent where index won't help.
  And only other condition is 'matchpoints.point > 1' which is actually resolved into comparison between 'matches.hscore' and 'vscore'.
  So no index is needed here.
*/
/* (iv) index created below
Explanation:
  Similar to iii, the joins involved in this query plan are hash anti join which index doesn't help.
  The index I choose is on 'scoreboard.points' that will help on locate the leader which has max value of points.
*/
CREATE INDEX scoreboard_idx on scoreboard(points);
  
-- (vi) Assume that the result of the query in Problem (ii) is materialized in
-- a table called Scoreboard. Write triggers to keep the Scoreboard up to date
-- when the matches table is inserted into, respectively updated. The resulting
-- Scoreboard updates should be incremental (i.e. do not recompute Scoreboard
-- from scratch).
/* 
Explanation:
  2 triggers created, one for insert, the other for update on 'matches'.
*/
CREATE TRIGGER update_scoreboard_on_match_insert
AFTER INSERT ON matches
FOR EACH ROW
BEGIN 
  IF NEW.hscore > NEW.vscore THEN
    UPDATE scoreboard SET points=points+2 WHERE team=NEW.hteam;
  ELSIF NEW.hscore < NEW.vscore THEN
    UPDATE scoreboard SET points=points+3 WHERE team=NEW.vteam;
  ELSE
    UPDATE scoreboard SET points=points+1 WHERE team=NEW.hteam or team=NEW.vteam;
  END IF;
END;

CREATE TRIGGER update_scoreboard_on_match_update
AFTER UPDATE ON matches
FOR EACH ROW
BEGIN 
  IF OLD.hscore > OLD.vscore THEN
    UPDATE scoreboard SET points=points-2 WHERE team=OLD.hteam;
  ELSIF OLD.hscore < OLD.vscore THEN
    UPDATE scoreboard SET points=points-3 WHERE team=OLD.vteam;
  ELSE
    UPDATE scoreboard SET points=points-1 WHERE team=OLD.hteam or team=OLD.vteam;
  END IF;
  
  IF NEW.hscore > NEW.vscore THEN
    UPDATE scoreboard SET points=points+2 WHERE team=NEW.hteam;
  ELSIF NEW.hscore < NEW.vscore THEN
    UPDATE scoreboard SET points=points+3 WHERE team=NEW.vteam;
  ELSE
    UPDATE scoreboard SET points=points+1 WHERE team=NEW.hteam or team=NEW.vteam;
  END IF;
END;

