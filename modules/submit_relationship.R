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

      # Validate the uploaded CSV
      validation_result <- validate_csv_upload(file$datapath)

      if (validation_result$valid) {
        uploaded_csv_data(validation_result$data)
        output$csv_validation_status <- renderUI({
          tags$div(class = "alert alert-success", "CSV file is valid and has been uploaded.")
        })
      } else {
        uploaded_csv_data(NULL)
        output$csv_validation_status <- renderUI({
          tags$div(class = "alert alert-danger", paste("CSV validation failed:", validation_result$message))
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
