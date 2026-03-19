# PostgreSQL maintenance utilities for nwfsc_public_dev database

library(DBI)
library(RPostgres)

# Load environment variables
db_config <- list(
  host = Sys.getenv("DB_HOST", "localhost"),
  port = as.integer(Sys.getenv("DB_PORT", "5432")),
  dbname = Sys.getenv("DB_NAME", "nwfsc_public_dev"),
  user = Sys.getenv("DB_USER", "postgres"),
  password = Sys.getenv("DB_PASSWORD", ""),
  schema = Sys.getenv("DB_SCHEMA", "stressor_responses")
)

# Connect to PostgreSQL
connect_db <- function() {
  con <- dbConnect(
    RPostgres::Postgres(),
    host = db_config$host,
    port = db_config$port,
    dbname = db_config$dbname,
    user = db_config$user,
    password = db_config$password
  )
  dbExecute(con, sprintf("SET search_path TO %s, public", db_config$schema))
  return(con)
}

# Populate lookup tables from main table
populate_lookup_tables <- function(con) {
  mapping <- list(
    stressor_names = "stressor_name",
    stressor_metrics = "specific_stressor_metric",
    species_common_names = "species_common_name",
    geographies = "geography",
    activities = "activity",
    genus_latins = "genus_latin",
    species_latins = "species_latin",
    research_article_types = "research_article_type",
    location_countries = "location_country",
    location_states_provinces = "location_state_province",
    location_watersheds_labs = "location_watershed_lab",
    location_rivers_creeks = "location_river_creek",
    broad_stressor_names = "broad_stressor_name"
  )

  for (tbl in names(mapping)) {
    col <- mapping[[tbl]]
    sql <- sprintf(
      "INSERT INTO %s.%s(name)
       SELECT DISTINCT %s
       FROM %s.stressor_responses
       WHERE %s IS NOT NULL
         AND TRIM(%s) <> ''
       ON CONFLICT (name) DO NOTHING",
      db_config$schema, tbl, col, db_config$schema, col, col
    )
    rows <- dbExecute(con, sql)
    message(sprintf("Populated %s: %d new entries", tbl, rows))
  }
}

# Remove duplicate entries from lookup tables (case-insensitive)
deduplicate_lookup_tables <- function(con) {
  lookup_tables <- c(
    "stressor_names", "stressor_metrics", "species_common_names",
    "geographies", "life_stages", "activities", "genus_latins",
    "species_latins", "research_article_types", "location_countries",
    "location_states_provinces", "location_watersheds_labs",
    "location_rivers_creeks", "broad_stressor_names"
  )

  for (tbl in lookup_tables) {
    sql <- sprintf(
      "DELETE FROM %s.%s a
       USING %s.%s b
       WHERE a.id > b.id
         AND LOWER(a.name) = LOWER(b.name)",
      db_config$schema, tbl, db_config$schema, tbl
    )
    rows <- dbExecute(con, sql)
    if (rows > 0) {
      message(sprintf("Removed %d duplicates from %s", rows, tbl))
    }
  }
}

# Get database statistics
get_db_stats <- function(con) {
  tables <- dbGetQuery(con, sprintf("
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = '%s'
    ORDER BY table_name
  ", db_config$schema))

  stats <- list()
  for (tbl in tables$table_name) {
    count <- dbGetQuery(con, sprintf(
      "SELECT COUNT(*) as n FROM %s.%s",
      db_config$schema, tbl
    ))$n
    stats[[tbl]] <- count
  }

  return(stats)
}

# Example usage:
if (interactive()) {
  con <- connect_db()

  # Get current stats
  cat("\n=== Database Statistics ===\n")
  stats <- get_db_stats(con)
  for (tbl in names(stats)) {
    cat(sprintf("%-30s: %d rows\n", tbl, stats[[tbl]]))
  }

  # Uncomment to run maintenance tasks:
  # populate_lookup_tables(con)
  # deduplicate_lookup_tables(con)

  dbDisconnect(con)
}
