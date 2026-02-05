#!/usr/bin/env Rscript
## Migration script: convert CSV text stored in `csv_data_json` (text) into a proper jsonb column
## for the `stressor_responses` table, replacing the text column with jsonb.
##
## Usage: set Postgres connection env vars (PGHOST, PGPORT, PGUSER, PGPASSWORD, PGDATABASE)
## then run:
##
##   Rscript scripts/migrate_csv_text_to_jsonb.R
##
## The script will:
##  - check the current data type of `csv_data_json` on `stressor_responses`.
##  - if it's text/character, create a new `csv_data_json_new jsonb` column,
##    convert existing text CSV values into JSON (array of row objects) and store into the new column,
##  - then drop the old column and rename the new one to `csv_data_json`.
##
## This script is conservative and runs inside a transaction; review logs before committing on production.

suppressPackageStartupMessages({
  library(DBI)
  library(RPostgres)
  library(jsonlite)
  library(readr)
})

get_env <- function(key, required = FALSE) {
  v <- Sys.getenv(key, unset = NA)
  if (required && (is.na(v) || v == "")) stop(sprintf("Environment variable %s is required", key))
  v
}

host <- get_env("DB_HOST", required = TRUE)
port <- as.integer(get_env("DB_PORT", required = TRUE))
dbname <- get_env("DB_NAME", required = TRUE)
user <- get_env("DB_USER", required = TRUE)
password <- get_env("DB_PASSWORD", required = TRUE)
schema <- get_env("DB_SCHEMA", required = TRUE)

conn <- NULL
tryCatch(
  {
    conn <- dbConnect(RPostgres::Postgres(), host = host, port = port, user = user, password = password, dbname = dbname, schema = schema)
  },
  error = function(e) {
    stop("Failed to connect to the database: ", conditionMessage(e))
  }
)

tbl <- "stressor_responses"
col <- "csv_data_json"

msg <- function(...) cat(sprintf(...), "\n")

info <- dbGetQuery(conn, "SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'stressor_responses' AND column_name = 'csv_data_json'")
if (nrow(info) == 0) {
  msg("Column '%s.%s' not found. Creating new jsonb column 'csv_data_json'.", tbl, col)
  dbExecute(conn, sprintf("ALTER TABLE %s ADD COLUMN %s jsonb", tbl, col))
  dbDisconnect(conn)
  quit(save = "no", status = 0)
}

current_type <- info$data_type[1]
msg("Current column type for %s.%s: %s", tbl, col, current_type)

if (tolower(current_type) %in% c("json", "jsonb")) {
  msg("Column already JSON/JSONB; no migration needed.")
  dbDisconnect(conn)
  quit(save = "no", status = 0)
}

# We'll create a new jsonb column and populate it
new_col <- "csv_data_json_new"
msg("Adding temporary column %s (%s) ...", new_col, "jsonb")
dbExecute(conn, sprintf("ALTER TABLE %s ADD COLUMN %s jsonb", tbl, new_col))

rows <- dbGetQuery(conn, sprintf("SELECT id, %s FROM %s WHERE %s IS NOT NULL", col, tbl, col))
if (nrow(rows) == 0) {
  msg("No rows with non-null %s to convert.", col)
  # safe cleanup: drop new column and exit
  dbExecute(conn, sprintf("ALTER TABLE %s DROP COLUMN %s", tbl, new_col))
  dbDisconnect(conn)
  quit(save = "no", status = 0)
}

msg("Converting %d rows...", nrow(rows))

dbBegin(conn)
converted <- 0L
errors <- list()
for (i in seq_len(nrow(rows))) {
  rid <- rows$id[i]
  txt <- rows[[col]][i]
  # attempt to detect if value is already JSON by checking first non-space character
  trimmed_txt <- sub("^\\s+", "", txt)
  is_json_like <- nchar(trimmed_txt) > 0 && substring(trimmed_txt, 1, 1) %in% c("[", "{")
  tryCatch(
    {
      if (is_json_like) {
        # Attempt to parse as JSON. If it's an array/object, convert to data.frame if possible.
        parsed <- tryCatch(fromJSON(txt), error = function(e) NULL)
        if (!is.null(parsed) && (is.data.frame(parsed) || (is.list(parsed) && length(parsed) > 0))) {
          df <- as.data.frame(parsed, stringsAsFactors = FALSE, optional = TRUE)
        } else {
          # Fall back to CSV parsing if JSON parsing didn't produce a usable structure
          df <- readr::read_csv(txt, show_col_types = FALSE)
        }
      } else {
        # Robust CSV parsing using readr
        df <- readr::read_csv(txt, show_col_types = FALSE)
      }

      # Ensure consistent column names and types for JSON conversion
      if (!is.data.frame(df)) df <- as.data.frame(df, stringsAsFactors = FALSE)

      # Convert to JSON rows; preserve NA as JSON null
      json_out <- toJSON(df, dataframe = "rows", auto_unbox = TRUE, na = "null")

      # write to new column (parameterized)
      dbExecute(conn, sprintf("UPDATE %s SET %s = $1 WHERE id = $2", tbl, new_col), params = list(json_out, rid))
      converted <- converted + 1L
    },
    error = function(e) {
      errors[[length(errors) + 1]] <<- list(id = rid, error = conditionMessage(e))
      msg("Error converting id=%s: %s", rid, conditionMessage(e))
    }
  )
}

if (length(errors) > 0) {
  msg("%d rows failed to convert. Rolling back transaction.", length(errors))
  dbRollback(conn)
  msg("Errors (sample up to 10):")
  print(head(errors, 10))
  dbDisconnect(conn)
  quit(save = "no", status = 1)
} else {
  msg("All rows converted successfully (%d). Swapping columns...", converted)
  # Drop old text column and rename new -> csv_data_json
  dbExecute(conn, sprintf("ALTER TABLE %s DROP COLUMN %s", tbl, col))
  dbExecute(conn, sprintf("ALTER TABLE %s RENAME COLUMN %s TO %s", tbl, new_col, col))
  dbCommit(conn)
  msg("Migration complete. Column '%s' is now jsonb.", col)
}

dbDisconnect(conn)
