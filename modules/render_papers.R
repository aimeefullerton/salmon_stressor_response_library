# nolint start
render_papers_server <- function(output, paginated_data, input, session) {
  output$paper_cards <- renderUI({
    data_to_display <- paginated_data()

    format_field <- function(label, val, bold = FALSE) {
      display <- ifelse(is.na(val) || val == "NA", "", val)
      if (display == "") {
        return("")
      }
      value_span <- sprintf("<span class='%s'>%s</span>", if (bold) "metadata-bold" else "metadata-light", htmltools::htmlEscape(display))
      label_span <- sprintf("<span class='metadata-label'>%s:</span> ", htmltools::htmlEscape(label))
      div_class <- "paper-meta-item"
      sprintf("<div class='%s' title='%s'>%s%s</div>", div_class, htmltools::htmlEscape(display), label_span, value_span)
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

        article_url <- paste0("?main_id=", paper$main_id)
        checkbox_id <- paste0("select_article_", paper$main_id)

        div(
          class = "hover-highlight",
          style = "padding: 8px 12px; margin: 6px auto; border-radius: 6px; width: 95%;
                display: flex; align-items: flex-start; justify-content: flex-start;
                border: 1px solid #ddd; background-color: #f9f9f9; min-height: 80px;",

          # Checkbox
          div(
            style = "margin-right: 10px; margin-top: 5px;",
            checkboxInput(inputId = checkbox_id, label = NULL, value = FALSE, width = "20px")
          ),

          # Title + Metadata block
          div(
            style = "flex-grow: 1; padding-left: 10px;",

            # Title
            actionButton(
              inputId = paste0("view_article_", paper$main_id),
              label = paste0(paper$main_id, ". ", paper$title),
              class = "paper-card-title btn-link"
            ),

            # Metadata rows
            div(
              class = "paper-meta-row",
              HTML(format_field("Common Name", paper$species_common_name, TRUE)),
              HTML(format_field("Life Stage", paper$life_stages, TRUE)),
              HTML(format_field("Type", paper$research_article_type, TRUE)),
              HTML(format_field("Activity", paper$activity, TRUE))
            ),
            div(
              class = "paper-meta-row",
              HTML(format_field("Stressor", paper$stressor_name, TRUE)),
              HTML(format_field("Metric", paper$specific_stressor_metric, TRUE)),
              HTML(format_field("Broad Stressor", paper$broad_stressor_name, TRUE)),
              HTML(format_field("Genus Latin", paper$genus_latin, TRUE))
            ),
            div(
              class = "paper-meta-row",
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
    ids <- paginated_data()$main_id
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
