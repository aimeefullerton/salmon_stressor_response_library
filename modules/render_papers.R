# nolint start
render_papers_server <- function(output, paginated_data, input, session) {
  output$paper_cards <- renderUI({
    data_to_display <- paginated_data()

    format_field <- function(label, val, bold = FALSE) {
      # UPDATED: Expanded the check to catch "N/A" and length-0 vectors just in case
      display <- ifelse(is.null(val) || length(val) == 0 || is.na(val) || val == "NA" || val == "N/A", "", val)
      if (display == "") {
        return("")
      }
      value_span <- sprintf("<span class='%s'>%s</span>", if (bold) "metadata-bold" else "metadata-light", htmltools::htmlEscape(display))
      label_span <- sprintf("<span class='metadata-label'>%s:</span> ", htmltools::htmlEscape(label))
      div_class <- "paper-meta-item"
      
      # UPDATED: Added inline styles here to force text wrapping and prevent boundary overflow
      sprintf("<div class='%s' title='%s' style='white-space: normal !important; word-break: break-word; overflow-wrap: break-word; padding-right: 15px; flex: 1 1 auto; min-width: 150px;'>%s%s</div>", 
              div_class, htmltools::htmlEscape(display), label_span, value_span)
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

        div(
          class = "hover-highlight",
          # UPDATED: width to 100% to fill your UI columns, and height to auto
          style = "padding: 12px 15px; margin: 10px auto; border-radius: 6px; width: 100%;
                display: flex; align-items: flex-start; justify-content: flex-start;
                border: 1px solid #ddd; background-color: #f9f9f9; min-height: 100px; height: auto;",

          # Checkbox
          div(
            # UPDATED: Added flex-shrink: 0 to stop the checkbox from squishing
            style = "margin-right: 15px; margin-top: 5px; flex-shrink: 0;",
            checkboxInput(inputId = checkbox_id, label = NULL, value = FALSE, width = "20px")
          ),

          # Title + Metadata block
          div(
            # UPDATED: Added min-width: 0 to force flexbox to respect text-wrapping
            style = "flex-grow: 1; padding-left: 10px; min-width: 0;",

            # Title
            div(
              style = "margin-bottom: 8px; white-space: normal; word-wrap: break-word;",
              actionButton(
                inputId = paste0("view_article_", paper$article_id),
                label = paste0(paper$article_id, ". ", paper$title),
                class = "paper-card-title btn-link",
                style = "text-align: left; white-space: normal; word-wrap: break-word; padding: 0;"
              )
            ),

            # Metadata rows
            # UPDATED: Added display: flex and flex-wrap: wrap so items drop down instead of pushing off-screen
            div(
              class = "paper-meta-row",
              style = "display: flex; flex-wrap: wrap; margin-bottom: 4px;",
              HTML(format_field("Common Name", paper$species_common_name, TRUE)),
              HTML(format_field("Life Stage", paper$life_stages, TRUE)),
              HTML(format_field("Type", paper$article_type, TRUE)),
              HTML(format_field("Activity", paper$activity, TRUE))
            ),
            div(
              class = "paper-meta-row",
              style = "display: flex; flex-wrap: wrap; margin-bottom: 4px;",
              HTML(format_field("Stressor", paper$stressor_name, TRUE)),
              HTML(format_field("Metric", paper$specific_stressor_metric, TRUE)),
              HTML(format_field("Broad Stressor", paper$broad_stressor_name, TRUE)),
              HTML(format_field("Latin Name", paper$latin_name, TRUE))
            ),
            div(
              class = "paper-meta-row",
              style = "display: flex; flex-wrap: wrap;",
              HTML(format_field("River/Creek", paper$location_river_creek, TRUE)),
              HTML(format_field("Watershed/Lab", paper$location_watershed_lab, TRUE)),
              HTML(format_field("State/Province", paper$location_state_province, TRUE)),
              HTML(format_field("Country", paper$location_country, TRUE))
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
