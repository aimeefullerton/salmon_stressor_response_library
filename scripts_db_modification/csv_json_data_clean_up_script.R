# nolint start

# -------------------------------------------------------------------------------------
# Purpose:
#   This script updates the `csv_data_json` column in the `stressor_responses` table
#   by converting existing CSV data stored in an "array of arrays" format into a
#   cleaner, more structured "array of named objects" format.
#
#   Example transformation:
#   From:
#     [["Header1", "Header2"], ["Val1", "Val2"], ["Val3", "Val4"]]
#   To:
#     [{"Header1": "Val1", "Header2": "Val2"}, {"Header1": "Val3", "Header2": "Val4"}]
#
# Why:
#   - The original format made downstream parsing, filtering, and visualization difficult.
#   - The new structure aligns better with JSON standards for tabular data
#     and simplifies data handling in the Shiny app (especially for download/export).
#
# Safety Measures:
#   - The original `csv_data_json` column was renamed to `csv_data_json_old` to preserve backup.
#   - Only rows with `main_id <= 132` were updated to exclude test entries.
#   - Only entries with valid JSON and well-structured data were processed.
#
# -------------------------------------------------------------------------------------


library(DBI)
library(RSQLite)
library(jsonlite)

# Connect to your SQLite database
con <- dbConnect(SQLite(), "data/stressor_responses.sqlite")

# Get all rows with main_id <= 132 and non-null old JSON
rows <- dbGetQuery(con, "
  SELECT main_id, csv_data_json_old 
  FROM stressor_responses 
  WHERE main_id <= 132 AND csv_data_json_old IS NOT NULL
")

# Function to convert array-of-arrays to array-of-named-objects
convert_to_named_json <- function(arrays) {
  if (!is.list(arrays) || length(arrays) < 2 || !is.vector(arrays[[1]])) {
    cat("Conversion skipped - structure mismatch\n")
    return(NULL)
  }

  headers <- arrays[[1]]
  data_rows <- arrays[-1]

  # Filter rows that match header length
  valid_rows <- Filter(function(row) length(row) == length(headers), data_rows)

  if (length(valid_rows) == 0) {
    cat("No valid data rows found\n")
    return(NULL)
  }

  named_list <- lapply(valid_rows, function(row) setNames(as.list(row), headers))
  return(named_list)
}

# Loop through and update each row
for (i in 1:nrow(rows)) {
  main_id <- rows$main_id[i]
  old_json <- rows$csv_data_json_old[i]

  parsed <- tryCatch({
    fromJSON(old_json, simplifyVector = FALSE)
  }, error = function(e) {
    cat("Failed to parse JSON for ID:", main_id, "\n")
    return(NULL)
  })

  if (!is.null(parsed)) {
    new_parsed <- convert_to_named_json(parsed)

    if (!is.null(new_parsed)) {
      new_json <- toJSON(new_parsed, auto_unbox = TRUE)
      dbExecute(con, "UPDATE stressor_responses SET csv_data_json = ? WHERE main_id = ?", 
                params = list(new_json, main_id))
      cat("Updated main_id:", main_id, "\n")
    } else {
      cat("Skipped main_id:", main_id, " - No valid rows\n")
    }
  } else {
    cat("Skipped main_id:", main_id, " - Invalid JSON\n")
  }
}

# Disconnect when done
dbDisconnect(con)

# nolint end
