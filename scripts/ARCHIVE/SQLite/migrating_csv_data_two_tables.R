library(DBI)
library(jsonlite)
library(RSQLite)
library(RPostgres)
library(pool)

con <- dbConnect(SQLite(), "data/stressor_responses.sqlite")

# Get unique article IDs from current csv_data_table
article_ids <- dbGetQuery(con, "SELECT DISTINCT id FROM csv_data_table")$id

for (article_id in article_ids) {
  # Fetch existing csv data
  csv_data <- dbGetQuery(con, sprintf("SELECT * FROM csv_data_table WHERE id = %d", article_id))

  # Create JSON backup
  csv_json <- jsonlite::toJSON(csv_data, pretty = TRUE, dataframe = "rows")

  # Insert metadata
  dbExecute(con, "
    INSERT INTO csv_meta (article_id, stressor_label, scaled_response_label, article_stressor_label, csv_data_json)
    VALUES (?, ?, ?, ?, ?)",
    params = list(
      article_id,
      unique(csv_data$stressor_label)[1],
      unique(csv_data$scaled_response_label)[1],
      unique(csv_data$article_stressor_label)[1],
      csv_json
    )
  )

  # Retrieve new csv_id for numeric linkage
  csv_id <- dbGetQuery(con, "SELECT last_insert_rowid() AS id;")$id[1]

  # Prepare numeric data
  numeric_data <- data.frame(
    csv_id = csv_id,
    row_index = csv_data$row_index,
    stressor_value = csv_data$stressor_value,
    scaled_response_value = csv_data$scaled_response_value,
    sd = csv_data$sd,
    low_limit = csv_data$low_limit,
    up_limit = csv_data$up_limit
  )

  # Insert numeric data
  dbWriteTable(con, "csv_numeric", numeric_data, append = TRUE, row.names = FALSE)
}

dbDisconnect(con)
