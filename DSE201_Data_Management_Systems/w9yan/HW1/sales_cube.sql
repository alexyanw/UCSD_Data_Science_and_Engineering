-- Create tables 
CREATE TABLE customers (
    id          SERIAL PRIMARY KEY,
    name        TEXT,
    state       TEXT,
    end_time    TIME
);
CREATE TABLE categories (
    id          SERIAL PRIMARY KEY,
    name        TEXT,
    description TEXT
);
CREATE TABLE products (
    id          SERIAL PRIMARY KEY,
    name        TEXT,
    list_price  FLOAT,
    category    INTEGER REFERENCES categories (id) NOT NULL
);
CREATE TABLE sales (
    id          SERIAL PRIMARY KEY,
    customer    INTEGER REFERENCES customers (id) NOT NULL,
    product     INTEGER REFERENCES products (id) NOT NULL,
    quantity    INTEGER,
    price       FLOAT
);

