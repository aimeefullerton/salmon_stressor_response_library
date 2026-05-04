# nolint start
update_filters_server <- function(input, output, session, data, db) {

  # Array columns (text[]) vs plain text columns
  array_cols <- c(
    "species_common_name", "latin_name", "life_stages", "activity", "season",
    "location_country", "location_state_province",
    "location_watershed_lab", "location_river_creek", "function_derivation"
  )

  filter_specs <- list(
    stressor = list(input_id = "stressor", column = "stressor_name"),
    stressor_metric = list(input_id = "stressor_metric", column = "specific_stressor_metric"),
    species = list(input_id = "species", column = "species_common_name"),
    life_stage = list(input_id = "life_stage", column = "life_stages"),
    activity = list(input_id = "activity", column = "activity"),
    latin_name = list(input_id = "latin_name", column = "latin_name"),
    article_type = list(input_id = "article_type", column = "article_type"),
    location_country = list(input_id = "location_country", column = "location_country"),
    location_state_province = list(input_id = "location_state_province", column = "location_state_province"),
    location_watershed_lab = list(input_id = "location_watershed_lab", column = "location_watershed_lab"),
    location_river_creek = list(input_id = "location_river_creek", column = "location_river_creek"),
    broad_stressor_name = list(input_id = "broad_stressor_name", column = "broad_stressor_name")
  )

# Apply one filter to a dataframe, aware of list vs plain columns
  apply_filter <- function(df, vals, col) {
    if (is.null(vals) || length(vals) == 0) return(df)
    if (col %in% array_cols) {
      keep <- vapply(df[[col]], function(cell) {
        if (is.na(cell) || !nzchar(cell)) return(FALSE)
        # Split the string back into individual items (handles commas with or without spaces)
        cell_parts <- trimws(strsplit(as.character(cell), ",")[[1]])
        any(cell_parts %in% vals)
      }, logical(1))
    } else {
      keep <- df[[col]] %in% vals
    }
    df[keep, ]
  }

# Get distinct values from a column for dropdown choices
  get_dynamic_vals <- function(df, col) {
    if (nrow(df) == 0) return(character(0))
    
    clean_cells <- df[[col]][!is.na(df[[col]]) & df[[col]] != ""]
    
    if (col %in% array_cols) {
      # Split all strings by comma, flatten, trim whitespace, and find unique
      parts <- unlist(lapply(clean_cells, function(x) trimws(strsplit(as.character(x), ",")[[1]])))
      vals <- unique(parts)
    } else {
      vals <- unique(clean_cells)
    }
    sort(vals[vals != "" & vals != "NA"])
  }

  # Main function to run the updates
  run_filter_updates <- function() {
    for (name in names(filter_specs)) {
      spec <- filter_specs[[name]]

      # Filter data using all OTHER active filters to get context-aware dropdowns
      df_sub <- data
      for (other in filter_specs[names(filter_specs) != name]) {
        # THE FIX: Isolate the input read so it doesn't crash outside the reactive loop!
        val <- isolate(input[[other$input_id]])
        df_sub <- apply_filter(df_sub, val, other$column)
      }

      # 1. Full universe of choices (from the entire downloaded dataset)
      lookup_vals <- get_dynamic_vals(data, spec$column)

      # 2. Dynamic subset from currently filtered data
      dynamic_vals <- get_dynamic_vals(df_sub, spec$column)

      # 3. Only show choices that exist in both the universe and the filtered subset
      valid_choices <- lookup_vals[lookup_vals %in% dynamic_vals]

      # THE FIX: Isolate the input read here too
      val_selected <- isolate(input[[spec$input_id]])
      
      updatePickerInput(session, spec$input_id,
        choices  = valid_choices,
        selected = intersect(val_selected, valid_choices)
      )
    }
  }

  # 1. Observe input changes to dynamically update filters
  observe({
    # Touch all inputs so this observe knows to re-run when users make selections
    lapply(filter_specs, function(x) input[[x$input_id]])
    
    # Do not run unless the dashboard is actually active
    req(input$main_navbar == "dashboard")
    
    run_filter_updates()
  })
  
  # 2. Force initialization only AFTER the UI has completely flushed to the browser!
  session$onFlushed(function() {
    isolate({
      run_filter_updates()
    })
  }, once = TRUE)

}
# nolint end
