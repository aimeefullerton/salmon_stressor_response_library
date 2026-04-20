# nolint start

# Load required modules
source("modules/csv_validation.R")
source("modules/error_handling.R")

# Compact Upload UI matched to the new February 2026 Database Schema
upload_ui <- function(id) {
  ns <- NS(id)

  tagList(
    shinyjs::useShinyjs(),
    tags$head(
      includeCSS("www/custom.css")
    ),
    div(
      id = ns("upload_form"),
      fluidRow(
        column(12, h3("Submit New SRF Relationship", style = "text-align: center; color: #6082B6;"))
      ),

# Core Metadata
      fluidRow(
        column(6, offset = 3, textInput(ns("title"), "Article Title *", placeholder = "Add a short descriptive title", width = "800px"))
      ),
      fluidRow(
        column(3, offset = 3, textInput(ns("article_type"), "Article Type", placeholder = "e.g., Peer-reviewed, Report")),
        column(3, textInput(ns("response"), "Response", placeholder = "e.g., Mean System Capacity"))
      ),

# CSV Upload
      fluidRow(
        column(6, offset = 3, wellPanel(
          style = "background-color: #f9f9f9; border-color: #ccc;",
          strong("SR Curve Data CSV"),
          uiOutput(ns("sr_csv_file_ui")),
          helpText(
            "Upload a CSV data file for the SR relationship.",
            br(),
            "Required columns: curve.id, stressor.label, stressor.x, units.x, response.label, response.y, units.y.",
            br(),
            "Optional columns: stressor.value, lower.limit, upper.limit, sd.",
            br(),
            "Each curve must have at least 4 rows with valid (non-NA) stressor.x and response.y values."
          ),
          downloadButton(ns("download_csv_template"), "Download CSV Template", class = "btn btn-info mb-2"),
          uiOutput(ns("csv_validation_status"))
        ))
      ),
      
# Stressor Information
      fluidRow(
        column(3, offset = 3, textInput(ns("stressor_name"), "Stressor Name", placeholder = "e.g., Temperature")),
        column(3, textInput(ns("broad_stressor_name"), "Broad Stressor Name", placeholder = "e.g., Water Quality"))
      ),
      fluidRow(
        column(6, offset = 3, textInput(ns("specific_stressor_metric"), "Specific Stressor Metric", placeholder = "e.g., 7DADM, Celsius, % Capacity", width = "100%"))
      ),

# Species Info
      fluidRow(
        column(3, offset = 3, textInput(ns("species_common_name"), "Species Common Name", placeholder = "e.g., Chinook Salmon")),
        column(3, textInput(ns("latin_name"), "Latin Name", placeholder = "e.g., Oncorhynchus tshawytscha"))
      ),
      fluidRow(
        column(3, offset = 3, textInput(ns("life_stages"), "Life Stages", placeholder = "e.g., Adult, Fry")),
        column(3, textInput(ns("activity"), "Activity", placeholder = "e.g., Migration, Spawning"))
      ),
      fluidRow(
        column(6, offset = 3, textInput(ns("season"), "Season", placeholder = "e.g., Summer, Fall", width = "100%"))
      ),

# Location Info
      fluidRow(
        column(3, offset = 3, textInput(ns("location_country"), "Country", placeholder = "e.g., USA, Canada")),
        column(3, textInput(ns("location_state_province"), "State / Province", placeholder = "e.g., Washington, BC"))
      ),
      fluidRow(
        column(3, offset = 3, textInput(ns("location_watershed_lab"), "Watershed / Lab", placeholder = "e.g., Columbia River Basin")),
        column(3, textInput(ns("location_river_creek"), "River / Creek", placeholder = "e.g., Snake River"))
      ),

# Descriptions & Formulas
      fluidRow(
        column(6, offset = 3, textAreaInput(ns("overview"), "Overview Description", placeholder = "Describe importance, pathways of effect, etc.", height = "120px", width = "100%"))
      ),
      fluidRow(
        column(6, offset = 3, textAreaInput(ns("function_derivation"), "Function Derivation", placeholder = "Describe the source of the function (e.g., expert opinion, mechanistic).", height = "120px", width = "100%"))
      ),
      fluidRow(
        column(6, offset = 3, textAreaInput(ns("transferability_of_function"), "Transferability of Function", placeholder = "Notes regarding transferability to other species and systems.", height = "80px", width = "100%"))
      ),
      fluidRow(
        column(6, offset = 3, textInput(ns("srf_formula"), "SRF Formula", placeholder = "Enter the mathematical formula if applicable", width = "100%"))
      ),
      fluidRow(
        column(6, offset = 3, textAreaInput(ns("source_of_stressor_data"), "Source of Stressor Data", placeholder = "Describe the source of stressor data needed to apply the function", height = "80px", width = "100%"))
      ),

# Confidence Rankings
      fluidRow(
        column(6, offset = 3, h4("Confidence Rankings"))
      ),
      fluidRow(
        column(3, offset = 3, textInput(ns("conf_source"), "Source", placeholder = "e.g., High, Medium, Low")),
        column(3, textInput(ns("conf_shape"), "Shape", placeholder = "e.g., High, Medium, Low"))
      ),
      fluidRow(
        column(3, offset = 3, textInput(ns("conf_variance"), "Variance", placeholder = "e.g., High, Medium, Low")),
        column(3, textInput(ns("conf_applicability"), "Applicability", placeholder = "e.g., High, Medium, Low"))
      ),
      fluidRow(
        column(6, offset = 3, textInput(ns("conf_interactions"), "Interactions", placeholder = "e.g., High, Medium, Low", width = "100%"))
      ),
# Citations (Dynamic)
      fluidRow(
        column(6, offset = 3, h4("Citations"))
      ),
      fluidRow(
        column(6, offset = 3, uiOutput(ns("dynamic_citations_ui")))
      ),
      fluidRow(
        column(6, offset = 3, actionButton(ns("add_citation"), "Add Another Citation", icon = icon("plus"), class = "btn-sm", style = "margin-bottom: 20px;"))
      ),
      
# Revision Log and Submit
      fluidRow(
        column(6, offset = 3, textAreaInput(ns("revision_log"), "Revision Log Message", placeholder = "Briefly describe the reason for this upload/change", height = "60px", width = "100%"))
      )
    ),
    fluidRow(
      column(3, offset = 3, actionButton(ns("save"), "Submit SR Profile", class = "btn-primary")),
      column(3, actionButton(ns("preview"), "Preview", class = "btn-secondary"))
    )
  )
}

upload_server <- function(id, db_conn = pool, current_user = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    output$sr_csv_file_ui <- renderUI({
      fileInput(ns("sr_csv_file"), NULL, accept = ".csv", buttonLabel = "Choose File", placeholder = "No file chosen")
    })

# Track the number of citation blocks
    citation_count <- reactiveVal(1)

    observeEvent(input$add_citation, {
      citation_count(citation_count() + 1)
    })

    # Render the dynamic citation fields
    output$dynamic_citations_ui <- renderUI({
      n <- citation_count()
      lapply(1:n, function(i) {
        div(
          style = "border: 1px solid #e3e3e3; padding: 15px; margin-bottom: 10px; border-radius: 5px; background-color: #fafafa;",
          textAreaInput(ns(paste0("citation_text_", i)), paste("Citation", i, "(Text)"), placeholder = "e.g., Smith et al. (2020)...", height = "70px", width = "100%"),
          fluidRow(
            column(6, textInput(ns(paste0("citation_title_", i)), "Link Title", placeholder = "e.g., Read the full paper")),
            column(6, textInput(ns(paste0("citation_url_", i)), "URL", placeholder = "https://doi.org/..."))
          )
        )
      })
    })
    
# Real-time CSV validation display
    observeEvent(input$sr_csv_file, {
      req(input$sr_csv_file)
      csv_validation_result <- validate_csv_upload(input$sr_csv_file)

      output$csv_validation_status <- renderUI({
        if (csv_validation_result$valid) {
          df <- csv_validation_result$data
          HTML(create_alert_html(
            type = "success",
            message = "CSV is valid and ready to submit",
            details = list(sprintf("Total rows: %d", nrow(df)))
          ))
        } else {
          error_msg <- get_csv_error_message(csv_validation_result)
          HTML(create_alert_html(type = "error", message = error_msg$message, details = error_msg$issues))
        }
      })
    })

    # Insert data into database when "Submit SR Profile" button is clicked
    observeEvent(input$save, {
      req(input$title)

      # Ensure CSV is uploaded and valid
      if (is.null(input$sr_csv_file)) {
        show_error_modal(session, "❌ Missing CSV File", "Please upload a CSV file containing your SR curve data.")
        return()
      }
      
      csv_validation_result <- validate_csv_upload(input$sr_csv_file)
      if (!csv_validation_result$valid) {
        show_error_modal(session, "❌ CSV Validation Failed", "Please fix the CSV file before submitting.")
        return()
      }
      df_csv <- csv_validation_result$data

# Compile Dynamic Citations into JSON Array
      citations_list <- list()
      for (i in 1:citation_count()) {
        c_text <- input[[paste0("citation_text_", i)]]
        c_title <- input[[paste0("citation_title_", i)]]
        c_url <- input[[paste0("citation_url_", i)]]

        # Only add to the database if the citation text isn't blank
        if (!is.null(c_text) && trimws(c_text) != "") {
          citations_list[[length(citations_list) + 1]] <- list(
            text = trimws(c_text),
            title = if (!is.null(c_title) && trimws(c_title) != "") trimws(c_title) else NA_character_,
            url = if (!is.null(c_url) && trimws(c_url) != "") trimws(c_url) else NA_character_
          )
        }
      }

      # Convert to JSON (If empty, save an empty JSON array '[]')
      citation_json <- if (length(citations_list) > 0) {
        jsonlite::toJSON(citations_list, auto_unbox = TRUE, null = "null")
      } else {
        "[]"
      }
      
# Handle Confidence Rankings (Convert empty strings back to NA for the DB)
      get_conf <- function(val) if (is.null(val) || trimws(val) == "") NA_character_ else trimws(val)

      # Determine user_id (You may need to look this up via a query depending on your DB)
      # For now, we will assume user_id is nullable or can accept the string. If it's a numeric ID,
      # you would query the 'users' table here to get the integer.
      user_name_to_log <- if(is.null(current_user)) "System Admin" else current_user

# Handle Confidence Rankings (Convert empty strings back to NA)
      get_conf <- function(val) if (is.null(val) || trimws(val) == "") NA_character_ else trimws(val)

      # Handle comma-separated Postgres Arrays (e.g., "Adult, Fry" -> '{"Adult","Fry"}')
      to_pg_array <- function(val) {
        if (is.null(val) || trimws(val) == "") return(NA_character_)
        parts <- trimws(strsplit(val, ",")[[1]])
        parts <- parts[parts != ""]
        if (length(parts) == 0) return(NA_character_)
        paste0("{", paste(sprintf('"%s"', gsub('"', '\\"', parts, fixed = TRUE)), collapse = ","), "}")
      }

      # Handle paragraph-style Postgres Arrays (e.g., wraps a whole paragraph in a 1-item array)
      to_pg_array_single <- function(val) {
        if (is.null(val) || trimws(val) == "") return(NA_character_)
        paste0('{"', gsub('"', '\\"', trimws(val), fixed = TRUE), '"}')
      }

      user_name_to_log <- if(is.null(current_user)) "System Admin" else current_user

      tryCatch({
        # Compile Revision Log into JSONB Format
        revision_json <- jsonlite::toJSON(list(
          list(
            message = input$revision_log,
            user = user_name_to_log,
            date = as.character(Sys.Date())
          )
        ), auto_unbox = TRUE)

        # --- Transaction Step 1: Insert Metadata ---
        query <- "
          INSERT INTO stressor_responses (
            article_type, title, stressor_name, broad_stressor_name, specific_stressor_metric, 
            response, srf_formula, species_common_name, latin_name, life_stages, activity, season, 
            location_country, location_state_province, location_watershed_lab, location_river_creek, 
            overview, function_derivation, transferability_of_function, 
            conf_source, conf_shape, conf_variance, conf_applicability, conf_interactions, 
            source_of_stressor_data, citations, revision_log
          ) VALUES (
            $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, 
            $18, $19, $20, $21, $22, $23, $24, $25, $26::jsonb, $27::jsonb
          ) RETURNING article_id;"

        new_article <- dbGetQuery(db_conn, query, params = list(
          # Standard Text Columns
          input$article_type, 
          input$title, 
          input$stressor_name, 
          input$broad_stressor_name, 
          input$specific_stressor_metric, 
          input$response, 
          input$srf_formula, 

          # Array Columns (Separated by commas)
          to_pg_array(input$species_common_name), 
          to_pg_array(input$latin_name), 
          to_pg_array(input$life_stages), 
          to_pg_array(input$activity), 
          to_pg_array(input$season), 
          to_pg_array(input$location_country), 
          to_pg_array(input$location_state_province), 
          to_pg_array(input$location_watershed_lab), 
          to_pg_array(input$location_river_creek), 

          # Large Text / Description Columns
          input$overview, 
          to_pg_array_single(input$function_derivation), # Formatted safely as a 1-item array
          input$transferability_of_function, 
          
          # Confidence Rankings
          get_conf(input$conf_source), 
          get_conf(input$conf_shape), 
          get_conf(input$conf_variance), 
          get_conf(input$conf_applicability), 
          get_conf(input$conf_interactions), 
          
          # Final Fields
          input$source_of_stressor_data, 
          citation_json, 
          revision_json # Inserted as JSONB
        ))

        new_article_id <- new_article$article_id

        # --- Transaction Step 2: Insert CSV Data ---
        if (nrow(df_csv) > 0) {
          df_csv$article_id <- new_article_id
          names(df_csv) <- gsub("\\.", "_", names(df_csv)) 
          dbAppendTable(db_conn, "csv_data", df_csv)
        }

        # Success!
        show_success_modal(
          session,
          "✓ Submission Successful",
          sprintf("Your stressor-response data <strong>%s</strong> has been successfully saved to the database (ID: %s).", input$title, new_article_id)
        )

# Clear the form
        try({ shinyjs::reset(ns("upload_form")) }, silent = TRUE)
        citation_count(1) # Resets the dynamic citations back to 1 box
        
 # Manually clear text inputs just in case shinyjs reset misses dynamically bound ones
        all_text_inputs <- c(
          "title", "article_type", "response", "stressor_name", "broad_stressor_name", 
          "specific_stressor_metric", "species_common_name", "latin_name", "life_stages", 
          "activity", "season", "location_country", "location_state_province", 
          "location_watershed_lab", "location_river_creek", "srf_formula", 
          "conf_source", "conf_shape", "conf_variance", "conf_applicability", "conf_interactions",
          "citation_title", "citation_url"
        )
        for (tid in all_text_inputs) {
          try({ updateTextInput(session, inputId = tid, value = "") }, silent = TRUE)
        }
        
        textarea_inputs <- c("overview", "function_derivation", "transferability_of_function", "source_of_stressor_data", "citation_text", "revision_log")
        for (tid in textarea_inputs) {
          try({ updateTextAreaInput(session, inputId = tid, value = "") }, silent = TRUE)
        }
        
        output$csv_validation_status <- renderUI({ NULL })

      }, error = function(e) {
        error_msg <- conditionMessage(e)
        show_error_modal(
          session,
          "❌ Error Saving to Database",
          sprintf("Failed to save your data. Error: %s<br><br><strong>Please verify all required fields.</strong>", error_msg)
        )
      })
    })

    # Preview modal logic (simplified to just display the inputs)
    observeEvent(input$preview, {
      req(input$title)
      showModal(modalDialog(
        title = "Preview Your Submission",
        size = "l",
        tagList(
          h4("Title:"), p(input$title),
          h4("Stressor Name:"), p(input$stressor_name),
          h4("Species:"), p(input$species_common_name),
          h4("Location:"), p(paste(input$location_country, input$location_state_province, sep = " - "))
          # (Add more fields here if desired!)
        ),
        easyClose = TRUE,
        footer = modalButton("Close")
      ))
    })

    # CSV Template Download
    output$download_csv_template <- downloadHandler(
      filename = function() { paste0("SRF_template_", Sys.Date(), ".csv") },
      content = function(file) {
        template_data <- data.frame(
          curve.id = rep("c1", 5), stressor.label = rep("temperature", 5),
          stressor.x = c(10, 15, 20, 25, 30), units.x = rep("degC", 5),
          response.label = rep("survival", 5), response.y = c(0.95, 0.85, 0.70, 0.50, 0.30),
          units.y = rep("proportion", 5), stressor.value = rep("constant", 5),
          lower.limit = c(0.90, 0.80, 0.65, 0.45, 0.25), upper.limit = c(1.00, 0.90, 0.75, 0.55, 0.35),
          sd = c(0.05, 0.05, 0.05, 0.05, 0.05)
        )
        write.csv(template_data, file, row.names = FALSE)
      }
    )
  })
}

# nolint end
