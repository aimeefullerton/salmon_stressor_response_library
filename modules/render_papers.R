# nolint start
render_papers_server <- function(output, paginated_data, input, session) {
  output$paper_cards <- renderUI({
    data_to_display <- paginated_data()

    format_field <- function(label, val, bold = FALSE) {
      # Expanded the check to catch "N/A" and length-0 vectors just in case
      display <- ifelse(is.null(val) || length(val) == 0 || is.na(val) || val == "NA" || val == "N/A", "", val)
      if (display == "") {
        return("")
      }
      label_span <- sprintf("<span class='metadata-light' style='color: #666;'>%s:</span> ", htmltools::htmlEscape(label))
      value_span <- sprintf("<span class='metadata-bold' style='color: #222; font-weight: 500;'>%s</span>", htmltools::htmlEscape(display))
      
      # Added a slight bottom margin to give the items breathing room
      sprintf("<div class='paper-meta-item' style='margin-bottom: 6px; line-height: 1.3;'>%s%s</div>", label_span, value_span)
    }

    if (is.null(data_to_display) || nrow(data_to_display) == 0) {
      return(tags$p(
        "No research papers found.",
        style = "font-size: 18px; font-weight: bold; color: red;"
      ))
    }

    # Remove rows where all values are NA
    data_to_display <- data_to_display[rowSums(is.na(data_to_display)) != ncol(data_to_display), ]

    tagList(
      lapply(seq_len(nrow(data_to_display)), function(i) {
        paper <- data_to_display[i, ]

        article_url <- paste0("?article_id=", paper$article_id)
        checkbox_id <- paste0("select_article_", paper$article_id)

        # Safely pull the userid for the badge
        contributor <- if ("contributor_name" %in% names(paper) && !is.na(paper$contributor_name)) paper$contributor_name else "UNKNOWN"

        div(
          class = "paper-card", 

          # 1. THE CONTRIBUTOR BADGE
          tags$span(class = "contributor-badge", paste("Entry by:", contributor)),

          # 2. THE CHECKBOX
          div(
            class = "paper-checkbox-container",
            checkboxInput(inputId = checkbox_id, label = NULL, value = FALSE, width = "20px")
          ),

          # 3. THE MAIN CONTENT
          div(
            class = "paper-content",
            
            # Title 
            div(
              style = "margin-bottom: 15px; width: 100%; border-bottom: 2px solid #f0f0f0; padding-bottom: 10px;", 
              actionButton(
                inputId = paste0("view_article_", paper$article_id),
                label = paste0(paper$article_id, ". ", paper$title),
                class = "paper-card-title btn-link",
                style = "display: block; text-align: left; padding: 0; white-space: normal !important; word-break: break-word; max-width: calc(100% - 160px); border: none; background: none; font-size: 1.15em; font-weight: bold; color: #0056b3;"
              )
            ),

            # ── NEW SECTIONED METADATA LAYOUT ──
            fluidRow(
              style = "font-size: 0.95em;",
              
              # Section 1: Biological & Study Info
              column(4,
                div(style = "border-right: 1px solid #eaeaea; padding-right: 15px; height: 100%;",
                  tags$strong("Biological Profile", style = "color: #6082B6; display: block; border-bottom: 1px solid #eaeaea; padding-bottom: 4px; margin-bottom: 10px; text-transform: uppercase; font-size: 0.85em; letter-spacing: 0.5px;"),
                  HTML(format_field("Type", paper$article_type)),
                  HTML(format_field("Common Name", paper$species_common_name)),
                  HTML(format_field("Latin Name", paper$latin_name)),
                  HTML(format_field("Life Stage", paper$life_stages)),
                  HTML(format_field("Activity", paper$activity))
                )
              ),
              
              # Section 2: Stressor Details
              column(4,
                div(style = "border-right: 1px solid #eaeaea; padding-left: 5px; padding-right: 15px; height: 100%;",
                  tags$strong("Stressor & Response", style = "color: #6082B6; display: block; border-bottom: 1px solid #eaeaea; padding-bottom: 4px; margin-bottom: 10px; text-transform: uppercase; font-size: 0.85em; letter-spacing: 0.5px;"),
                  HTML(format_field("Stressor", paper$stressor_name)),
                  HTML(format_field("Stressor Metric", paper$specific_stressor_metric)),
                  HTML(format_field("Response", paper$response))
                )
              ),
              
              # Section 3: Location
              column(4,
                div(style = "padding-left: 5px; height: 100%;",
                  tags$strong("Location", style = "color: #6082B6; display: block; border-bottom: 1px solid #eaeaea; padding-bottom: 4px; margin-bottom: 10px; text-transform: uppercase; font-size: 0.85em; letter-spacing: 0.5px;"),
                  HTML(format_field("Country", paper$location_country)),
                  HTML(format_field("State/Province", paper$location_state_province)),
                  HTML(format_field("Watershed/Lab", paper$location_watershed_lab)),
                  HTML(format_field("River/Creek", paper$location_river_creek))
                )
              )
            )
          )
        )
      })
    )
  })

  # Sync all checkboxes with "Select All"
  observeEvent(input$select_all, {
    ids <- paginated_data()$article_id
    for (mid in ids) {
      updateCheckboxInput(
        session,
        inputId = paste0("select_article_", mid),
        value = input$select_all
      )
    }
  })
}
# nolint end
