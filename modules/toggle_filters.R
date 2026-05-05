# nolint start

toggle_filters_server <- function(input, session) {
  observeEvent(input$toggle_filters, {
    new_label <- ifelse(input$toggle_filters %% 2 == 1, "Hide Filters", "Show Filters")
    updateActionButton(session, "toggle_filters", label = new_label)
    
    # This toggles the hidden div we just created in ui.R
    shinyjs::toggle("filter_panel") 
  })
}

# nolint end
