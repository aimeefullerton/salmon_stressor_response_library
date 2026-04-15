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
      label_span <- sprintf("<span class='metadata-light'>%s:</span> ", htmltools::htmlEscape(label))
      value_span <- sprintf("<span class='metadata-bold'>%s</span>", htmltools::htmlEscape(display))
      
      sprintf("<div class='paper-meta-item'>%s%s</div>", label_span, value_span)
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

        # Safely pull the userid for the badge (defaults to "Unknown" if column is missing)
        contributor <- if ("contributor_name" %in% names(paper) && !is.na(paper$contributor_name)) paper$contributor_name else "UNKNOWN"

        div(
          class = "paper-card", # NEW: Uses your modern card CSS

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
              style = "margin-bottom: 8px; width: 100%;", 
              actionButton(
                inputId = paste0("view_article_", paper$article_id),
                label = paste0(paper$article_id, ". ", paper$title),
                class = "paper-card-title btn-link",
                
                # UPDATED STYLE: Forces block display, overrides text wrapping, and cuts 160px off the max width
                style = "display: block; text-align: left; padding: 0; white-space: normal !important; word-break: break-word; max-width: calc(100% - 160px); border: none; background: none;"
              )
            ),

# Metadata rows - CSS classes paper-meta-row and paper-meta-item do the aligning!
            div(
              class = "paper-meta-row",
              HTML(format_field("Common Name", paper$species_common_name)),
              HTML(format_field("Life Stage", paper$life_stages)),
              HTML(format_field("Type", paper$article_type)),
              HTML(format_field("Activity", paper$activity))
            ),
            div(
              class = "paper-meta-row",
              HTML(format_field("Stressor", paper$stressor_name)),
              HTML(format_field("Metric", paper$specific_stressor_metric)),
              HTML(format_field("Response", paper$response)),
              HTML(format_field("Latin Name", paper$latin_name))
            ),
            div(
              class = "paper-meta-row",
              HTML(format_field("River/Creek", paper$location_river_creek)),
              HTML(format_field("Watershed/Lab", paper$location_watershed_lab)),
              HTML(format_field("State/Province", paper$location_state_province)),
              HTML(format_field("Country", paper$location_country))
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
