-- IF --
SELECT COUNT(*) AS CNTREC FROM pragma_table_info('transactions') WHERE name='from_doc' != 0;
-- UP --