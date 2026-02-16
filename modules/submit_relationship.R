# nolint start

# Load required modules
source("modules/csv_validation.R")
source("modules/error_handling.R")
source("modules/csv_template.R")

submit_relationship_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidPage(
      tags$head(
        includeCSS("www/custom.css"),
        tags$script(HTML("
          Shiny.addCustomMessageHandler('relationship_submission_status', function(data) {
            var statusDiv = document.getElementById('submission_status');
            if (data.success) {
              statusDiv.innerHTML = '<div class=\"alert alert-success\" role=\"alert\">' + data.message + '</div>'
            } else {
              statusDiv.innerHTML = '<div class=\"alert alert-danger\" role=\"alert\">' + data.message + '</div>'
            }
          }"))
      ),
      fluidRow(
        column(8,
          offset = 2,
          h2("Submit a Relationship"),
          p("Use the form below to suggest a new relationship between a stressor and a response. Please provide as much detail as possible to help us evaluate your submission.")
        )
      ),
      div(
        id = ns("submit_relationship_form"),
        fluidRow(
          column(
            6,
            offset = 3,
            textInput(ns("your_name"), "Your Name"),
            textInput(ns("your_email"), "Your Email"),
          ),
          column(
            6,
            offset = 3,
            textInput(ns("relationship"), "Relationship Title", placeholder = "Stressor A causes Response B"),
            textAreaInput(ns("relationship_description"), "Relationship Description", rows = 3)
          )
        ),
        # optional csv upload for supporting data
        fluidRow(
          column(6, offset = 3, wellPanel(
            strong("SR Curve Data CSV"),
            uiOutput(ns("sr_csv_file_ui")),
            helpText(
              "Upload a CSV data file for the SR relationship.",
              br(),
              "Required columns: curve.id, stressor.label, stressor.x, units.x, response.label, response.y, units.y.",
              br(),
              "Optional columns: stressor.value, lower.limit, upper.limit, sd.",
              br(),
              "Each curve must have at least 4 rows with valid (non-NA) stressor.x and response.y values.",
              br(),
              "2 MB limit. Allowed type: .csv"
            ),
            downloadButton(ns("download_csv_template"), "Download CSV Template", class = "btn btn-info mb-2"),
            uiOutput(ns("csv_validation_status"))
          ))
        ),
        fluidRow(
          column(6,
            offset = 3,
            actionButton(ns("submit_relationship"), "Submit Relationship", class = "btn btn-primary btn-block"),
            tags$br(), tags$br(),
            div(id = ns("submission_status"))
          )
        )
      )
    )
  )
}

submit_relationship_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive value to store the uploaded CSV data
    uploaded_csv_data <- reactiveVal(NULL)

    # UI for file upload
    output$sr_csv_file_ui <- renderUI({
      fileInput(ns("sr_csv_file"), NULL, accept = ".csv", buttonLabel = "Choose File", placeholder = "No file chosen")
    })

    # Handle CSV file upload and validation
    observeEvent(input$sr_csv_file, {
      req(input$sr_csv_file)
      file <- input$sr_csv_file

      # Validate the uploaded CSV using the full Shiny file input object
      validation_result <- tryCatch(
        validate_csv_upload(file),
        error = function(e) {
          output$csv_validation_status <- renderUI({
            tags$div(class = "alert alert-danger", paste("CSV validation error:", conditionMessage(e)))
          })
          list(valid = FALSE, message = conditionMessage(e))
        }
      )

      if (isTRUE(validation_result$valid)) {
        df <- validation_result$data
        col_map <- validation_result$col_map

        # Extract metadata for display
        stressor_label <- if (!is.na(col_map$stressor_label)) {
          unique(df[[col_map$stressor_label]])[1]
        } else {
          "N/A"
        }

        response_label <- if (!is.na(col_map$response_label)) {
          unique(df[[col_map$response_label]])[1]
        } else {
          "N/A"
        }

        units_x <- if (!is.na(col_map$units_x)) {
          unique(df[[col_map$units_x]])[1]
        } else {
          "N/A"
        }

        units_y <- if (!is.na(col_map$units_y)) {
          unique(df[[col_map$units_y]])[1]
        } else {
          "N/A"
        }

        # Count unique curves
        unique_curves <- length(unique(df[[col_map$curve_id]]))

        details <- list(
          sprintf("Total rows: %d", nrow(df)),
          sprintf("Number of curves: %d", unique_curves),
          sprintf("Stressor: %s (%s)", stressor_label, units_x),
          sprintf("Response: %s (%s)", response_label, units_y)
        )

        if (length(validation_result$security_warnings) > 0) {
          details <- c(
            details,
            "⚠️ Security Notice: Suspicious patterns detected and neutralized"
          )
        }

        uploaded_csv_data(df)

        output$csv_validation_status <- renderUI({
          HTML(create_alert_html(
            type = "success",
            message = "CSV is valid and ready to submit",
            details = details
          ))
        })

        # Show security warnings in modal if present
        if (length(validation_result$security_warnings) > 0) {
          show_warning_modal(
            session,
            "🛡️ Security Notice",
            "Your CSV file contained suspicious patterns that were automatically neutralized for safety.",
            details = validation_result$security_warnings
          )
        }
      } else {
        uploaded_csv_data(NULL)
        error_msg <- get_csv_error_message(validation_result)

        output$csv_validation_status <- renderUI({
          HTML(create_alert_html(
            type = "error",
            message = error_msg$message,
            details = error_msg$issues
          ))
        })
      }
    })

    # Handle CSV template download
    output$download_csv_template <- downloadHandler(
      filename = function() {
        paste0("SRF_template_", Sys.Date(), ".csv")
      },
      content = function(file) {
        write_csv_template(file)
      }
    )
  })
}

# nolint end
