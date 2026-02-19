# nolint start

toggle_filters_server <- function(input, session) {
  observeEvent(input$toggle_filters, {
    new_label <- ifelse(input$toggle_filters %% 2 == 1, "Hide Filters", "Show Filters")
    updateActionButton(session, "toggle_filters", label = new_label)
  })
}

# nolint end
