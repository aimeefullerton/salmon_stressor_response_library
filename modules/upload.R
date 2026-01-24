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
        ),
        # Validation status display
        uiOutput(ns("csv_validation_status"))
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

    # Real-time CSV validation display
    output$csv_validation_status <- renderUI({
      if (is.null(input$sr_csv_file)) {
        return(NULL)
      }

      validation_result <- validate_csv_upload(input$sr_csv_file)

      if (validation_result$valid) {
        return(HTML(create_alert_html(
          type = "success",
          message = "CSV file validated successfully",
          details = list(sprintf("Rows: %d", nrow(validation_result$data)))
        )))
      } else {
        return(HTML(create_alert_html(
          type = "error",
          message = validation_result$message,
          details = validation_result$all_issues
        )))
      }
    })

    # Save data when button is clicked
    observeEvent(input$save, {
      req(input$title)

      # Step 1: Validate required fields
      if (trimws(input$title) == "") {
        show_error_modal(
          session,
          "❌ Missing Title",
          "Please enter a title for this stressor response profile before saving."
        )
        return()
      }

      # Step 2: Check for title duplication
      title_check <- check_title_duplicate(input$title, db_conn)
      if (title_check$duplicate) {
        show_error_modal(
          session,
          "❌ Duplicate Title",
          title_check$message
        )
        return()
      }

      # Step 3: Validate CSV if uploaded
      csv_validation_result <- NULL
      if (!is.null(input$sr_csv_file)) {
        csv_validation_result <- validate_csv_upload(input$sr_csv_file)
        if (!csv_validation_result$valid) {
          error_msg <- get_csv_error_message(csv_validation_result)
          show_error_modal(
            session,
            error_msg$title,
            error_msg$message,
            error_msg$issues
          )
          log_error("CSV Upload", error_msg$message, list(file = input$sr_csv_file$name))
          return()
        }
      }

      # Step 4: Check for data conflicts
      conflict_check <- check_data_conflict(
        input$stressor_name,
        input$species_common_name,
        input$geography,
        db_conn
      )
      if (conflict_check$conflict) {
        # Show warning but allow user to proceed
        show_warning_modal(
          session,
          "⚠️ Potential Data Conflict Detected",
          conflict_check$message
        )
        return()
      }

      # Step 5: Insert new metadata values into lookup tables
      tryCatch(
        {
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
        },
        error = function(e) {
          show_error_modal(
            session,
            "❌ Error Saving Metadata",
            sprintf("Failed to save metadata values: %s", conditionMessage(e))
          )
          log_error("Metadata Insert", conditionMessage(e))
          stop(e)
        }
      )

      # Step 6: Convert uploaded CSV to JSON string
      csv_json <- NULL
      if (!is.null(csv_validation_result) && csv_validation_result$valid) {
        tryCatch(
          {
            csv_json <- jsonlite::toJSON(csv_validation_result$data, pretty = TRUE, auto_unbox = TRUE)
          },
          error = function(e) {
            show_error_modal(
              session,
              "❌ Error Processing CSV Data",
              sprintf("Failed to process CSV data: %s", conditionMessage(e))
            )
            log_error("CSV JSON Conversion", conditionMessage(e))
            stop(e)
          }
        )
      }

      # Step 7: Insert into main table with error handling
      tryCatch(
        {
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

          # Success message
          show_success_modal(
            session,
            "✅ Success!",
            sprintf(
              "Your stressor response profile '<strong>%s</strong>' has been successfully saved to the database.",
              input$title
            )
          )

          # Log successful submission
          log_entry <- sprintf(
            "Title: %s | Stressor: %s | Species: %s | Geography: %s",
            input$title,
            paste(input$stressor_name, collapse = ", "),
            paste(input$species_common_name, collapse = ", "),
            paste(input$geography, collapse = ", ")
          )
          message(sprintf("[SUCCESS] Data submitted - %s", log_entry))
        },
        error = function(e) {
          error_msg <- conditionMessage(e)
          show_error_modal(
            session,
            "❌ Error Saving to Database",
            sprintf(
              "Failed to save your data to the database. Error: %s<br><br><strong>Please try again or contact support if the problem persists.</strong>",
              error_msg
            )
          )
          log_error("Database Insert", error_msg, list(title = input$title))
        }
      )
    })

    observeEvent(input$preview, {
      req(input$title)

      # Validate CSV if uploaded before showing preview
      csv_preview <- NULL
      csv_preview_status <- NULL

      if (!is.null(input$sr_csv_file)) {
        csv_validation_result <- validate_csv_upload(input$sr_csv_file)

        if (csv_validation_result$valid) {
          df_csv <- csv_validation_result$data
          csv_preview <- paste(capture.output(head(df_csv, 5)), collapse = "\n")
          csv_preview_status <- HTML(create_alert_html(
            type = "success",
            message = "CSV is valid",
            details = list(sprintf("Rows: %d", nrow(df_csv)))
          ))
        } else {
          error_msg <- get_csv_error_message(csv_validation_result)
          csv_preview_status <- HTML(create_alert_html(
            type = "error",
            message = error_msg$message,
            details = error_msg$issues
          ))
        }
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
          h4("Uploaded CSV Status:"),
          uiOutput(ns("preview_csv_status")),
          h4("CSV Preview (first 5 rows):"),
          tags$pre(csv_preview %||% "No CSV uploaded")
        ),
        easyClose = TRUE,
        footer = modalButton("Close")
      ))

      # Output CSV validation status for preview
      output$preview_csv_status <- renderUI({
        csv_preview_status %||% ""
      })

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
