# nolint start
reset_filters_server <- function(input, session) {
  observeEvent(input$reset_filters, {
    filters <- c("stressor", "stressor_metric", "species", "life_stage", "activity", 
                 "latin_name", "article_type", "location_country", "location_state_province", 
                 "location_watershed_lab", "location_river_creek", "broad_stressor_name")
    
    for (f in filters) {
      updateSelectizeInput(session, f, selected = character(0))
    }
  })
}
# nolint end
