# nolint start
library(shiny)
library(plotly)
library(DBI)

overlay_plot_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      column(12,
             plotlyOutput(ns("comparison_chart"), height = "550px")
      )
    ),
    hr(style = "margin-top: 30px; margin-bottom: 30px; border-top: 2px solid #eee;"),
    fluidRow(
      column(12,
             h4(icon("list-ul"), " Selected Profiles Summary", style = "color: #2c3e50; font-weight: 600; margin-bottom: 20px;"),
             uiOutput(ns("selected_summary_cards"))
      )
    )
  )
}

overlay_plot_server <- function(id, selected_ids_reactive, db_conn, full_metadata_reactive) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # 1. Fetch Quantitative Data for the selected IDs
    plot_data <- reactive({
      ids <- selected_ids_reactive()
      req(length(ids) > 0)
      
      # Convert IDs to a format SQL can read (e.g., '1','2','3')
      ids_sql <- paste(ids, collapse = ",")
      
      # Fetch the CSV data points for these specific articles
      query <- sprintf("SELECT * FROM csv_data WHERE article_id IN (%s)", ids_sql)
      
      tryCatch({
        dbGetQuery(db_conn, query)
      }, error = function(e) {
        data.frame() # Return empty if error or no table
      })
    })
    
    # 2. Build the Interactive Plotly Graph
    output$comparison_chart <- renderPlotly({
      df <- plot_data()
      
      if (nrow(df) == 0) {
        # If the user selected papers that don't have CSV data attached
        return(
          plot_ly() %>% 
            layout(
              title = list(text = "No Quantitative CSV Data Available for Selected Profiles", font = list(color = "red")),
              xaxis = list(title = "Stressor", showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
              yaxis = list(title = "Response", showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE)
            )
        )
      }
      
      # Ensure data is sorted by article and stressor x so lines draw correctly left-to-right
      df <- df[order(df$article_id, df$curve_id, df$stressor_x), ]
      
      # Create a unique group name for the legend
      df$legend_group <- paste0("ID ", df$article_id, ": ", df$curve_id)
      
      # Draw the overlay plot
      p <- plot_ly(df, x = ~stressor_x, y = ~response_y, color = ~legend_group, 
                   type = 'scatter', mode = 'lines+markers',
                   hoverinfo = 'text',
                   text = ~paste("<b>Article:</b>", article_id,
                                 "<br><b>Curve:</b>", curve_id,
                                 "<br><b>Stressor:</b>", stressor_x, units_x,
                                 "<br><b>Response:</b>", response_y, units_y)) %>%
        layout(
          title = list(text = "Multi-Stressor Comparison Overlay", font = list(size = 20, color = "#2c3e50")),
          xaxis = list(title = "Stressor Value", gridcolor = "#f0f0f0"),
          yaxis = list(title = "Response Value", gridcolor = "#f0f0f0"),
          hovermode = "closest",
          plot_bgcolor = 'white',
          paper_bgcolor = 'white',
          legend = list(orientation = "h", x = 0, y = -0.2)
        )
      p
    })
    
    # 3. Build the Summary Cards below the plot
    output$selected_summary_cards <- renderUI({
      ids <- selected_ids_reactive()
      req(length(ids) > 0)
      
      # Filter the full dataset to only the selected rows
      all_meta <- full_metadata_reactive()
      selected_meta <- all_meta[all_meta$article_id %in% ids, ]
      
      # Generate a clean card for each selected item
      cards <- lapply(1:nrow(selected_meta), function(i) {
        row <- selected_meta[i, ]
        
        div(
          style = "border: 1px solid #d1d8e0; border-left: 4px solid #3182ce; border-radius: 5px; padding: 15px; margin-bottom: 15px; background-color: #f8fafc;",
          fluidRow(
            column(12, h5(strong(paste0(row$article_id, ". ", row$title)), style = "margin-top: 0; color: #2b6cb0;")),
            column(4, p(strong("Species: "), row$sav_species, style = "margin-bottom: 5px;")),
            column(4, p(strong("Stressor: "), row$specific_sav_metric, style = "margin-bottom: 5px;")),
            column(4, p(strong("Function: "), row$specific_sav_function, style = "margin-bottom: 5px;"))
          )
        )
      })
      do.call(tagList, cards)
    })
  })
}
# nolint end
