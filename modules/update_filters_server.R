# nolint start
update_filters_server <- function(input, output, session, data, db) {

  # 1. Define exactly which columns are Postgres Arrays
  array_cols <- c(
    "species_common_name", "latin_name", "life_stages", "activity", "season",
    "location_country", "location_state_province",
    "location_watershed_lab", "location_river_creek", "function_derivation"
  )

  # 2. Map the UI input IDs to the database column names
  filter_specs <- list(
    list(id = "stressor", col = "stressor_name"),
    list(id = "stressor_metric", col = "specific_stressor_metric"),
    list(id = "species", col = "species_common_name"),
    list(id = "life_stage", col = "life_stages"),
    list(id = "activity", col = "activity"),
    list(id = "latin_name", col = "latin_name"),
    list(id = "article_type", col = "article_type"),
    list(id = "location_country", col = "location_country"),
    list(id = "location_state_province", col = "location_state_province"),
    list(id = "location_watershed_lab", col = "location_watershed_lab"),
    list(id = "location_river_creek", col = "location_river_creek"),
    list(id = "broad_stressor_name", col = "broad_stressor_name")
  )

  # 3. Query PostgreSQL directly for the choices
  get_live_db_choices <- function(col_name) {
    tryCatch({
      
      # Ask Postgres to unnest the array and give us distinct values
      if (col_name %in% array_cols) {
        query <- sprintf("SELECT DISTINCT unnest(%s) AS val FROM stressor_responses WHERE %s IS NOT NULL", col_name, col_name)
      } else {
        # Standard distinct query for plain text columns
        query <- sprintf("SELECT DISTINCT %s AS val FROM stressor_responses WHERE %s IS NOT NULL", col_name, col_name)
      }

      # Fire the query directly to the database
      res <- dbGetQuery(db, query)

      # Clean up the SQL results
      vals <- unlist(res$val) 
      vals <- as.character(vals)
      vals <- trimws(vals)
      
      # Remove any garbage values that might exist in the database
      vals <- vals[!is.na(vals) & vals != "" & vals != "NA" & vals != "NULL"]

      return(sort(unique(vals)))
      
    }, error = function(e) {
      print(paste("❌ Live DB Query Failed for", col_name, ":", e$message))
      return(character(0))
    })
  }

  # 4. Populate the filters IMMEDIATELY on load using live database calls
  for (spec in filter_specs) {
    choices <- get_live_db_choices(spec$col)
    
    if (length(choices) > 0) {
      updatePickerInput(session, inputId = spec$id, choices = choices)
    }
  }

}
# nolint end
