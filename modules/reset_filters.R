# nolint start
reset_filters_server <- function(input, session) {
  observeEvent(input$reset_filters_btn, {
    updateTextInput(session, "search", value = "")

    updatePickerInput(session, "stressor", selected = "All")
    updatePickerInput(session, "stressor_metric", selected = "All")
    updatePickerInput(session, "species", selected = "All")
    updatePickerInput(session, "geography", selected = "All")
    updatePickerInput(session, "life_stage", selected = "All")
    updatePickerInput(session, "activity", selected = "All")
    updatePickerInput(session, "genus_latin", selected = "All")
    updatePickerInput(session, "species_latin", selected = "All")

    # New filters
    updatePickerInput(session, "research_article_type", selected = "All")
    updatePickerInput(session, "location_country", selected = "All")
    updatePickerInput(session, "location_state_province", selected = "All")
    updatePickerInput(session, "location_watershed_lab", selected = "All")
    updatePickerInput(session, "location_river_creek", selected = "All")
    updatePickerInput(session, "broad_stressor_name", selected = "All")
  })
}
# nolint end
