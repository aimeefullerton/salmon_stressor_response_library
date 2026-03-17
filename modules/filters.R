# nolint start

# Helper: checks if any element of a list-column cell matches selected values
match_array_col <- function(col, selected) {
  vapply(col, function(cell) any(cell %in% selected), logical(1))
}

# Helper: checks if any element of a list-column cell matches a search term
search_array_col <- function(col, search_term) {
  vapply(col, function(cell) {
    any(grepl(search_term, tolower(cell), ignore.case = TRUE))
  }, logical(1))
}

filter_data_server <- function(input, data, session) {
  filtered_data <- reactive({
    req(!is.null(data), nrow(data) > 0)
    data_filtered <- data

    # text[] columns
    if (!is.null(input$species) && length(input$species) > 0)
      data_filtered <- data_filtered[match_array_col(data_filtered$species_common_name, input$species), ]

    if (!is.null(input$life_stage) && length(input$life_stage) > 0)
      data_filtered <- data_filtered[match_array_col(data_filtered$life_stages, input$life_stage), ]

    if (!is.null(input$activity) && length(input$activity) > 0)
      data_filtered <- data_filtered[match_array_col(data_filtered$activity, input$activity), ]

    if (!is.null(input$latin_name) && length(input$latin_name) > 0)
      data_filtered <- data_filtered[match_array_col(data_filtered$latin_name, input$latin_name), ]

    if (!is.null(input$location_country) && length(input$location_country) > 0)
      data_filtered <- data_filtered[match_array_col(data_filtered$location_country, input$location_country), ]

    if (!is.null(input$location_state_province) && length(input$location_state_province) > 0)
      data_filtered <- data_filtered[match_array_col(data_filtered$location_state_province, input$location_state_province), ]

    if (!is.null(input$location_watershed_lab) && length(input$location_watershed_lab) > 0)
      data_filtered <- data_filtered[match_array_col(data_filtered$location_watershed_lab, input$location_watershed_lab), ]

    if (!is.null(input$location_river_creek) && length(input$location_river_creek) > 0)
      data_filtered <- data_filtered[match_array_col(data_filtered$location_river_creek, input$location_river_creek), ]

    # Plain text columns
    if (!is.null(input$article_type) && length(input$article_type) > 0)
      data_filtered <- data_filtered[data_filtered$article_type %in% input$article_type, ]

    if (!is.null(input$broad_stressor_name) && length(input$broad_stressor_name) > 0)
      data_filtered <- data_filtered[data_filtered$broad_stressor_name %in% input$broad_stressor_name, ]

    if (!is.null(input$stressor) && length(input$stressor) > 0)
      data_filtered <- data_filtered[data_filtered$stressor_name %in% input$stressor, ]

    if (!is.null(input$stressor_metric) && length(input$stressor_metric) > 0)
      data_filtered <- data_filtered[data_filtered$specific_stressor_metric %in% input$stressor_metric, ]

    # Search
    if (!is.null(input$search) && input$search != "") {
      search_term <- tolower(input$search)

      plain_cols <- c(
        "article_id", "article_type", "title", "stressor_name", "broad_stressor_name",
        "specific_stressor_metric", "response", "overview",
        "transferability_of_function", "source_of_stressor_data"
      )
      array_cols <- c(
        "species_common_name", "latin_name", "life_stages", "activity", "season",
        "location_country", "location_state_province", "location_watershed_lab",
        "location_river_creek", "function_derivation"
      )

      if (nrow(data_filtered) > 0) {
        plain_matches <- Reduce(`|`, lapply(plain_cols, function(col) {
          grepl(search_term, tolower(as.character(data_filtered[[col]])), ignore.case = TRUE)
        }))
        array_matches <- Reduce(`|`, lapply(array_cols, function(col) {
          search_array_col(data_filtered[[col]], search_term)
        }))
        data_filtered <- data_filtered[plain_matches | array_matches, ]
      }
    }

    data_filtered
  })

  return(filtered_data)
}
# nolint end
