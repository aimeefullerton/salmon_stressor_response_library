# nolint start
library(shiny)
library(plotly)
library(DBI)

overlay_plot_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      column(12,
             plotlyOutput(ns("comparison_chart"), height = "750px")
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
    
    # 1. Fetch Quantitative Data & Merge Titles
    plot_data <- reactive({
      ids <- selected_ids_reactive()
      req(length(ids) > 0)
      
      ids_sql <- paste(ids, collapse = ",")
      query <- sprintf("SELECT * FROM csv_data WHERE article_id IN (%s)", ids_sql)
      
      df_csv <- tryCatch({
        dbGetQuery(db_conn, query)
      }, error = function(e) {
        data.frame()
      })
      
      # Merge the real article title from the metadata so it shows in the legend
      if(nrow(df_csv) > 0) {
        meta <- full_metadata_reactive()
        df_csv <- merge(df_csv, meta[, c("article_id", "title")], by = "article_id", all.x = TRUE)
      }
      
      df_csv
    })
    
    # 2. Build the Interactive Plotly Graph
    output$comparison_chart <- renderPlotly({
      df <- plot_data()
      
      if (nrow(df) == 0) {
        return(
          plot_ly() %>% 
            layout(
              title = list(text = "No Quantitative CSV Data Available for Selected Profiles", font = list(color = "red")),
              xaxis = list(title = "Stressor", showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
              yaxis = list(title = "Response", showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE)
            )
        )
      }
      
      # Sort data so lines draw correctly left-to-right
      df <- df[order(df$article_id, df$curve_id, df$stressor_x), ]
      
      # Create clean legend groups (Handles old data where curve_id might be NA)
      df$curve_label <- ifelse(is.na(df$curve_id) | df$curve_id == "", "", paste0(" (Curve: ", df$curve_id, ")"))
      df$legend_group <- paste0(df$title, df$curve_label)
      
      # Draw the overlay plot
      p <- plot_ly(df, x = ~stressor_x, y = ~response_y, color = ~legend_group, 
                   type = 'scatter', mode = 'lines+markers',
                   hoverinfo = 'text',
                   text = ~paste("<b>Article:</b>", title,
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
    
    # 3. Build the Summary Cards (UPDATED TO SALMONID SCHEMA)
    output$selected_summary_cards <- renderUI({
      ids <- selected_ids_reactive()
      req(length(ids) > 0)
      
      all_meta <- full_metadata_reactive()
      selected_meta <- all_meta[as.character(all_meta$article_id) %in% as.character(ids), ]
      
      cards <- lapply(1:nrow(selected_meta), function(i) {
        row <- selected_meta[i, ]
        
        div(
          style = "border: 1px solid #d1d8e0; border-left: 4px solid #3182ce; border-radius: 5px; padding: 15px; margin-bottom: 15px; background-color: #f8fafc;",
          fluidRow(
            column(12, h5(strong(paste0(row$article_id, ". ", row$title)), style = "margin-top: 0; color: #2b6cb0;")),
            column(4, p(strong("Species: "), row$species_common_name, style = "margin-bottom: 5px;")),
            column(4, p(strong("Stressor: "), row$stressor_name, style = "margin-bottom: 5px;")),
            column(4, p(strong("Response: "), row$response, style = "margin-bottom: 5px;"))
          )
        )
      })
      do.call(tagList, cards)
    })
  })
}
# nolint end
