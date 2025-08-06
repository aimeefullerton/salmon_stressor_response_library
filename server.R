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
  # Store filter state
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
    broad_stressor_name = NULL
  )

  # Save filter state whenever a filter changes
  observe({
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
  })

  # Restore filter state when returning to dashboard tab
  observeEvent(input$main_navbar, {
    if (input$main_navbar == "dashboard") {
      updatePickerInput(session, "stressor", selected = filter_state$stressor)
      updatePickerInput(session, "stressor_metric", selected = filter_state$stressor_metric)
      updatePickerInput(session, "species", selected = filter_state$species)
      updatePickerInput(session, "geography", selected = filter_state$geography)
      updatePickerInput(session, "life_stage", selected = filter_state$life_stage)
      updatePickerInput(session, "activity", selected = filter_state$activity)
      updatePickerInput(session, "genus_latin", selected = filter_state$genus_latin)
      updatePickerInput(session, "species_latin", selected = filter_state$species_latin)
      updatePickerInput(session, "research_article_type", selected = filter_state$research_article_type)
      updatePickerInput(session, "location_country", selected = filter_state$location_country)
      updatePickerInput(session, "location_state_province", selected = filter_state$location_state_province)
      updatePickerInput(session, "location_watershed_lab", selected = filter_state$location_watershed_lab)
      updatePickerInput(session, "location_river_creek", selected = filter_state$location_river_creek)
      updatePickerInput(session, "broad_stressor_name", selected = filter_state$broad_stressor_name)
    }
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
    if (!is.null(query$main_id)) {
      main_id <- as.numeric(query$main_id)
      if (!is.na(main_id)) {
        tryCatch(
          {
            render_article_ui(output, session)
            render_article_server(input, output, session, main_id, db)
          },
          error = function(e) {
            output$article_content <- renderUI({
              tags$p(paste("Error rendering article:", e$message), style = "color: red; font-weight: bold;")
            })
            print(e)
          }
        )
      } else {
        output$article_content <- renderUI(
          tags$p("Article not found.", style = "color: red; font-weight: bold;")
        )
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
