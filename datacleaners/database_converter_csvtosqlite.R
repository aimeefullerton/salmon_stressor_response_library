library(DBI)
library(RSQLite)
library(jsonlite)

csv_file <- "all_stressor_responses.csv"
sqlite_file <- "stressor_responses.sqlite"

# Read and clean CSV
df <- read.csv(csv_file, fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE)
colnames(df) <- gsub("ï»¿", "", colnames(df))
colnames(df) <- gsub("\\.", "_", colnames(df))
colnames(df) <- gsub("[^[:alnum:]_ %()]", "", colnames(df))

# Parse the csv_data_json into a long format table
safe_parse_csv_data_json <- function(json_str, id, stressor_name) {
  if (is.na(json_str) || json_str == "") return(NULL)
  parsed <- tryCatch(jsonlite::fromJSON(json_str), error = function(e) NULL)
  if (is.null(parsed) || length(parsed) < 2) return(NULL)
  
  header <- parsed[1, ]
  data <- parsed[-1, , drop = FALSE]
  df <- as.data.frame(data, stringsAsFactors = FALSE)
  colnames(df) <- header
  
  # Normalize column names before parsing
  colnames(df) <- gsub("\\.", "_", colnames(df))  # e.g., low.limit -> low_limit
  
  x_col <- colnames(df)[1]
  y_col <- colnames(df)[2]
  
  result <- data.frame(
    id = id,
    row_index = seq_len(nrow(df)),
    stressor_label = x_col,
    stressor_value = suppressWarnings(as.numeric(df[[x_col]])),
    scaled_response_label = y_col,
    scaled_response_value = suppressWarnings(as.numeric(df[[y_col]])),
    article_stressor_label = stressor_name,
    stringsAsFactors = FALSE
  )
  
  # Add optional columns if present (use normalized names)
  if ("SD" %in% colnames(df)) {
    result$sd <- suppressWarnings(as.numeric(df[["SD"]]))
  }
  if ("low_limit" %in% colnames(df)) {
    result$low_limit <- suppressWarnings(as.numeric(df[["low_limit"]]))
  }
  if ("up_limit" %in% colnames(df)) {
    result$up_limit <- suppressWarnings(as.numeric(df[["up_limit"]]))
  }
  
  return(result)
}


csv_long_list <- lapply(seq_len(nrow(df)), function(i) {
  safe_parse_csv_data_json(df$csv_data_json[i], df$id[i], df$stressor_name[i])
})
csv_data_table <- do.call(rbind, csv_long_list)

# Write to SQLite
db <- dbConnect(SQLite(), sqlite_file)
dbWriteTable(db, "stressor_responses", df, overwrite = TRUE)
dbWriteTable(db, "csv_data_table", csv_data_table, overwrite = TRUE)
dbDisconnect(db)

cat("SQLite database created:", sqlite_file, "\n")
