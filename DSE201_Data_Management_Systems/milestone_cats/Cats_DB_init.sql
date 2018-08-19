CREATE SCHEMA cats;

-- Create necessary tables
CREATE TABLE cats."user"
(
  user_id serial primary key NOT NULL,
  user_name character varying(50) NOT NULL,
  facebook_id character varying(50) NOT NULL
);

CREATE TABLE cats.video
(
  video_id serial primary key NOT NULL,
  video_name character varying(50) NOT NULL
);

CREATE TABLE cats.login
(
  login_id serial primary key NOT NULL,
  user_id integer references cats."user" (user_id) NOT NULL,
  "time" timestamp without time zone NOT NULL
);

CREATE TABLE cats.watch
(
  watch_id serial primary key NOT NULL,
  video_id integer references cats.video (video_id) NOT NULL,
  user_id integer references cats."user" (user_id) NOT NULL,
  "time" timestamp without time zone NOT NULL
);

CREATE TABLE cats.friend
(
  user_id integer references cats."user" (user_id) NOT NULL,
  friend_id integer references cats."user" (user_id) NOT NULL
);

CREATE TABLE cats."likes"
(
  like_id serial primary key NOT NULL,
  user_id integer references cats."user" (user_id) NOT NULL,
  video_id integer references cats.video (video_id) NOT NULL,
  "time" timestamp without time zone NOT NULL
);

CREATE TABLE cats.suggestion
(
  suggestion_id serial primary key NOT NULL,
  login_id integer references cats.login(login_id) NOT NULL,
  video_id integer references cats.video (video_id) NOT NULL
);

-- Loading sample data into sales
-- COPY <table_name> FROM <location in your computer> DELIMITER ',' CSV;
-- ie. COPY video FROM 'c:\wenyan\dse\UCSD_Data_Science_and_Engineering\DSE201\video.txt' DELIMITER ',' CSV;
COPY cats."user" FROM 'c:\wenyan\dse\UCSD_Data_Science_and_Engineering\DSE201_Data_Management_Systems\milestone_cats\user.csv' DELIMITER ',' CSV;
COPY cats.video FROM 'c:\wenyan\dse\UCSD_Data_Science_and_Engineering\DSE201_Data_Management_Systems\milestone_cats\video.csv' DELIMITER ',' CSV;
COPY cats.friend FROM 'c:\wenyan\dse\UCSD_Data_Science_and_Engineering\DSE201_Data_Management_Systems\milestone_cats\friend.csv' DELIMITER ',' CSV;
COPY cats.likes FROM 'c:\wenyan\dse\UCSD_Data_Science_and_Engineering\DSE201_Data_Management_Systems\milestone_cats\likes.csv' DELIMITER ',' CSV;
