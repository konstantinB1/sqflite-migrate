-- UP -- 
CREATE TABLE IF NOT EXISTS test_table (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL
);

-- DOWN --
DROP TABLE test_table;