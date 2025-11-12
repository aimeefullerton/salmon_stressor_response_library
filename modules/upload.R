# nolint start

# Compact Upload UI (Updated + Centered & Spacing Reduced)

upload_ui <- function(id) {
  ns <- NS(id)

  picker_opts <- list(
    "actions-box" = TRUE,
    "live-search" = TRUE
  )

  tagList(
    shinyjs::useShinyjs(),
    tags$head(
      includeCSS("www/custom.css")
    ),
    fluidRow(
      column(12, h3("Submit New Research Data", style = "text-align: center; color: #6082B6;"))
    ),

    # Core Metadata
    fluidRow(
      column(6, offset = 3, textInput(ns("title"), "Title *", placeholder = "Add a short descriptive title such as Coho Fry and Stream Temperature", width = "800px"))
    ),
    fluidRow(
      column(3, offset = 3, pickerInput(ns("stressor_name"), "Stressor Name", NULL,
        multiple = TRUE, options = picker_opts,
        choices = NULL, selected = NULL
      )),
      column(3, pickerInput(ns("specific_stressor_metric"), "Specific Stressor Metric", NULL,
        multiple = TRUE, options = picker_opts,
        choices = NULL, selected = NULL
      ))
    ),
    fluidRow(
      column(3, offset = 3, textInput(ns("stressor_units"), "Stressor Units", placeholder = "e.g., °C, mg/L")),
      column(3)
    ),

    # Species Info
    fluidRow(
      column(3, offset = 3, pickerInput(ns("species_common_name"), "Species Common Name", NULL,
        multiple = TRUE, options = picker_opts,
        choices = NULL, selected = NULL
      )),
      column(3, pickerInput(ns("genus_latin"), "Genus Latin", NULL,
        multiple = TRUE, options = picker_opts,
        choices = NULL, selected = NULL
      ))
    ),
    fluidRow(
      column(3, offset = 3, pickerInput(ns("species_latin"), "Species Latin", NULL,
        multiple = TRUE, options = picker_opts,
        choices = NULL, selected = NULL
      )),
      column(3, pickerInput(ns("geography"), "Geography", NULL,
        multiple = TRUE, options = picker_opts,
        choices = NULL, selected = NULL
      ))
    ),
    fluidRow(
      column(3, offset = 3, pickerInput(ns("life_stage"), "Life Stage", NULL, multiple = TRUE, options = picker_opts)),
      column(3, pickerInput(ns("activity"), "Activity", NULL, multiple = TRUE, options = picker_opts))
    ),

    # New Metadata Fields
    fluidRow(
      column(3, offset = 3, pickerInput(ns("research_article_type"), "Research Article Type", NULL, multiple = TRUE, options = picker_opts)),
      column(3, pickerInput(ns("location_country"), "Country", NULL, multiple = TRUE, options = picker_opts))
    ),
    fluidRow(
      column(3, offset = 3, pickerInput(ns("location_state_province"), "State / Province", NULL, multiple = TRUE, options = picker_opts)),
      column(3, pickerInput(ns("location_watershed_lab"), "Watershed / Lab", NULL, multiple = TRUE, options = picker_opts))
    ),
    fluidRow(
      column(3, offset = 3, pickerInput(ns("location_river_creek"), "River / Creek", NULL, multiple = TRUE, options = picker_opts)),
      column(3, pickerInput(ns("broad_stressor_name"), "Broad Stressor Name", NULL, multiple = TRUE, options = picker_opts))
    ),

    # Description Fields
    fluidRow(
      column(6, offset = 3, textAreaInput(ns("description_overview"), "Detailed SR Function Description",
        placeholder = "Describe importance and why it is being included. Include key pieces of information, such as the original source formula, function derivation, pathways of effect etc.", height = "200px", width = "800px"
      ))
    ),
    fluidRow(
      column(6, offset = 3, textAreaInput(ns("description_function_derivation"), "Function Derivation",
        placeholder = "Describe the source of the function (e.g., expert opinion, mechanistic or theory based, correlative model etc.)", height = "200px", width = "800px"
      ))
    ),
    fluidRow(
      column(6, offset = 3, textAreaInput(ns("description_transferability_of_function"), "Transferability of Function",
        placeholder = "Describe notes regarding the transferability of the function to other species and systems.", height = "200px", width = "800px"
      ))
    ),
    fluidRow(
      column(6, offset = 3, textAreaInput(ns("description_source_of_stressor_data1"), "Source of Stressor Data",
        placeholder = "Describe the source of stressor data needed to apply the function", height = "200px", width = "800px"
      ))
    ),

    # CSV Upload
    fluidRow(
      column(6, offset = 3, wellPanel(
        style = "background-color: #f9f9f9; border-color: #ccc;",
        strong("SR Curve Data CSV"),
        fileInput(ns("sr_csv_file"), NULL, accept = ".csv", buttonLabel = "Choose File", placeholder = "No file chosen"),
        helpText(
          "Upload a csv data file for the SR relationship. Columns should include stressor, response, sd, low_limit, up_limit.",
          "One file only.", "2 MB limit.", "Allowed types: csv."
        )
      ))
    ),

    # Vital Rate Tab
    fluidRow(
      column(3, offset = 3, textInput(ns("vital_rate"), "Vital Rate (Process)", placeholder = "Enter vital rate details")),
      column(3, textInput(ns("season"), "Season", placeholder = "Describe seasonal timing"))
    ),
    fluidRow(
      column(6, offset = 3, textInput(ns("activity_details"), "Activity Details", placeholder = "Describe activity (if applicable)"))
    ),

    # Stressor Details
    fluidRow(
      column(3, offset = 3, textInput(ns("stressor_magnitude"), "Stressor Magnitude Data", placeholder = "Source of stressor magnitude data (e.g., GIS layer, field collection etc.)")),
      column(3, textInput(ns("poe_chain"), "PoE Chain", placeholder = "Describe PoE chain (e.g., agriculture, runoff, nutrients, productivity, hypoxia, fish)"))
    ),
    fluidRow(
      column(6, offset = 3, textInput(ns("key_covariates"), "Key Covariates & Dependencies",
        placeholder = "Describe key covariates and dependencies separately on each line (e.g., NTU > 5; Hardness < 200 mg/L; only applicable to lentic systems etc.). Use personal judgment (don't include all study parameters).", width = "100%"
      ))
    ),

    # Citations Tabs
    fluidRow(
      column(6, offset = 3, textAreaInput(ns("citation_text"), "Citations (as text)",
        placeholder = "Citations in APA format. Use reference from Google Scholar if possible.", height = "70px"
      ))
    ),
    fluidRow(
      column(3, offset = 3, textInput(ns("citation_url"), "Citation URL", placeholder = "http://example.com")),
      column(3, textInput(ns("citation_link_text"), "Citation Link Text", placeholder = "Display text for the link"))
    ),

    # Revision Log and Submit
    fluidRow(
      column(6, offset = 3, textAreaInput(ns("revision_log"), "Revision Log Message",
        placeholder = "Briefly describe any updates or changes made", height = "60px"
      ))
    ),
    fluidRow(
      column(3, offset = 3, actionButton(ns("save"), "Save SR Profile", class = "btn-primary")),
      column(3, actionButton(ns("preview"), "Preview", class = "btn-secondary"))
    )
  )
}

upload_server <- function(id, db_conn = pool) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Map UI input IDs to lookup tables
    lookup_tables <- c(
      "stressor_name" = "stressor_names",
      "specific_stressor_metric" = "stressor_metrics",
      "species_common_name" = "species_common_names",
      "genus_latin" = "genus_latins",
      "species_latin" = "species_latins",
      "geography" = "geographies",
      "life_stage" = "life_stages",
      "activity" = "activities",
      "research_article_type" = "research_article_types",
      "location_country" = "location_countries",
      "location_state_province" = "location_states_provinces",
      "location_watershed_lab" = "location_watersheds_labs",
      "location_river_creek" = "location_rivers_creeks",
      "broad_stressor_name" = "broad_stressor_names"
    )

    # Populate dropdowns on page load
    session$onFlushed(function() {
      for (input_id in names(lookup_tables)) {
        table <- lookup_tables[[input_id]]
        query <- sprintf("SELECT name FROM %s WHERE name IS NOT NULL AND TRIM(name) != '' ORDER BY name", table)
        values <- dbGetQuery(db_conn, query)$name
        updatePickerInput(session, inputId = input_id, choices = values, selected = NULL)
      }
    }, once = TRUE)

    # Save data when button is clicked
    observeEvent(input$save, {
      req(input$title)


      # use pool instead of creating a new connection
      # Check if the title already exists
      existing_title <- dbGetQuery(db_conn, "SELECT 1 FROM stressor_responses WHERE title = $1 LIMIT 1", params = list(input$title))

      if (nrow(existing_title) > 0) {
        showModal(modalDialog(
          title = "⚠️ Duplicate Title",
          "A stressor response with this title already exists. Please use a different title.",
          easyClose = TRUE
        ))
        return()
      }

      # Step 1: Insert new metadata values into lookup tables
      for (input_id in names(lookup_tables)) {
        table <- lookup_tables[[input_id]]
        values <- input[[input_id]]
        if (!is.null(values)) {
          for (val in values) {
            existing <- dbGetQuery(db_conn, sprintf("SELECT 1 FROM %s WHERE LOWER(name) = LOWER($1) LIMIT 1", table), params = list(val))
            if (nrow(existing) == 0) {
              dbExecute(db_conn, sprintf("INSERT INTO %s (name) VALUES ($1)", table), params = list(val))
            }
          }
        }
      }

      # Convert uploaded CSV to JSON string
      csv_json <- NULL
      if (!is.null(input$sr_csv_file)) {
        try(
          {
            df_csv <- read.csv(input$sr_csv_file$datapath, stringsAsFactors = FALSE)
            csv_json <- jsonlite::toJSON(df_csv, pretty = TRUE, auto_unbox = TRUE)
          },
          silent = TRUE
        )
      }

      # Step 2: Insert into main table - FIXED COLUMN NAMES
      #* replaced SQLite placeholders with Postgres placeholders
      dbExecute(db_conn, "
        INSERT INTO stressor_responses (
          title, stressor_name, specific_stressor_metric, stressor_units,
          species_common_name, genus_latin, species_latin, geography,
          life_stages, activity, research_article_type, location_country,
          location_state_province, location_watershed_lab, location_river_creek,
          broad_stressor_name, description_overview, description_function_derivation,
          description_transferability_of_function, description_source_of_stressor_data1,
          vital_rate, season, activity_details, stressor_magnitude, poe_chain,
          covariates_dependencies, citations_citation_text, citations_citation_links,
          citation_link, revision_log, csv_data_json
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30, $31)
      ",
        params = list(
          input$title,
          paste(input$stressor_name, collapse = ", "),
          paste(input$specific_stressor_metric, collapse = ", "),
          input$stressor_units,
          paste(input$species_common_name, collapse = ", "),
          paste(input$genus_latin, collapse = ", "),
          paste(input$species_latin, collapse = ", "),
          paste(input$geography, collapse = ", "),
          paste(input$life_stage, collapse = ", "),
          paste(input$activity, collapse = ", "),
          paste(input$research_article_type, collapse = ", "),
          paste(input$location_country, collapse = ", "),
          paste(input$location_state_province, collapse = ", "),
          paste(input$location_watershed_lab, collapse = ", "),
          paste(input$location_river_creek, collapse = ", "),
          paste(input$broad_stressor_name, collapse = ", "),
          input$description_overview,
          input$description_function_derivation,
          input$description_transferability_of_function,
          input$description_source_of_stressor_data1,
          input$vital_rate,
          input$season,
          input$activity_details,
          input$stressor_magnitude,
          input$poe_chain,
          input$key_covariates,
          input$citation_text,
          input$citation_link_text,
          paste0(input$citation_link_text, " (", input$citation_url, ")"),
          input$revision_log,
          csv_json
        )
      )

      # Step 3: Success modal
      showModal(modalDialog(
        title = "Success!",
        "Your stressor response profile has been saved.",
        easyClose = TRUE
      ))

      # Get the ID of the newly inserted row
      main_id <- dbGetQuery(db_conn, "SELECT currval(pg_get_serial_sequence('stressor_responses', 'main_id')) AS id")$id
    })

    observeEvent(input$preview, {
      req(input$title)

      # Read uploaded CSV and show head
      csv_preview <- NULL
      if (!is.null(input$sr_csv_file)) {
        try(
          {
            df_csv <- read.csv(input$sr_csv_file$datapath, stringsAsFactors = FALSE)
            csv_preview <- paste(capture.output(head(df_csv, 5)), collapse = "\n")
          },
          silent = TRUE
        )
      }

      # Show preview modal with all fields
      showModal(modalDialog(
        title = "Preview Your Submission",
        size = "l",
        tagList(
          h4("Title:"), verbatimTextOutput(ns("preview_title")),
          h4("Stressor Name:"), verbatimTextOutput(ns("preview_stressor")),
          h4("Specific Stressor Metric:"), verbatimTextOutput(ns("preview_metric")),
          h4("Stressor Units:"), verbatimTextOutput(ns("preview_units")),
          h4("Species (Common):"), verbatimTextOutput(ns("preview_species")),
          h4("Genus (Latin):"), verbatimTextOutput(ns("preview_genus")),
          h4("Species (Latin):"), verbatimTextOutput(ns("preview_species_latin")),
          h4("Geography:"), verbatimTextOutput(ns("preview_geography")),
          h4("Life Stages:"), verbatimTextOutput(ns("preview_lifestage")),
          h4("Activity:"), verbatimTextOutput(ns("preview_activity")),
          h4("Article Type:"), verbatimTextOutput(ns("preview_article")),
          h4("Location - Country:"), verbatimTextOutput(ns("preview_country")),
          h4("Location - State/Province:"), verbatimTextOutput(ns("preview_state")),
          h4("Watershed / Lab:"), verbatimTextOutput(ns("preview_watershed")),
          h4("River / Creek:"), verbatimTextOutput(ns("preview_river")),
          h4("Broad Stressor Name:"), verbatimTextOutput(ns("preview_broad_stressor")),
          h4("Description (Overview):"), verbatimTextOutput(ns("preview_overview")),
          h4("Description (Derivation):"), verbatimTextOutput(ns("preview_derivation")),
          h4("Description (Transferability):"), verbatimTextOutput(ns("preview_transferability")),
          h4("Description (Data Source):"), verbatimTextOutput(ns("preview_datasource")),
          h4("Vital Rate:"), verbatimTextOutput(ns("preview_vital")),
          h4("Season:"), verbatimTextOutput(ns("preview_season")),
          h4("Activity Details:"), verbatimTextOutput(ns("preview_activity_details")),
          h4("Stressor Magnitude:"), verbatimTextOutput(ns("preview_magnitude")),
          h4("POE Chain:"), verbatimTextOutput(ns("preview_poe")),
          h4("Covariates / Dependencies:"), verbatimTextOutput(ns("preview_covariates")),
          h4("Citation Text:"), verbatimTextOutput(ns("preview_citation_text")),
          h4("Citation Link:"), verbatimTextOutput(ns("preview_citation_link")),
          h4("Revision Log:"), verbatimTextOutput(ns("preview_revision_log")),
          h4("Uploaded CSV Preview (first 5 rows):"),
          tags$pre(csv_preview %||% "No CSV uploaded or preview failed.")
        ),
        easyClose = TRUE,
        footer = modalButton("Close")
      ))

      # Populate text outputs
      output$preview_title <- renderText({
        input$title
      })
      output$preview_stressor <- renderText({
        paste(input$stressor_name, collapse = ", ")
      })
      output$preview_metric <- renderText({
        paste(input$specific_stressor_metric, collapse = ", ")
      })
      output$preview_units <- renderText({
        input$stressor_units
      })
      output$preview_species <- renderText({
        paste(input$species_common_name, collapse = ", ")
      })
      output$preview_genus <- renderText({
        paste(input$genus_latin, collapse = ", ")
      })
      output$preview_species_latin <- renderText({
        paste(input$species_latin, collapse = ", ")
      })
      output$preview_geography <- renderText({
        paste(input$geography, collapse = ", ")
      })
      output$preview_lifestage <- renderText({
        paste(input$life_stage, collapse = ", ")
      })
      output$preview_activity <- renderText({
        paste(input$activity, collapse = ", ")
      })
      output$preview_article <- renderText({
        paste(input$research_article_type, collapse = ", ")
      })
      output$preview_country <- renderText({
        paste(input$location_country, collapse = ", ")
      })
      output$preview_state <- renderText({
        paste(input$location_state_province, collapse = ", ")
      })
      output$preview_watershed <- renderText({
        paste(input$location_watershed_lab, collapse = ", ")
      })
      output$preview_river <- renderText({
        paste(input$location_river_creek, collapse = ", ")
      })
      output$preview_broad_stressor <- renderText({
        paste(input$broad_stressor_name, collapse = ", ")
      })
      output$preview_overview <- renderText({
        input$description_overview
      })
      output$preview_derivation <- renderText({
        input$description_function_derivation
      })
      output$preview_transferability <- renderText({
        input$description_transferability_of_function
      })
      output$preview_datasource <- renderText({
        input$description_source_of_stressor_data1
      })
      output$preview_vital <- renderText({
        input$vital_rate
      })
      output$preview_season <- renderText({
        input$season
      })
      output$preview_activity_details <- renderText({
        input$activity_details
      })
      output$preview_magnitude <- renderText({
        input$stressor_magnitude
      })
      output$preview_poe <- renderText({
        input$poe_chain
      })
      output$preview_covariates <- renderText({
        input$key_covariates
      })
      output$preview_citation_text <- renderText({
        input$citation_text
      })
      output$preview_citation_link <- renderText({
        paste0(input$citation_link_text, " (", input$citation_url, ")")
      })
      output$preview_revision_log <- renderText({
        input$revision_log
      })
    })
  })
}

# nolint end
