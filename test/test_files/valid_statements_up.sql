-- IF --
SELECT COUNT(*) AS CNTREC FROM pragma_table_info('transactions') WHERE name='from_doc' != 0;
SELECT COUNT(*) AS CNTREC FROM pragma_table_info('transactions') WHERE name='from_doc' != 0;
-- UP --
ALTER TABLE transactions ADD COLUMN from_doc INT NOT NULL DEFAULT 1;
ALTER TABLE transactions ADD COLUMN doc_from INT NOT NULL DEFAULT 0;
-- UPDATE transactions SET from_doc = 1;
-- Comment node
-- IF --
select COUNT(*) from pragma_table_info('transactions') where name = 'from_doc' = 1;
-- DOWN --
ALTER TABLE transactions DROP COLUMN from_doc;