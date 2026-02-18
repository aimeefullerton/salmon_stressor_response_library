# nolint start

# Load required modules
source("modules/csv_validation.R")
source("modules/csv_template.R")
source("modules/file_validation.R")
source("modules/error_handling.R")
source("modules/customFileInput.R")

# Use namespaced package calls; check optional email/future support
# (avoid attaching packages inside modules)
.email_support <- (
  requireNamespace("future", quietly = TRUE) &&
    requireNamespace("promises", quietly = TRUE) &&
    requireNamespace("emayili", quietly = TRUE)
)

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
          p("
            Use the form below to suggest a new relationship between a stressor and a response.
            Please provide as much detail as possible to help us evaluate your submission.
            We also encourage you to upload any relevant data (in CSV format) or source PDFs that can help us understand and verify the relationship you're submitting.
            After you submit, our team will review the information and get back to you if we have any questions.
            We appreciate your contribution to making this library more comprehensive and useful for everyone!
          ")
        )
      ),
      div(
        id = ns("submit_relationship_form"),
        fluidRow(
          column(
            6,
            offset = 3,
            textInput(ns("name"), "Name *", placeholder = "Your full name"),
            uiOutput(ns("error_name")),
            textInput(ns("email"), "Email *", placeholder = "you@example.com"),
            uiOutput(ns("error_email")),
            textInput(ns("citation"), "Citation *", placeholder = "Full citation of the primary research article"),
            uiOutput(ns("error_citation")),
            shiny::tagAppendAttributes(
              textInput(ns("title"), "Title *", placeholder = "Title of the SR function"),
              title = "Format: Author et al. Year: Function description. Example: Honea et al. 2016: Chinook egg-to-fry survival vs incubation temperature",
              `data-toggle` = "tooltip",
              `data-placement` = "right",
              `data-trigger` = "focus"
            ),
            uiOutput(ns("error_title"))
          )
        ),
        fluidRow(
          column(
            6,
            offset = 3,
            textAreaInput(ns("notes"), "Notes *", rows = 5, placeholder = "Use this section to describe the stressor-response relationship you are submitting, why it should be included, and any additional details that you believe would be useful to us."),
            uiOutput(ns("error_notes"))
          )
        ),
        # optional csv upload for supporting data + optional PDF
        fluidRow(
          column(6, offset = 3, wellPanel(
            strong("Optional File Uploads"),
            div(id = ns("pdf_wrapper"), customFileInput(ns("supporting_pdf"), "Optional: PDF from which the relationship comes", accept = c(".pdf", "application/pdf"))),
            shinyjs::hidden(
              actionButton(ns("remove_pdf"), "Remove PDF",
                icon = icon("times-circle"),
                class = "btn btn-sm btn-outline-danger mb-2"
              )
            ),
            uiOutput(ns("pdf_validation_status")),
            div(id = ns("csv_wrapper"), customFileInput(ns("sr_csv_file"), "Optional: CSV data for relationship curve(s)", accept = ".csv")),
            shinyjs::hidden(
              actionButton(ns("remove_csv"), "Remove CSV",
                icon = icon("times-circle"),
                class = "btn btn-sm btn-outline-danger mb-2"
              )
            ),
            uiOutput(ns("csv_validation_status")),
            tags$div(
              # style = "margin-top:8px;",
              tags$a(
                href = "#", class = "link-primary",
                onclick = "var clickEl = document.querySelector('a[data-value=\"User Guide\"]'); if (clickEl) { clickEl.click(); setTimeout(function(){ var el = document.getElementById('examples-of-valid-csv-files'); if (el) { el.setAttribute('tabindex', '-1'); el.scrollIntoView({behavior: 'smooth', block: 'start'}); } }, 200); } return false;",
                "Read the User Guide for CSV formatting and examples"
              )
            ),
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
            downloadButton(ns("download_csv_template"), "Download CSV Template", class = "btn btn-info mb-2")
          ))
        ),
        fluidRow(
          column(6,
            offset = 3,
            actionButton(ns("submit_relationship"), "Submit Relationship", class = "btn btn-primary btn-block"),
            tags$br(), tags$br(),
            uiOutput(ns("error_files")),
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

    # Reactive values to store the uploaded CSV and PDF data and their validation results
    uploaded_csv_data <- reactiveVal(NULL)
    uploaded_csv_validation <- reactiveVal(NULL)
    uploaded_pdf_validation <- reactiveVal(NULL)

    # Handle CSV file upload and validation
    observeEvent(input$sr_csv_file, {
      req(input$sr_csv_file)
      shinyjs::show("remove_csv")
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

    # Handle PDF file upload and validation (inline)
    observeEvent(input$supporting_pdf, {
      req(input$supporting_pdf)
      shinyjs::show("remove_pdf")
      file <- input$supporting_pdf

      validation_result <- tryCatch(
        validate_pdf_upload(file),
        error = function(e) {
          output$pdf_validation_status <- renderUI({
            tags$div(class = "alert alert-danger", paste("PDF validation error:", conditionMessage(e)))
          })
          list(valid = FALSE, message = conditionMessage(e), issues = list(conditionMessage(e)))
        }
      )

      if (isTRUE(validation_result$valid)) {
        fpath <- file$datapath
        file_size <- NA
        if (!is.null(fpath) && file.exists(fpath)) {
          file_size <- file.info(fpath)$size
        }

        details <- list(
          sprintf("Filename: %s", file$name),
          sprintf("Size (MB): %s", ifelse(is.na(file_size), "unknown", sprintf("%.3f", file_size / 1e6)))
        )

        uploaded_pdf_validation(validation_result)

        output$pdf_validation_status <- renderUI({
          HTML(create_alert_html(
            type = "success",
            message = "PDF is valid and ready to submit",
            details = details
          ))
        })
      } else {
        uploaded_pdf_validation(NULL)
        output$pdf_validation_status <- renderUI({
          HTML(create_alert_html(
            type = "error",
            message = sprintf("PDF upload validation failed: %s", validation_result$message),
            details = validation_result$issues
          ))
        })
      }
    })

    # Handle removal of uploaded CSV
    observeEvent(input$remove_csv, {
      shinyjs::reset("csv_wrapper")
      shinyjs::hide("remove_csv")
      uploaded_csv_data(NULL)
      uploaded_csv_validation(NULL)
      output$csv_validation_status <- renderUI(NULL)
    })

    # Handle removal of uploaded PDF
    observeEvent(input$remove_pdf, {
      shinyjs::reset("pdf_wrapper")
      shinyjs::hide("remove_pdf")
      uploaded_pdf_validation(NULL)
      output$pdf_validation_status <- renderUI(NULL)
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

      # Require that PDF (if provided) was validated on upload — reuse cached result
      if (!is.null(input$supporting_pdf)) {
        pdf_cached <- uploaded_pdf_validation()
        if (is.null(pdf_cached)) {
          show_error_modal(session, "PDF Not Validated", "Please upload and validate your PDF file before submitting (use the file chooser to re-upload).")
          return()
        }
        if (!isTRUE(pdf_cached$valid)) {
          show_error_modal(session, "PDF Validation Failed", pdf_cached$message)
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

      # Prepare to send notification email asynchronously
      smtp_host <- Sys.getenv("SMTP_HOST")
      smtp_port <- as.integer(Sys.getenv("SMTP_PORT"))
      smtp_user <- Sys.getenv("SMTP_USER")
      smtp_pass <- Sys.getenv("SMTP_PASS")
      smtp_from <- Sys.getenv("SMTP_FROM")
      admin_to <- Sys.getenv("ADMIN_EMAIL")

      if (nzchar(smtp_host) && nzchar(smtp_user) && nzchar(smtp_pass) && nzchar(smtp_from) && nzchar(admin_to)) {
        if (.email_support) {
          attachments <- character(0)
          if (!is.null(saved_files$csv)) attachments <- c(attachments, saved_files$csv)
          if (!is.null(saved_files$pdf)) attachments <- c(attachments, saved_files$pdf)

          email_text <- paste0(
            "New Relationship Submission\n\n",
            "Name: ", input$name, "\n",
            "Email: ", input$email, "\n",
            "Title: ", input$title, "\n",
            "Citation: ", input$citation, "\n\n",
            "Notes:\n", input$notes, "\n\n",
            "Attachments: ", paste(basename(attachments), collapse = ", ")
          )

          # Build emayili envelope
          email_env <- emayili::envelope() %>%
            emayili::from(smtp_from) %>%
            emayili::to(admin_to) %>%
            emayili::subject(paste("New relationship submission:", input$title)) %>%
            emayili::text(email_text)

          # Attach files if present
          if (length(attachments) > 0) {
            for (att in attachments) {
              email_env <- email_env %>% emayili::attachment(att)
            }
          }

          promises::future_promise(
            {
              tryCatch(
                {
                  smtp <- emayili::server(host = smtp_host, port = smtp_port, username = smtp_user, password = smtp_pass)
                  smtp(email_env)
                },
                error = function(e) {
                  stop(sprintf("SMTP send error: %s", conditionMessage(e)))
                }
              )
            },
            seed = TRUE
          ) %...>%
            (function(res) {
              message(sprintf("[EMAIL SENT] Submission notification sent"))
              invisible(NULL)
            }) %...!%
            (function(e) {
              err_msg <- conditionMessage(e)
              message(sprintf("[EMAIL ERROR] Failed to send submission email: %s", err_msg))
              try(
                {
                  show_error_modal(session, "Email Send Failed", sprintf("Notification email failed to send: %s", err_msg))
                },
                silent = TRUE
              )
              invisible(NULL)
            })
        } else {
          message("[EMAIL SKIPPED] required packages (future/promises/emayili) not installed; not sending submission email.")
        }
      } else {
        message("[EMAIL SKIPPED] SMTP config missing; not sending submission email.")
      }

      # Clear cached upload state and reset the form UI after successful submission
      uploaded_csv_data(NULL)
      uploaded_csv_validation(NULL)
      uploaded_pdf_validation(NULL)
      output$csv_validation_status <- renderUI(NULL)
      output$pdf_validation_status <- renderUI(NULL)
      shinyjs::hide("remove_csv")
      shinyjs::hide("remove_pdf")
      reset("submit_relationship_form")

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
