# nolint start
update_filters_server <- function(input, output, session, data, db) {

  # Array columns (text[]) vs plain text columns
  array_cols <- c(
    "species_common_name", "latin_name", "life_stages", "activity",
    "location_country", "location_state_province",
    "location_watershed_lab", "location_river_creek"
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
        if (is.na(cell)) return(FALSE)
        # Split the string back into individual items using the comma-space
        cell_parts <- strsplit(cell, ", ")[[1]]
        any(cell_parts %in% vals)
      }, logical(1))
    } else {
      keep <- df[[col]] %in% vals
    }
    df[keep, ]
  }

# Get distinct values from a column for dropdown choices
  get_dynamic_vals <- function(df, col) {
    if (col %in% array_cols) {
      # Remove NAs, then split all strings by comma-space, then unlist to a flat vector
      clean_cells <- df[[col]][!is.na(df[[col]])]
      vals <- unique(unlist(strsplit(clean_cells, ", ")))
    } else {
      vals <- unique(df[[col]])
    }
    sort(vals[!is.na(vals) & nzchar(vals)])
  }

  observe({
    for (name in names(filter_specs)) {
      spec <- filter_specs[[name]]

      # Filter data using all OTHER active filters
      df_sub <- data
      for (other in filter_specs[names(filter_specs) != name]) {
        df_sub <- apply_filter(df_sub, input[[other$input_id]], other$column)
      }

      # Full universe of choices from the pre-loaded dataframe
      lookup_vals <- get_dynamic_vals(data, spec$column)

      # Dynamic subset from currently filtered data
      dynamic_vals <- get_dynamic_vals(df_sub, spec$column)

      # Only show choices that exist in both the DB universe and the filtered subset
      valid_choices <- lookup_vals[lookup_vals %in% dynamic_vals]

      updatePickerInput(session, spec$input_id,
        choices  = valid_choices,
        selected = intersect(input[[spec$input_id]], valid_choices)
      )
    }
  })
}
# nolint end
