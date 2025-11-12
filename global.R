# nolint start

library(shiny)
library(DBI)
library(RPostgres)
library(pool)

# Connect to Postgres database
db_config <- list(
  host = Sys.getenv("DB_HOST", "localhost"),
  port = as.integer(Sys.getenv("DB_PORT", "5432")),
  dbname = Sys.getenv("DB_NAME", "nwfsc_public_dev"),
  user = Sys.getenv("DB_USER", "postgres"),
  password = Sys.getenv("DB_PASSWORD", ""),
  schema = Sys.getenv("DB_SCHEMA", "stressor_responses")
)

# Validate configuration
if (db_config$password == "") {
  stop("Database password not found. Please check your .Renviron file.")
}

# create a connection pool (better practice than a single connection)
pool <- dbPool(
  drv = RPostgres::Postgres(),
  host = db_config$host,
  port = db_config$port,
  dbname = db_config$dbname,
  user = db_config$user,
  password = db_config$password,
  minSize = 1, # todo: ask Jim if there is preferred min/max sizes
  maxSize = 5
)

# set the search path to the schema
dbExecute(pool, sprintf("SET search_path TO %s, public", db_config$schema))

# test connection
tryCatch(
  {
    dbGetQuery(pool, "SELECT 1")
    message("db connection success")
  },
  error = function(e) {
    stop("db connection failed: ", e$message)
  }
)

# initialize all variables with empty vectors in case loading data fails
stressor_names <- character(0)
stressor_metrics <- character(0)
species_names <- character(0)
geographies <- character(0)
life_stages <- character(0)
activities <- character(0)
genus_latin <- character(0)
species_latin <- character(0)
research_article_types <- character(0)
location_countries <- character(0)
location_states_provinces <- character(0)
location_watersheds_labs <- character(0)
location_rivers_creeks <- character(0)
broad_stressor_names <- character(0)

# Check if the `stressor_responses` table exists
table_exists <- dbExistsTable(pool, Id(schema = db_config$schema, table = "stressor_responses"))

if (table_exists) {
  tryCatch(
    {
      # query with schema prefix
      data <- dbGetQuery(pool, sprintf("SELECT * FROM %s.stressor_responses", db_config$schema))

      # Extract unique values for original dropdowns
      stressor_names <- sort(unique(na.omit(data$stressor_name)))
      stressor_metrics <- sort(unique(na.omit(data$specific_stressor_metric)))
      species_names <- sort(unique(na.omit(data$species_common_name)))
      geographies <- sort(unique(na.omit(data$geography)))
      life_stages <- sort(unique(na.omit(data$life_stages)))
      activities <- sort(unique(na.omit(data$activity)))
      genus_latin <- sort(unique(na.omit(data$genus_latin)))
      species_latin <- sort(unique(na.omit(data$species_latin)))

      # Extract unique values for new metadata filters
      research_article_types <- sort(unique(na.omit(data$research_article_type)))
      location_countries <- sort(unique(na.omit(data$location_country)))
      location_states_provinces <- sort(unique(na.omit(data$location_state_province)))
      location_watersheds_labs <- sort(unique(na.omit(data$location_watershed_lab)))
      location_rivers_creeks <- sort(unique(na.omit(data$location_river_creek)))
      broad_stressor_names <- sort(unique(na.omit(data$broad_stressor_name)))

      message(sprintf("Loaded %d records from database.", nrow(data)))
    },
    error = function(e) {
      warning("failed to load data from stressor_responses: ", e$message)
    }
  )
} else {
  warning(sprintf("Table stressor_responses does not exist in schema %s", db_config$schema))
}

# pool will be closed automatically when the R session ends.
# another option: register an onStop callback to server.R

# nolint end
