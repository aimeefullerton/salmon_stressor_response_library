# nolint start

# Load required modules
source("global.R")
source("modules/about_us.R", local = TRUE) # Restored
source("modules/acknowledgement.R", local = TRUE) # Restored
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


server <- function(input, output, session) {
  observeEvent(input$main_navbar,
    {
      if (input$main_navbar == "dashboard") {
        updateFilterDropdowns()
      }
    },
    ignoreInit = TRUE
  )

  updateFilterDropdowns <- function() {
    updatePickerInput(session, "stressor", choices = getCategoryChoices("stressor_names"))
    updatePickerInput(session, "stressor_metric", choices = getCategoryChoices("stressor_metrics"))
    updatePickerInput(session, "species", choices = getCategoryChoices("species_common_names"))
    updatePickerInput(session, "geography", choices = getCategoryChoices("geographies"))
    updatePickerInput(session, "life_stage", choices = getCategoryChoices("life_stages"))
    updatePickerInput(session, "activity", choices = getCategoryChoices("activities"))
    updatePickerInput(session, "genus_latin", choices = getCategoryChoices("genus_latins"))
    updatePickerInput(session, "species_latin", choices = getCategoryChoices("species_latins"))
    updatePickerInput(session, "research_article_type", choices = getCategoryChoices("research_article_types"))
    updatePickerInput(session, "location_country", choices = getCategoryChoices("location_countries"))
    updatePickerInput(session, "location_state_province", choices = getCategoryChoices("location_state_provinces"))
    updatePickerInput(session, "location_watershed_lab", choices = getCategoryChoices("location_watershed_labs"))
    updatePickerInput(session, "location_river_creek", choices = getCategoryChoices("location_river_creeks"))
    updatePickerInput(session, "broad_stressor_name", choices = getCategoryChoices("broad_stressor_names"))
  }

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


  # Launch admin authentication
  # admin_ok <- adminAuthServer("auth", correct_pw = "secret123")

  # output$categories_auth_ui <- renderUI({
  #   if (!admin_ok()) {
  #     adminAuthUI("auth")
  #   } else {
  #     tagList(
  #       actionButton("logout_admin", "Logout", class = "btn btn-danger mb-3"),
  #       manageCategoriesUI("manage_categories")
  #     )
  #   }
  # })

  # observeEvent(admin_ok(), {
  #   if (admin_ok()) {
  #     manageCategoriesServer("manage_categories", db)
  #   }
  # })

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

  # pagination <- pagination_server(input, filtered_data)
  # paginated_data <- pagination$paginated_data
  # output$page_info <- renderText(pagination$page_info())
  pagination <- pagination_server(input, output, session, filtered_data)
  paginated_data <- pagination$paginated_data
  output$page_info <- renderText(pagination$page_info())
  output$page_info_top <- renderText(pagination$page_info())

  update_filters_server(input, output, session, data, db)
  toggle_filters_server(input, session)
  reset_filters_server(input, session)

  upload_server("upload")

  edaServer("eda", db_path = "data/stressor_responses.sqlite")

  render_papers_server(output, paginated_data, input, session)

  # Download handler setup
  setup_download_csv(output, paginated_data, db, input)

  # Article display logic
  # observe({
  #   query <- parseQueryString(session$clientData$url_search)
  #   if (!is.null(query$main_id)) {
  #     main_id <- as.numeric(query$main_id)
  #     if (!is.na(main_id)) {
  #       tryCatch(
  #         {
  #           render_article_ui(output, session)
  #           render_article_server(input, output, session, main_id, db)
  #         },
  #         error = function(e) {
  #           output$article_content <- renderUI({
  #             tags$p(paste("Error rendering article:", e$message), style = "color: red; font-weight: bold;")
  #           })
  #           print(e)
  #         }
  #       )
  #     } else {
  #       output$article_content <- renderUI(
  #         tags$p("Article not found.", style = "color: red; font-weight: bold;")
  #       )
  #     }
  #   }
  # })
  observe({
    ids <- paginated_data()$main_id
    lapply(ids, function(mid) {
      observeEvent(input[[paste0("view_article_", mid)]],
        {
          showModal(modalDialog(
            title = paste("Article", mid),
            render_article_ui(mid, paginated_data()),
            easyClose = TRUE,
            size = "l"
          ))
          # This sets up all outputs for the selected article
          render_article_server(input, output, session, mid, db)
        },
        ignoreInit = TRUE
      )

      observeEvent(input[[paste0("expand_all_", mid)]],
        {
          shinyjs::show("metadata_section")
          shinyjs::show("description_section")
          shinyjs::show("citations_section")
          shinyjs::show("images_section")
          shinyjs::show("csv_section")
          shinyjs::show("interactive_plot_section")
        },
        ignoreInit = TRUE
      )

      observeEvent(input[[paste0("collapse_all_", mid)]],
        {
          shinyjs::hide("metadata_section")
          shinyjs::hide("description_section")
          shinyjs::hide("citations_section")
          shinyjs::hide("images_section")
          shinyjs::hide("csv_section")
          shinyjs::hide("interactive_plot_section")
        },
        ignoreInit = TRUE
      )
    })
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
