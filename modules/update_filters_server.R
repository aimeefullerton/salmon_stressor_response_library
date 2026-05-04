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

  observe({
    req(input$main_navbar == "dashboard")
    
    # Capture current state
    current_inputs <- lapply(filter_specs, function(spec) input[[spec$input_id]])
    names(current_inputs) <- names(filter_specs)

    for (name in names(filter_specs)) {
      spec <- filter_specs[[name]]
      
      # Filter data by OTHER selections
      df_sub <- data
      for (other_name in names(filter_specs)) {
        if (other_name != name) {
          other_spec <- filter_specs[[other_name]]
          df_sub <- apply_filter(df_sub, current_inputs[[other_name]], other_spec$column)
        }
      }

      valid_choices <- get_dynamic_vals(df_sub, spec$column)
      
      # THE SAFETY VALVE: Prevents glitching loop
      freezeReactiveValue(input, spec$input_id)
      
      updateSelectizeInput(session, spec$input_id,
        choices  = valid_choices,
        selected = current_inputs[[name]],
        server   = TRUE 
      )
    }
  })
}
# nolint end
