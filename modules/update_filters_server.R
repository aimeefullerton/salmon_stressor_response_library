# modules/update_filters_server.R
# nolint start
update_filters_server <- function(input, output, session, data, db) {

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

# This only runs when the app starts (Initial Population)
  observe({
    req(input$main_navbar == "dashboard")
    # Loop through and populate everything ONCE
    for (spec in filter_specs) {
      choices <- get_dynamic_vals(data, spec$col)
      updateSelectizeInput(session, spec$id, choices = choices, server = TRUE)
    }
  }, once = TRUE)

  # This ONLY runs when the user clicks the "Update Filter Options" button
  observeEvent(input$apply_cascading, {
    current_selections <- lapply(filter_specs, function(spec) input[[spec$id]])
    names(current_selections) <- sapply(filter_specs, function(s) s$id)

    for (spec in filter_specs) {
      df_sub <- data
      for (other_spec in filter_specs) {
        if (other_spec$id != spec$id) {
          df_sub <- apply_filter(df_sub, current_selections[[other_spec$id]], other_spec$col)
        }
      }
      valid_choices <- get_dynamic_vals(df_sub, spec$col)
      
      updateSelectizeInput(session, spec$id,
        choices  = valid_choices,
        selected = current_selections[[spec$id]],
        server   = TRUE 
      )
    }
    showNotification("Filter options updated based on your selections.", type = "message")
  })
}
# nolint end
