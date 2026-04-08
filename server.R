# nolint start

source("modules/csv_validation.R", local = TRUE)
source("modules/error_handling.R", local = TRUE)
source("modules/about_us.R", local = TRUE)
source("modules/acknowledgement.R", local = TRUE)
source("modules/filters.R", local = TRUE)
source("modules/pagination.R", local = TRUE)
source("modules/render_papers.R", local = TRUE)
source("modules/update_filters_server.R", local = TRUE)
source("modules/toggle_filters.R", local = TRUE)
source("modules/reset_filters.R", local = TRUE)
source("modules/render_article_ui.R", local = TRUE)
source("modules/render_article_server.R", local = TRUE)
source("modules/downloads.R", local = TRUE)
source("modules/upload.R", local = TRUE)
source("modules/eda.R", local = TRUE)
source("modules/submit_relationship.R", local = TRUE)

server <- function(input, output, session) {
  db <- pool

  # ── Initial data load ──────────────────────────────────────────────────────
  table_exists <- dbExistsTable(db, Id(schema = db_config$schema, table = "stressor_responses"))

  if (!table_exists) {
    warning("Table `stressor_responses` does not exist in the database.")
    data <- data.frame()
  } else {
    # UPDATED: Added LEFT JOIN to pull the user's name from the users table
    data <- dbGetQuery(db, "
      SELECT 
        sr.*, 
        u.name AS contributor_name 
      FROM stressor_responses sr
      LEFT JOIN users u ON sr.user_id = u.user_id 
      ORDER BY sr.article_id ASC
    ")

# Parse Postgres text[] columns into R character vectors AND collapse into strings
    pq_array_cols <- names(data)[sapply(data, inherits, "pq__text")]
    data[pq_array_cols] <- lapply(data[pq_array_cols], function(col) {
      sapply(col, function(x) {
        # Return true NA instead of "N/A"
        if (is.null(x) || is.na(x) || !nzchar(x)) return(NA_character_)
        x <- gsub("^\\{|\\}$", "", x)
        parts <- strsplit(x, ",(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)", perl = TRUE)[[1]]
        parts <- gsub('^"|"$', "", trimws(parts))
        valid_parts <- parts[parts != "NULL" & nzchar(parts)]
        # If the array was empty (e.g., {""}), return true NA
        if (length(valid_parts) == 0) return(NA_character_)
        # Collapse valid items
        return(paste(valid_parts, collapse = ", "))
      })
    })
}
  # ── Filter dropdowns ───────────────────────────────────────────────────────
  getCategoryChoices <- function(column_name) {
    # Use unnest() so each array element becomes its own distinct row
    tryCatch(
      dbGetQuery(
        db,
        sprintf(
          "SELECT DISTINCT unnest(%s) AS val FROM stressor_responses WHERE %s IS NOT NULL ORDER BY val",
          column_name, column_name
        )
      )[["val"]],
      error = function(e) character(0)
    )
  }

  updateFilterDropdowns <- function() {
    cols <- c(
      "stressor"                = "stressor_name",
      "stressor_metric"         = "specific_stressor_metric",
      "species"                 = "species_common_name",
      "life_stage"              = "life_stages",
      "activity"                = "activity",
      "latin_name"              = "latin_name",
      "article_type"            = "article_type",
      "location_country"        = "location_country",
      "location_state_province" = "location_state_province",
      "location_watershed_lab"  = "location_watershed_lab",
      "location_river_creek"    = "location_river_creek",
      "broad_stressor_name"     = "broad_stressor_name"
    )
    for (input_id in names(cols)) {
      updatePickerInput(session, input_id, choices = getCategoryChoices(cols[[input_id]]))
    }
  }

  observeEvent(input$main_navbar,
    {
      if (input$main_navbar == "dashboard") updateFilterDropdowns()
    },
    ignoreInit = TRUE
  )

  # ── Filtered & paginated data ──────────────────────────────────────────────
  filtered_data <- filter_data_server(input, data, session)

  pagination <- pagination_server(input, output, session, filtered_data)
  paginated_data <- pagination$paginated_data
  output$page_info <- renderText(pagination$page_info())
  output$page_info_top <- renderText(pagination$page_info())

  observeEvent(filtered_data(), {
    updateNumericInput(session, "page", value = 1)
  })

  observeEvent(input$prev_page, {
    updateNumericInput(session, "page", value = max(1, input$page - 1))
  })

  observeEvent(input$next_page, {
    updateNumericInput(session, "page", value = input$page + 1)
  })

  # ── Modules ────────────────────────────────────────────────────────────────
  update_filters_server(input, output, session, data, db)
  toggle_filters_server(input, session)
  reset_filters_server(input, session)
  submit_relationship_server("submit_relationship")
  edaServer("eda")
  render_papers_server(output, paginated_data, input, session)
  setup_download_csv(output, paginated_data, db, input, session)

  # ── Article modal ──────────────────────────────────────────────────────────
  # Track which articles have had render_article_server called to avoid
  # registering duplicate output renderers on repeated modal opens.
  initialized_articles <- character(0)

  observe({
    ids <- paginated_data()$article_id

    lapply(ids, function(mid) {
      mid_str <- as.character(mid)

      # ── Open modal ──────────────────────────────────────────────────────────
      observeEvent(input[[paste0("view_article_", mid)]],
        {
          paper_row <- paginated_data()[paginated_data()$article_id == mid, , drop = FALSE]

          showModal(modalDialog(
            title     = paste("Article", mid),
            render_article_ui(mid, paginated_data()),
            easyClose = TRUE,
            size      = "l"
          ))

          if (!mid_str %in% initialized_articles) {
            render_article_server(input, output, session, mid, paper_row, db)

            # ── Expand all ────────────────────────────────────────────────────
            observeEvent(input[[paste0("expand_all_", mid)]],
              {
                shinyjs::show(paste0("metadata_section_", mid))
                shinyjs::show(paste0("description_section_", mid))
                shinyjs::show(paste0("confidence_section_", mid))
                shinyjs::show(paste0("citations_section_", mid))
                shinyjs::show(paste0("csv_section_", mid))
                shinyjs::show(paste0("interactive_plot_section_", mid))
              },
              ignoreInit = TRUE
            )

            # ── Collapse all ──────────────────────────────────────────────────
            observeEvent(input[[paste0("collapse_all_", mid)]],
              {
                shinyjs::hide(paste0("metadata_section_", mid))
                shinyjs::hide(paste0("description_section_", mid))
                shinyjs::hide(paste0("confidence_section_", mid))
                shinyjs::hide(paste0("citations_section_", mid))
                shinyjs::hide(paste0("csv_section_", mid))
                shinyjs::hide(paste0("interactive_plot_section_", mid))
              },
              ignoreInit = TRUE
            )

            # ── Section toggles ───────────────────────────────────────────────
            for (section in c("metadata", "description", "confidence", "citations", "csv", "interactive_plot")) {
              local({
                s <- section
                m <- mid
                observeEvent(input[[paste0("toggle_", s, "_", m)]],
                  {
                    shinyjs::toggle(paste0(s, "_section_", m))
                  },
                  ignoreInit = TRUE
                )
              })
            }

            initialized_articles <<- c(initialized_articles, mid_str)
          }
        },
        ignoreInit = TRUE
      )
    })
  })
}

# nolint end
