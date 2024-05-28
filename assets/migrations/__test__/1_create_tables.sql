-- UP -- 
CREATE TABLE IF NOT EXISTS test_table (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS test_table2 (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL
);

-- DOWN --
DROP TABLE test_table;
DROP TABLE test_table2;