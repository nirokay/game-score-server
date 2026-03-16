CREATE TABLE IF NOT EXISTS gamePopcat (
    timestamp INTEGER PRIMARY KEY UNIQUE NOT NULL,
    username WORD DEFAULT "",
    score INTEGER
);
