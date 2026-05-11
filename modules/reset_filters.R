# nolint start
reset_filters_server <- function(input, session) {
  observeEvent(input$reset_filters, {
    updateTextInput(session, "search", value = "")

    updatePickerInput(session, "stressor", selected = character(0))
    updatePickerInput(session, "stressor_metric", selected = character(0))
    updatePickerInput(session, "species", selected = character(0))
    updatePickerInput(session, "life_stage", selected = character(0))
    updatePickerInput(session, "activity", selected = character(0))
    updatePickerInput(session, "latin_name", selected = character(0))
    updatePickerInput(session, "article_type", selected = character(0))
    updatePickerInput(session, "location_country", selected = character(0))
    updatePickerInput(session, "location_state_province", selected = character(0))
    updatePickerInput(session, "location_watershed_lab", selected = character(0))
    updatePickerInput(session, "location_river_creek", selected = character(0))
    updatePickerInput(session, "broad_stressor_name", selected = character(0))
  })
}
# nolint end
