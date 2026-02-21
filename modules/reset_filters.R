# nolint start
reset_filters_server <- function(input, session) {
  observeEvent(input$reset_filters, {
    updateTextInput(session, "search", value = "")

    updateSelectInput(session, "stressor", selected = "All")
    updateSelectInput(session, "stressor_metric", selected = "All")
    updateSelectInput(session, "species", selected = "All")
    updateSelectInput(session, "life_stage", selected = "All")
    updateSelectInput(session, "activity", selected = "All")
    updateSelectInput(session, "genus_latin", selected = "All")
    updateSelectInput(session, "species_latin", selected = "All")
    updateSelectInput(session, "article_type", selected = "All")
    updateSelectInput(session, "location_country", selected = "All")
    updateSelectInput(session, "location_state_province", selected = "All")
    updateSelectInput(session, "location_watershed_lab", selected = "All")
    updateSelectInput(session, "location_river_creek", selected = "All")
    updateSelectInput(session, "broad_stressor_name", selected = "All")
  })
}
# nolint end
