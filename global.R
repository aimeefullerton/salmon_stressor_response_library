# nolint start

library(shiny)
library(DBI)
library(RSQLite)
library(RPostgres)
library(pool)

# Connect to SQLite database
db_path <- "data/stressor_responses.sqlite"
conn <- dbConnect(SQLite(), db_path)

# Check if the `stressor_responses` table exists before querying
if ("stressor_responses" %in% dbListTables(conn)) {
  # Load data from `stressor_responses`
  data <- dbGetQuery(conn, "SELECT * FROM stressor_responses")

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
} else {
  warning("Table `stressor_responses` does not exist in the database.")
}

# Close database connection to prevent memory leaks
dbDisconnect(conn)

# nolint end
