library(DBI)
library(RSQLite)
library(RPostgres)
library(pool)

con <- dbConnect(SQLite(), dbname = "path/to/your_database.sqlite")

# function to populate from stressor_responses
populate_from_main <- function(con) {
  mapping <- list(
    stressor_names        = "stressor_name",
    stressor_metrics      = "specific_stressor_metric",
    species_common_names  = "species_common_name",
    geographies           = "geography",
    life_stages           = "life_stages",
    activities            = "activity",
    genus_latins          = "genus_latin",
    species_latins        = "species_latin"
  )

  for (tbl in names(mapping)) {
    col <- mapping[[tbl]]
    sql <- sprintf(
      "INSERT OR IGNORE INTO %s(name)
         SELECT DISTINCT %s
         FROM stressor_responses
        WHERE %s IS NOT NULL
          AND TRIM(%s) <> '';",
      tbl, col, col, col
    )
    dbExecute(con, sql)
    message("Populated ", tbl)
  }
}

populate_from_main(con)

dbDisconnect(con)
