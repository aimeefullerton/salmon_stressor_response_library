
library(DBI)
library(RSQLite)

add_columns <- function(db_path, table_name) {
  con <- dbConnect(SQLite(), dbname = db_path)
  on.exit(dbDisconnect(con), add = TRUE)
  
  info     <- dbGetQuery(con, sprintf("PRAGMA table_info(%s);", table_name))
  existing <- info$name
  
  cols_to_add <- list(
    stressor_category        = "TEXT",
    research_article_type    = "TEXT",
    location_country         = "TEXT",
    location_state_province  = "TEXT",
    location_watershed_lab   = "TEXT",
    location_river_creek     = "TEXT"
  )
  
  # Iterate and ALTER TABLE 
  for (col in names(cols_to_add)) {
    if (!(col %in% existing)) {
      sql <- sprintf(
        "ALTER TABLE %s ADD COLUMN %s %s;",
        table_name, col, cols_to_add[[col]]
      )
      dbExecute(con, sql)
      message("Added column: ", col)
    } else {
      message("ℹ️ Column already exists, skipping: ", col)
    }
  }
}
