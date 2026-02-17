# nolint start

# Load required modules
source("modules/csv_validation.R")
source("modules/error_handling.R")
source("modules/csv_template.R")
source("modules/file_validation.R")

submit_relationship_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidPage(
      tags$head(
        includeCSS("www/custom.css"),
      ),
      shinyjs::useShinyjs(),
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
            textInput(ns("name"), "Name *", placeholder = "Your full name"),
            textInput(ns("email"), "Email *", placeholder = "you@example.com"),
            textInput(ns("citation"), "Citation *", placeholder = "APA or other citation")
          ),
          column(
            6,
            offset = 3,
            textInput(ns("title"), "Title *", placeholder = "Title of relationship"),
            textAreaInput(ns("notes"), "Notes *", rows = 3, placeholder = "Any additional notes")
          )
        ),
        # optional csv upload for supporting data + optional PDF
        fluidRow(
          column(6, offset = 3, wellPanel(
            strong("Optional File Uploads"),
            div(id = ns("pdf_wrapper"), fileInput(ns("supporting_pdf"), "Optional: PDF from which the relationship comes", accept = c(".pdf", "application/pdf"))),
            tags$br(),
            div(id = ns("csv_wrapper"), fileInput(ns("sr_csv_file"), "Optional: CSV data for relationship curve(s)", accept = ".csv")),
            tags$br(),
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

    # Reactive values to store the uploaded CSV data and its validation result
    uploaded_csv_data <- reactiveVal(NULL)
    uploaded_csv_validation <- reactiveVal(NULL)

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
        uploaded_csv_validation(validation_result)

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
        uploaded_csv_validation(NULL)
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

    # Handle form submission (required fields + optional files)
    observeEvent(input$submit_relationship, {
      # Basic required field checks
      req(input$name, input$email, input$citation, input$title, input$notes)

      errs <- character()
      if (is.null(input$name) || trimws(input$name) == "") errs <- c(errs, "Name is required")
      if (is.null(input$email) || trimws(input$email) == "") errs <- c(errs, "Email is required")
      if (is.null(input$citation) || trimws(input$citation) == "") errs <- c(errs, "Citation is required")
      if (is.null(input$title) || trimws(input$title) == "") errs <- c(errs, "Title is required")
      if (is.null(input$notes) || trimws(input$notes) == "") errs <- c(errs, "Notes are required")

      # Basic email format check
      if (!is.null(input$email) && nzchar(trimws(input$email))) {
        if (!grepl("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$", trimws(input$email))) {
          errs <- c(errs, "Email format appears invalid")
        }
      }

      if (length(errs) > 0) {
        show_error_modal(session, "Missing required fields", paste(errs, collapse = "<br>"))
        return()
      }

      # Require that CSV (if provided) was validated on upload — reuse cached result
      if (!is.null(input$sr_csv_file)) {
        csv_cached <- uploaded_csv_validation()
        if (is.null(csv_cached)) {
          show_error_modal(session, "CSV Not Validated", "Please upload and validate your CSV file before submitting (use the file chooser to re-upload).")
          return()
        }
        if (!isTRUE(csv_cached$valid)) {
          emsg <- get_csv_error_message(csv_cached)
          show_error_modal(session, "CSV Validation Failed", emsg$message)
          return()
        }
      }

      # Validate PDF if provided
      if (!is.null(input$supporting_pdf)) {
        pdf_check <- validate_pdf_upload(input$supporting_pdf)
        if (!isTRUE(pdf_check$valid)) {
          show_error_modal(session, "PDF Validation Failed", pdf_check$message)
          return()
        }
      }

      # If files passed validation, copy them to a secure temp dir with sanitized names
      saved_files <- list()
      safe_name <- function(n) gsub("[^A-Za-z0-9_.-]", "_", n)

      if (!is.null(input$sr_csv_file)) {
        src <- input$sr_csv_file$datapath
        dest <- file.path(tempdir(), paste0(format(Sys.time(), "%Y%m%d%H%M%S"), "_", safe_name(input$sr_csv_file$name)))
        tryCatch(
          {
            file.copy(src, dest)
            saved_files$csv <- dest
          },
          error = function(e) {
            show_error_modal(session, "File Save Error", "Failed to save uploaded CSV file temporarily.")
            return()
          }
        )
      }

      if (!is.null(input$supporting_pdf)) {
        src <- input$supporting_pdf$datapath
        dest <- file.path(tempdir(), paste0(format(Sys.time(), "%Y%m%d%H%M%S"), "_", safe_name(input$supporting_pdf$name)))
        tryCatch(
          {
            file.copy(src, dest)
            saved_files$pdf <- dest
          },
          error = function(e) {
            show_error_modal(session, "File Save Error", "Failed to save uploaded PDF file temporarily.")
            return()
          }
        )
      }

      # At this point all validations passed.
      # Show success and store metadata or temp paths if needed.
      show_success_modal(session, "Submission Accepted", sprintf("Thank you %s — your submission titled '%s' was received.", input$name, input$title))

      # Clear cached upload state and reset the form UI
      try(
        {
          uploaded_csv_data(NULL)
          uploaded_csv_validation(NULL)
          shinyjs::reset(ns("submit_relationship_form"))
        },
        silent = TRUE
      )

      # Log minimal info (avoid logging raw file contents)
      message(sprintf(
        "[RELATIONSHIP SUBMIT] Name=%s, Email=%s, Title=%s, CSV=%s, PDF=%s",
        input$name, input$email, input$title,
        ifelse(!is.null(saved_files$csv), saved_files$csv, ""),
        ifelse(!is.null(saved_files$pdf), saved_files$pdf, "")
      ))
    })
  })
}

# nolint end
