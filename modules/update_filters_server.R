# nolint start
update_filters_server <- function(input, output, session, data, db) {

  # 1. Standard config (Keep as is)
  array_cols <- c(
    "species_common_name", "latin_name", "life_stages", "activity", "season",
    "location_country", "location_state_province",
    "location_watershed_lab", "location_river_creek", "function_derivation"
  )

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

  # ... (Keep apply_filter and get_dynamic_vals helpers exactly as they are) ...
  apply_filter <- function(df, vals, col) {
    if (is.null(vals) || length(vals) == 0) return(df)
    if (col %in% array_cols) {
      keep <- vapply(df[[col]], function(cell) {
        if (is.na(cell) || !nzchar(cell)) return(FALSE)
        cell_parts <- trimws(strsplit(as.character(cell), ",")[[1]])
        any(cell_parts %in% vals)
      }, logical(1))
    } else {
      keep <- df[[col]] %in% vals
    }
    df[keep, ]
  }

  get_dynamic_vals <- function(df, col) {
    if (nrow(df) == 0) return(character(0))
    clean_cells <- df[[col]][!is.na(df[[col]]) & df[[col]] != ""]
    if (col %in% array_cols) {
      parts <- unlist(lapply(clean_cells, function(x) trimws(strsplit(as.character(x), ",")[[1]])))
      vals <- unique(parts)
    } else {
      vals <- unique(clean_cells)
    }
    vals <- vals[vals != "" & vals != "NA" & vals != "NULL"]
    return(sort(vals))
  }

  # 2. THE SECRET SAUCE: Debounced Input Watcher
  # This collects all filter inputs into one bucket and waits 800ms 
  # after the last click before telling the server to update choices.
  to_watch <- reactive({
    lapply(filter_specs, function(s) input[[s$id]])
  })
  
  # Wait for 800ms of "silence" before triggering cascading updates
  debounced_watch <- to_watch %>% debounce(800)

  # 3. Automatic Cascading Observer
  observeEvent(debounced_watch(), {
    req(input$main_navbar == "dashboard")
    
    # Get the static values currently in the inputs
    current_selections <- isolate(to_watch())
    names(current_selections) <- sapply(filter_specs, function(s) s$id)

    for (spec in filter_specs) {
      # Calculate subset of valid data based on OTHER selections
      df_sub <- data
      for (other_spec in filter_specs) {
        if (other_spec$id != spec$id) {
          df_sub <- apply_filter(df_sub, current_selections[[other_spec$id]], other_spec$col)
        }
      }

      valid_choices <- get_dynamic_vals(df_sub, spec$col)
      
      # Stop the loop: only update if the choices are actually different
      # We use 'freeze' to keep the UI from jumping
      freezeReactiveValue(input, spec$id)
      
      updateSelectizeInput(session, spec$id,
        choices  = valid_choices,
        selected = current_selections[[spec$id]],
        server   = TRUE 
      )
    }
  }, ignoreInit = FALSE)
}
# nolint end
