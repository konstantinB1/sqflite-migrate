-- UP -- 
CREATE TABLE IF NOT EXISTS test_table7 (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    age INT NOT NULL
);

-- DOWN --
DROP TABLE test_table7;