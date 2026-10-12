-- 50,000 customers and 1,000,000 orders. Deliberately shaped so the optimizer has
-- something to get wrong: STATUS is heavily skewed, and CITY and COUNTRY are
-- correlated (every Pune customer is in India), which the optimizer does not know.
ALTER SESSION DISABLE PARALLEL DML;

CREATE TABLE customers (
  customer_id   NUMBER        PRIMARY KEY,
  full_name     VARCHAR2(60)  NOT NULL,
  country       VARCHAR2(30)  NOT NULL,
  city          VARCHAR2(30)  NOT NULL,
  segment       VARCHAR2(12)  NOT NULL,
  signup_date   DATE          NOT NULL
);

INSERT INTO customers
SELECT level,
       'Customer ' || level,
       CASE MOD(level, 10) WHEN 0 THEN 'India' WHEN 1 THEN 'India' WHEN 2 THEN 'India'
            WHEN 3 THEN 'USA' WHEN 4 THEN 'USA' WHEN 5 THEN 'UK'
            WHEN 6 THEN 'Germany' WHEN 7 THEN 'Japan' WHEN 8 THEN 'Brazil' ELSE 'France' END,
       CASE MOD(level, 10) WHEN 0 THEN 'Mumbai' WHEN 1 THEN 'Pune' WHEN 2 THEN 'Delhi'
            WHEN 3 THEN 'New York' WHEN 4 THEN 'Chicago' WHEN 5 THEN 'London'
            WHEN 6 THEN 'Berlin' WHEN 7 THEN 'Tokyo' WHEN 8 THEN 'Sao Paulo' ELSE 'Paris' END,
       CASE WHEN MOD(level, 20) = 0 THEN 'PLATINUM'
            WHEN MOD(level, 5) = 0 THEN 'GOLD' ELSE 'STANDARD' END,
       DATE '2020-01-01' + MOD(level * 7, 2000)
  FROM dual CONNECT BY level <= 50000;

CREATE TABLE orders (
  order_id      NUMBER        PRIMARY KEY,
  customer_id   NUMBER        NOT NULL REFERENCES customers,
  order_date    DATE          NOT NULL,
  status        VARCHAR2(10)  NOT NULL,
  channel       VARCHAR2(10)  NOT NULL,
  amount        NUMBER(10,2)  NOT NULL,
  notes         VARCHAR2(200)
);

-- 99% of orders are DELIVERED; PENDING is 0.1% - 1,000 rows out of a million.
INSERT /*+ APPEND */ INTO orders
SELECT level,
       MOD(ORA_HASH(level, 1000003), 50000) + 1,
       DATE '2024-01-01' + MOD(level, 900),
       CASE WHEN MOD(level, 1000) = 0 THEN 'PENDING'
            WHEN MOD(level, 1000) BETWEEN 1 AND 4 THEN 'CANCELLED'
            WHEN MOD(level, 1000) BETWEEN 5 AND 9 THEN 'SHIPPED'
            ELSE 'DELIVERED' END,
       CASE MOD(level, 3) WHEN 0 THEN 'WEB' WHEN 1 THEN 'MOBILE' ELSE 'STORE' END,
       ROUND(10 + MOD(ORA_HASH(level, 99991), 99000) / 100, 2),
       RPAD('order note ', 60 + MOD(level, 100), 'x')
  FROM dual CONNECT BY level <= 1000000;
COMMIT;

CREATE INDEX orders_status_ix ON orders (status);
CREATE INDEX customers_city_ix ON customers (city);

-- Statistics without histograms: the optimizer knows STATUS has four values and
-- nothing about how unevenly they are spread.
BEGIN
  DBMS_STATS.GATHER_TABLE_STATS(USER, 'CUSTOMERS', method_opt => 'FOR ALL COLUMNS SIZE 1');
  DBMS_STATS.GATHER_TABLE_STATS(USER, 'ORDERS',    method_opt => 'FOR ALL COLUMNS SIZE 1');
END;
/

SELECT table_name, num_rows, blocks, last_analyzed FROM user_tables ORDER BY table_name;
