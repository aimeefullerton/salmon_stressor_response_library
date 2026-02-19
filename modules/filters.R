# nolint start

# Function to filter data based on user inputs
filter_data_server <- function(input, data, session) {
  filtered_data <- reactive({
    req(!is.null(data), nrow(data) > 0)
    data_filtered <- data

    # Applying filtering conditions for each selected filter
    # Filter: species common name
    if (!is.null(input$species) && length(input$species) > 0) {
      data_filtered <- data_filtered[data_filtered$species_common_name %in% input$species, ]
    }

    # Filter: life stage
    if (!is.null(input$life_stage) && length(input$life_stage) > 0) {
      data_filtered <- data_filtered[
        Reduce("|", lapply(input$life_stage, function(stage) {
          grepl(stage, data_filtered$life_stages, ignore.case = TRUE)
        })),
      ]
    }

    # Filter: activity
    if (!is.null(input$activity) && length(input$activity) > 0) {
      data_filtered <- data_filtered[data_filtered$activity %in% input$activity, ]
    }

    # Filter: genus latin
    if (!is.null(input$genus_latin) && length(input$genus_latin) > 0) {
      data_filtered <- data_filtered[data_filtered$genus_latin %in% input$genus_latin, ]
    }

    # Filter: species latin
    if (!is.null(input$species_latin) && length(input$species_latin) > 0) {
      data_filtered <- data_filtered[data_filtered$species_latin %in% input$species_latin, ]
    }

    if (!is.null(input$research_article_type) && length(input$research_article_type) > 0) {
      data_filtered <- data_filtered[data_filtered$research_article_type %in% input$research_article_type, ]
    }
    if (!is.null(input$location_country) && length(input$location_country) > 0) {
      data_filtered <- data_filtered[data_filtered$location_country %in% input$location_country, ]
    }
    if (!is.null(input$location_state_province) && length(input$location_state_province) > 0) {
      data_filtered <- data_filtered[data_filtered$location_state_province %in% input$location_state_province, ]
    }
    if (!is.null(input$location_watershed_lab) && length(input$location_watershed_lab) > 0) {
      data_filtered <- data_filtered[data_filtered$location_watershed_lab %in% input$location_watershed_lab, ]
    }
    if (!is.null(input$location_river_creek) && length(input$location_river_creek) > 0) {
      data_filtered <- data_filtered[data_filtered$location_river_creek %in% input$location_river_creek, ]
    }
    if (!is.null(input$broad_stressor_name) && length(input$broad_stressor_name) > 0) {
      data_filtered <- data_filtered[data_filtered$broad_stressor_name %in% input$broad_stressor_name, ]
    }
    if (!is.null(input$stressor) && length(input$stressor) > 0) {
      data_filtered <- data_filtered[data_filtered$stressor_name %in% input$stressor, ]
    }

    # Search
    if (!is.null(input$search) && input$search != "") {
      search_term <- tolower(input$search)
      search_cols <- c(
        "title", "species_common_name", "genus_latin", "species_latin",
        "stressor_name", "specific_stressor_metric", "life_stages",
        "activity", "location_country", "location_state_province",
        "location_watershed_lab", "location_river_creek", "broad_stressor_name"
      )

      if (nrow(data_filtered) > 0 && length(search_cols) > 0) {
        matched_rows <- Reduce(`|`, lapply(search_cols, function(col) {
          grepl(search_term, tolower(data_filtered[[col]]), ignore.case = TRUE)
        }))
        data_filtered <- data_filtered[matched_rows, ]
      }
    }

    data_filtered
  })

  return(filtered_data)
}
# nolint end
