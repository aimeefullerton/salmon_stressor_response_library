update_filters_server <- function(input, output, session, data, db) {
  # 1) Define all filters in one place
  filter_specs <- list(
    stressor = list(
      input_id = "stressor",
      column = "stressor_name",
      table = "stressor_responses",
      regex = FALSE
    ),
    stressor_metric = list(
      input_id = "stressor_metric",
      column = "specific_stressor_metric",
      table = "stressor_responses",
      regex = FALSE
    ),
    species = list(
      input_id = "species",
      column = "species_common_name",
      table = "stressor_responses",
      regex = FALSE
    ),
    geography = list(
      input_id = "geography",
      column = "geography",
      table = "stressor_responses",
      regex = FALSE
    ),
    life_stage = list(
      input_id = "life_stage",
      column = "life_stages",
      table = "stressor_responses",
      regex = TRUE
    ),
    activity = list(
      input_id = "activity",
      column = "activity",
      table = "stressor_responses",
      regex = FALSE
    ),
    genus_latin = list(
      input_id = "genus_latin",
      column = "genus_latin",
      table = "stressor_responses",
      regex = FALSE
    ),
    species_latin = list(
      input_id = "species_latin",
      column = "species_latin",
      table = "stressor_responses",
      regex = FALSE
    ),
    research_article_type = list(
      input_id = "research_article_type",
      column = "research_article_type",
      table = "stressor_responses",
      regex = FALSE
    ),
    location_country = list(
      input_id = "location_country",
      column = "location_country",
      table = "stressor_responses",
      regex = FALSE
    ),
    location_state_province = list(
      input_id = "location_state_province",
      column = "location_state_province",
      table = "stressor_responses",
      regex = FALSE
    ),
    location_watershed_lab = list(
      input_id = "location_watershed_lab",
      column = "location_watershed_lab",
      table = "stressor_responses",
      regex = FALSE
    ),
    location_river_creek = list(
      input_id = "location_river_creek",
      column = "location_river_creek",
      table = "stressor_responses",
      regex = FALSE
    ),
    broad_stressor_name = list(
      input_id = "broad_stressor_name",
      column = "broad_stressor_name",
      table = "stressor_responses",
      regex = FALSE
    )
  )

  # helper: apply one filter to df
  apply_filter <- function(df, vals, col, regex) {
    if (is.null(vals) || length(vals) == 0) {
      return(df)
    }
    if (regex) {
      keep <- Reduce(`|`, lapply(vals, function(v) {
        grepl(v, df[[col]], ignore.case = TRUE)
      }), init = FALSE)
      df[keep, ]
    } else {
      df[df[[col]] %in% vals, ]
    }
  }

  # Helper: apply a filter conditionally
  apply_filter <- function(df, vals, col, regex) {
    if (is.null(vals) || length(vals) == 0) {
      return(df)
    }
    if (regex) {
      keep <- Reduce(`|`, lapply(vals, function(v) {
        grepl(v, df[[col]], ignore.case = TRUE)
      }), init = FALSE)
      df[keep, ]
    } else {
      df[df[[col]] %in% vals, ]
    }
  }

  # Helper: clean comma-separated life_stages
  clean_life_stages <- function(vec) {
    parts <- unique(unlist(strsplit(vec, ","), use.names = FALSE))
    parts <- trimws(gsub('["\\[\\]]', "", parts))
    parts[parts != ""]
  }

  # Observe and update all filters based on current selections
  observe({
    for (name in names(filter_specs)) {
      spec <- filter_specs[[name]]

      # Filter data using all OTHER filters
      df_sub <- data
      for (other in filter_specs[names(filter_specs) != name]) {
        vals <- input[[other$input_id]]
        df_sub <- apply_filter(df_sub, vals, other$column, other$regex)
      }

      # Get full set of lookup values
      lookup_vals <- dbGetQuery(
        db,
        sprintf("SELECT DISTINCT %s FROM stressor_responses ORDER BY %s", spec$column, spec$column)
      )[[spec$column]]

      # Get dynamic subset based on filtered data
      if (spec$regex) {
        dynamic_vals <- clean_life_stages(df_sub[[spec$column]])
      } else {
        dynamic_vals <- unique(df_sub[[spec$column]])
        dynamic_vals <- dynamic_vals[!is.na(dynamic_vals)]
      }

      # Intersect: only show valid choices in UI
      valid_choices <- lookup_vals[lookup_vals %in% dynamic_vals]

      # Update filter with valid choices only
      updatePickerInput(session, spec$input_id,
        choices  = valid_choices,
        selected = intersect(input[[spec$input_id]], valid_choices)
      )
    }
  })
}
