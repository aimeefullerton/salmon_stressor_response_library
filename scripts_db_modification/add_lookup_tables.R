library(DBI)
library(RSQLite)
library(RPostgres)
library(pool)

setup_lookup_tables <- function(db_path) {
  con <- dbConnect(SQLite(), dbname = db_path)
  on.exit(dbDisconnect(con))

  lookup_defs <- list(
    stressor_names = "name TEXT UNIQUE NOT NULL",
    stressor_metrics = "name TEXT UNIQUE NOT NULL",
    species_common_names = "name TEXT UNIQUE NOT NULL",
    geographies = "name TEXT UNIQUE NOT NULL",
    life_stages = "name TEXT UNIQUE NOT NULL",
    activities = "name TEXT UNIQUE NOT NULL",
    genus_latins = "name TEXT UNIQUE NOT NULL",
    species_latins = "name TEXT UNIQUE NOT NULL",

    # New metadata lookups
    research_article_types = "name TEXT UNIQUE NOT NULL",
    location_countries = "name TEXT UNIQUE NOT NULL",
    location_states_provinces = "name TEXT UNIQUE NOT NULL",
    location_watersheds_labs = "name TEXT UNIQUE NOT NULL",
    location_rivers_creeks = "name TEXT UNIQUE NOT NULL",
    broad_stressor_names = "name TEXT UNIQUE NOT NULL"
  )

  for (tbl in names(lookup_defs)) {
    sql <- sprintf(
      "CREATE TABLE IF NOT EXISTS %s (
         id   INTEGER PRIMARY KEY,
         %s
       );",
      tbl, lookup_defs[[tbl]]
    )
    dbExecute(con, sql)
  }
}
