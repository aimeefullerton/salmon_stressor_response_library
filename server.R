# nolint start

# Load required modules
source("global.R")
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
source("modules/admin_auth.R", local = TRUE)
source("modules/manage_categories.R", local = TRUE)
source("modules/eda.R", local = TRUE)
source("modules/back_button.R", local = TRUE)

server <- function(input, output, session) {
  # Enhanced filter state storage with tracking
  filter_state <- reactiveValues(
    stressor = NULL,
    stressor_metric = NULL,
    species = NULL,
    geography = NULL,
    life_stage = NULL,
    activity = NULL,
    genus_latin = NULL,
    species_latin = NULL,
    research_article_type = NULL,
    location_country = NULL,
    location_state_province = NULL,
    location_watershed_lab = NULL,
    location_river_creek = NULL,
    broad_stressor_name = NULL,
    initialized = FALSE,
    in_article_view = FALSE,
    restoring = FALSE # Add flag to prevent multiple restorations
  )

  # Track current view state
  current_view <- reactiveVal("dashboard")

  # Safe filter restoration function
  restore_filters_safely <- function() {
    tryCatch(
      {
        # Prevent multiple simultaneous restorations
        isolate({
          if (isTRUE(filter_state$restoring)) {
            cat("Filter restoration already in progress, skipping...\n")
            return()
          }
          filter_state$restoring <- TRUE
        })

        # Isolate the reactive values to avoid reactive context issues
        isolate({
          if (isTRUE(filter_state$initialized)) {
            # Capture values in isolation
            saved_stressor <- filter_state$stressor
            saved_stressor_metric <- filter_state$stressor_metric
            saved_species <- filter_state$species
            saved_geography <- filter_state$geography
            saved_life_stage <- filter_state$life_stage
            saved_activity <- filter_state$activity
            saved_genus_latin <- filter_state$genus_latin
            saved_species_latin <- filter_state$species_latin
            saved_research_article_type <- filter_state$research_article_type
            saved_location_country <- filter_state$location_country
            saved_location_state_province <- filter_state$location_state_province
            saved_location_watershed_lab <- filter_state$location_watershed_lab
            saved_location_river_creek <- filter_state$location_river_creek
            saved_broad_stressor_name <- filter_state$broad_stressor_name

            # Helper function to check if a filter has values
            has_value <- function(x) {
              tryCatch(
                {
                  !is.null(x) && length(x) > 0 && !all(is.na(x)) && !all(x == "")
                },
                error = function(e) FALSE
              )
            }

            # Check if any filters were actually set
            has_filters <- has_value(saved_stressor) || has_value(saved_stressor_metric) ||
              has_value(saved_species) || has_value(saved_geography) ||
              has_value(saved_life_stage) || has_value(saved_activity) ||
              has_value(saved_genus_latin) || has_value(saved_species_latin) ||
              has_value(saved_research_article_type) || has_value(saved_location_country) ||
              has_value(saved_location_state_province) || has_value(saved_location_watershed_lab) ||
              has_value(saved_location_river_creek) || has_value(saved_broad_stressor_name)

            # Use later to ensure UI elements are ready
            later::later(function() {
              tryCatch(
                {
                  updatePickerInput(session, "stressor", selected = saved_stressor)
                  updatePickerInput(session, "stressor_metric", selected = saved_stressor_metric)
                  updatePickerInput(session, "species", selected = saved_species)
                  updatePickerInput(session, "geography", selected = saved_geography)
                  updatePickerInput(session, "life_stage", selected = saved_life_stage)
                  updatePickerInput(session, "activity", selected = saved_activity)
                  updatePickerInput(session, "genus_latin", selected = saved_genus_latin)
                  updatePickerInput(session, "species_latin", selected = saved_species_latin)
                  updatePickerInput(session, "research_article_type", selected = saved_research_article_type)
                  updatePickerInput(session, "location_country", selected = saved_location_country)
                  updatePickerInput(session, "location_state_province", selected = saved_location_state_province)
                  updatePickerInput(session, "location_watershed_lab", selected = saved_location_watershed_lab)
                  updatePickerInput(session, "location_river_creek", selected = saved_location_river_creek)
                  updatePickerInput(session, "broad_stressor_name", selected = saved_broad_stressor_name)

                  # Show filters if any were set
                  if (isTRUE(has_filters)) {
                    # Force the filter panel to show by simulating button click
                    later::later(function() {
                      shinyjs::runjs("
                    try {
                      var toggleBtn = $('#toggle_filters');
                      if (toggleBtn.length > 0) {
                        var isShowingFilters = toggleBtn.text().includes('Hide');
                        if (!isShowingFilters) {
                          toggleBtn.click();
                        }
                      }
                    } catch(e) {
                      console.log('Error toggling filters:', e);
                    }
                  ")
                    }, delay = 0.1)
                  }

                  # Reset the restoring flag
                  filter_state$restoring <- FALSE
                  cat("Filters restored successfully (has_filters:", has_filters, ")\n")
                },
                error = function(e) {
                  filter_state$restoring <- FALSE
                  cat("Error in updatePickerInput:", e$message, "\n")
                }
              )
            }, delay = 0.3)
          } else {
            filter_state$restoring <- FALSE
            cat("No filter state to restore (not initialized)\n")
          }
        })
      },
      error = function(e) {
        # Ensure restoring flag is reset even if there's an error
        tryCatch(
          {
            filter_state$restoring <- FALSE
          },
          error = function(e2) {
            # Ignore errors when setting restoring flag
          }
        )
        cat("Error in restore_filters_safely:", e$message, "\n")
      }
    )
  }

  # Monitor URL changes to detect view transitions
  observe({
    query <- parseQueryString(session$clientData$url_search)

    if (!is.null(query$main_id)) {
      # We're in article view
      if (current_view() == "dashboard") {
        filter_state$in_article_view <- TRUE
        current_view("article")
      }
    } else {
      # We're in dashboard view
      if (current_view() == "article") {
        # Just returned from article view - restore filters
        current_view("dashboard")
        restore_filters_safely()
      }
    }
  })

  # Save filter state whenever a filter changes (only in dashboard view)
  observe({
    query <- parseQueryString(session$clientData$url_search)

    # Only save state when we're in dashboard view
    if (is.null(query$main_id)) {
      filter_state$stressor <- input$stressor
      filter_state$stressor_metric <- input$stressor_metric
      filter_state$species <- input$species
      filter_state$geography <- input$geography
      filter_state$life_stage <- input$life_stage
      filter_state$activity <- input$activity
      filter_state$genus_latin <- input$genus_latin
      filter_state$species_latin <- input$species_latin
      filter_state$research_article_type <- input$research_article_type
      filter_state$location_country <- input$location_country
      filter_state$location_state_province <- input$location_state_province
      filter_state$location_watershed_lab <- input$location_watershed_lab
      filter_state$location_river_creek <- input$location_river_creek
      filter_state$broad_stressor_name <- input$broad_stressor_name
      filter_state$initialized <- TRUE
    }
  })

  # Restore filter state when returning to dashboard tab
  observeEvent(input$main_navbar, {
    if (input$main_navbar == "dashboard") {
      restore_filters_safely()
    }
  })

  # Manual filter restoration trigger (for JavaScript calls)
  observeEvent(input$trigger_filter_restore, {
    restore_filters_safely()
  })

  # Handle back to dashboard button click
  observeEvent(input$back_to_dashboard, {
    # Update URL to remove main_id parameter
    query <- parseQueryString(session$clientData$url_search)
    query$main_id <- NULL

    # Rebuild query string
    if (length(query) > 0) {
      query_string <- paste(names(query), query, sep = "=", collapse = "&")
      new_url <- paste0("?", query_string)
    } else {
      new_url <- ""
    }

    # Update the URL
    updateQueryString(new_url, mode = "replace", session = session)

    # Restore filters after URL update
    later::later(function() {
      restore_filters_safely()
    }, delay = 0.3)
  })

  getCategoryChoices <- function(table_name) {
    tryCatch(
      {
        dbGetQuery(db, sprintf("SELECT name FROM %s ORDER BY name", table_name))$name
      },
      error = function(e) {
        character(0)
      }
    )
  }

  # Global logout tracker
  admin_logged_in <- reactiveVal(FALSE)

  # Pass in a function that toggles this
  admin_ok <- adminAuthServer("auth", correct_pw = "secret123", updateStatus = admin_logged_in)

  output$categories_auth_ui <- renderUI({
    if (!admin_logged_in()) {
      adminAuthUI("auth")
    } else {
      tagList(
        div(
          style = "display: flex; justify-content: flex-end; margin-bottom: 10px;",
          actionButton("logout_admin", "Logout", class = "btn btn-danger")
        ),
        manageCategoriesUI("manage_categories")
      )
    }
  })

  observeEvent(admin_logged_in(), {
    if (admin_logged_in()) {
      manageCategoriesServer("manage_categories", db)
    }
  })

  # Handle logout
  observeEvent(input$logout_admin, {
    admin_logged_in(FALSE)
  })

  # Connect to database
  db <- tryCatch(
    dbConnect(SQLite(), "data/stressor_responses.sqlite"),
    error = function(e) {
      stop("Error: Unable to connect to the database.")
    }
  )

  if (!"stressor_responses" %in% dbListTables(db)) {
    stop("Error: Table `stressor_responses` does not exist in the database.")
  }

  data <- dbReadTable(db, "stressor_responses")

  filtered_data <- filter_data_server(input, data, session)

  progressive_data <- reactive({
    req(data)
    df <- data

    if (!is.null(input$stressor) && length(input$stressor) > 0) {
      df <- df[df$stressor_name %in% input$stressor, ]
    }
    if (!is.null(input$stressor_metric) && length(input$stressor_metric) > 0) {
      df <- df[df$specific_stressor_metric %in% input$stressor_metric, ]
    }
    if (!is.null(input$species) && length(input$species) > 0) {
      df <- df[df$species_common_name %in% input$species, ]
    }
    if (!is.null(input$geography) && length(input$geography) > 0) {
      df <- df[df$geography %in% input$geography, ]
    }
    if (!is.null(input$life_stage) && length(input$life_stage) > 0) {
      df <- df[Reduce(`|`, lapply(input$life_stage, function(stage) {
        grepl(stage, df$life_stages, ignore.case = TRUE)
      })), ]
    }
    if (!is.null(input$activity) && length(input$activity) > 0) {
      df <- df[df$activity %in% input$activity, ]
    }
    if (!is.null(input$genus_latin) && length(input$genus_latin) > 0) {
      df <- df[df$genus_latin %in% input$genus_latin, ]
    }
    if (!is.null(input$species_latin) && length(input$species_latin) > 0) {
      df <- df[df$species_latin %in% input$species_latin, ]
    }

    df
  })

  pagination <- pagination_server(input, output, session, filtered_data)
  paginated_data <- pagination$paginated_data
  output$page_info <- renderText(pagination$page_info())
  output$page_info_top <- renderText(pagination$page_info())

  update_filters_server(input, output, session, data, db)
  toggle_filters_server(input, session)

  observeEvent(input$reset_filters_btn, {
    reset_filters_server(input, session)
  })

  upload_server("upload")

  edaServer("eda", db_path = "data/stressor_responses.sqlite")

  render_papers_server(output, paginated_data, input, session)

  # Download handler setup
  setup_download_csv(output, paginated_data, db, input)

  # Article display logic
  observe({
    query <- parseQueryString(session$clientData$url_search)

    # Only handle article rendering when main_id is present
    if (!is.null(query$main_id)) {
      main_id <- as.numeric(query$main_id)
      if (!is.na(main_id)) {
        # Fetch article data from the database
        tryCatch(
          {
            render_article_ui(output, session)
            render_article_server(input, output, session, main_id, db)
          },
          error = function(e) {
            # create error message when article fails to render
            output$article_content <- renderUI({
              tagList(
                # Add the back button even on error
                create_back_button(),
                # Error message
                div(
                  style = "margin-top: 20px; padding: 20px; border: 1px solid #dc3545; background-color: #f8d7da; border-radius: 8px;",
                  tags$h4("Error loading article", style = "color: #721c24; margin-bottom: 10px;"),
                  tags$p(paste("Unable to render article:", e$message),
                    style = "color: #721c24; font-weight: bold; margin: 0;"
                  )
                )
              )
            })
            print(e)
          }
        )
      } else {
        # Create back button and "not found" message for invalid main_id
        output$article_content <- renderUI({
          tagList(
            # Add the back button for invalid article ID
            create_back_button(),
            # Not found message
            div(
              style = "margin-top: 20px; padding: 20px; border: 1px solid #ffc107; background-color: #fff3cd; border-radius: 8px;",
              tags$h4("Article Not Found", style = "color: #856404; margin-bottom: 10px;"),
              tags$p("The requested article could not be found.",
                style = "color: #856404; font-weight: bold; margin: 0;"
              )
            )
          )
        })
      }
    }
  })

  # Section toggles
  observeEvent(input$toggle_metadata, {
    toggle("metadata_section")
  })
  observeEvent(input$toggle_description, {
    toggle("description_section")
  })
  observeEvent(input$toggle_citations, {
    toggle("citations_section")
  })
  observeEvent(input$toggle_images, {
    toggle("images_section")
  })
  observeEvent(input$toggle_csv, {
    toggle("csv_section")
  })
  observeEvent(input$toggle_plot, {
    toggle("plot_section")
  })
  observeEvent(input$generate_plot, {
    show("compare_plot")
  })
  observeEvent(filtered_data(), {
    updateNumericInput(session, "page", value = 1)
  })
  observeEvent(input$toggle_interactive_plot, {
    toggle("interactive_plot_section")
  })
  observeEvent(input$prev_page, {
    updateNumericInput(session, "page", value = max(1, input$page - 1))
  })
  observeEvent(input$next_page, {
    updateNumericInput(session, "page", value = input$page + 1)
  })

  # Close DB connection on session end
  session$onSessionEnded(function() {
    dbDisconnect(db)
  })
}

# nolint end
