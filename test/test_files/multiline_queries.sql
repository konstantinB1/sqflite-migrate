-- UP --
CREATE TABLE IF NOT EXISTS transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date INTEGER NOT NULL,
    sign TEXT NOT NULL,
    amount REAL NOT NULL,
    vendor_details TEXT NOT NULL,
    transaction_type TEXT NOT NULL,
    currency TEXT NOT NULL
);
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS category TEXT;
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS account_id INTEGER;
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS transaction_id TEXT;

-- DOWN --
DROP TABLE transactions IF EXISTS;