# Load necessary libraries
library(DBI)
library(RSQLite)

# Connect to the db
con <- dbConnect(SQLite(), "data/stressor_responses.sqlite")

# Create the new `csv_meta` table
dbExecute(con, "
  CREATE TABLE IF NOT EXISTS csv_meta (
    csv_id INTEGER PRIMARY KEY AUTOINCREMENT,
    article_id INTEGER,
    stressor_label TEXT,
    scaled_response_label TEXT,
    article_stressor_label TEXT,
    csv_data_json TEXT,
    upload_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );
")

# Create the new `csv_numeric` table
dbExecute(con, "
  CREATE TABLE IF NOT EXISTS csv_numeric (
    numeric_id INTEGER PRIMARY KEY AUTOINCREMENT,
    csv_id INTEGER,
    row_index INTEGER,
    stressor_value REAL,
    scaled_response_value REAL,
    sd REAL,
    low_limit REAL,
    up_limit REAL,
    FOREIGN KEY(csv_id) REFERENCES csv_meta(csv_id)
  );
")

# Disconnect
dbDisconnect(con)

print("Tables created successfully!")
