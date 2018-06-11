-- Create tables for cat videos
CREATE TABLE users (
    id          SERIAL PRIMARY KEY,
    name        TEXT,
    facebook    TEXT,
    end_time    TIME
);
CREATE TABLE friends (
    subject     INTEGER REFERENCES users (ID) NOT NULL,
    object      INTEGER REFERENCES users (ID) NOT NULL
);
CREATE TABLE videos (
    id          SERIAL PRIMARY KEY,
    name        TEXT
);
CREATE TABLE likes (
    id          SERIAL PRIMARY KEY,
    usr         INTEGER REFERENCES users (id) NOT NULL,
    video       INTEGER REFERENCES videos (id) NOT NULL,
    at          TIME
);
CREATE TABLE logins (
    id          SERIAL PRIMARY KEY,
    usr         INTEGER REFERENCES users (id) NOT NULL,
    at          TIME
);
CREATE TABLE suggests (
    id          SERIAL PRIMARY KEY,
    login       INTEGER REFERENCES logins (id) NOT NULL,
    video       INTEGER REFERENCES videos (id) NOT NULL
);
