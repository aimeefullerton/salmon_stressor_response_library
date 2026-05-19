# modules/eda.R
# nolint start
library(shiny)
library(DBI)
library(dplyr)
library(ggplot2)
library(RPostgres)
library(pool)
library(plotly)

# UI for EDA module
edaUI <- function(id) {
  ns <- NS(id)
  tagList(
    fluidPage(
      h3("Exploratory Data Analysis", style = "color: #0077b6; text-align: center;"),
      tabsetPanel(
        tabPanel("Stressor Distribution", plotlyOutput(ns("plot_stressor"))),
        tabPanel("Species", plotlyOutput(ns("plot_species"))),
        tabPanel("Life Stages", plotlyOutput(ns("plot_lifestage"))),
        tabPanel("Top Locations", plotlyOutput(ns("plot_locations")))
      )
    )
  )
}

# Server for EDA module
edaServer <- function(id) {
  moduleServer(id, function(input, output, session) {
    # Shared colors
    bar_fill <- "#F49D5C"
    text_color <- "#005f5f"

    # Helper to pull top N counts for plain text columns
    top_n_counts <- function(tbl, col, n = 10) {
      df <- dbGetQuery(pool, sprintf("
        SELECT %s AS value, COUNT(*) AS n
        FROM stressor_responses
        WHERE %s IS NOT NULL AND TRIM(%s) <> ''
        GROUP BY %s
        ORDER BY n DESC
        LIMIT %d", col, col, col, col, n))
      
      # THE FIX: Convert integer64 to standard numeric for Plotly
      df$n <- as.numeric(df$n)
      
      df
    }

    # 1. Stressor names
    output$plot_stressor <- renderPlotly({
      df <- top_n_counts("stressor_responses", "stressor_name", 10)
      
      p <- ggplot(df, aes(x = reorder(value, n), y = n, text = paste("Stressor:", value, "<br>Count:", n))) +
        geom_col(fill = bar_fill) +
        coord_flip() +
        labs(title = "Top 10 Stressor Names", x = NULL, y = "Count") +
        theme_minimal() +
        theme(
          plot.title = element_text(size = 18, face = "bold", color = text_color),
          axis.text = element_text(size = 12, color = text_color),
          axis.title = element_text(size = 14, color = text_color),
          panel.grid.major.x = element_blank()
        )
      
      ggplotly(p, tooltip = "text") %>% config(displayModeBar = FALSE)
    })

    # 2. Species
    output$plot_species <- renderPlotly({
      df1 <- dbGetQuery(pool, "
        SELECT TRIM(unnested) AS raw, COUNT(*) AS n
        FROM stressor_responses,
          LATERAL unnest(species_common_name) AS unnested
        WHERE species_common_name IS NOT NULL
          AND array_length(species_common_name, 1) > 0
        GROUP BY raw
        ORDER BY n DESC
        LIMIT 10
      ")
      
      # THE FIX: Convert integer64 to standard numeric for Plotly
      df1$n <- as.numeric(df1$n)

      p <- ggplot(df1, aes(x = reorder(raw, n), y = n, text = paste("Species:", raw, "<br>Count:", n))) +
        geom_col(fill = bar_fill) +
        coord_flip() +
        labs(title = "Top 10 Species", x = NULL, y = "Count") +
        theme_minimal() +
        theme(
          plot.title = element_text(size = 18, face = "bold", color = text_color),
          axis.text  = element_text(size = 12, color = text_color),
          axis.title = element_text(size = 14, color = text_color),
          panel.grid.major.x = element_blank()
        )
      
      ggplotly(p, tooltip = "text") %>% config(displayModeBar = FALSE)
    })

    # 3. Life-stages
    output$plot_lifestage <- renderPlotly({
      df1 <- dbGetQuery(pool, "
        SELECT TRIM(unnested) AS raw, COUNT(*) AS n
        FROM stressor_responses,
          LATERAL unnest(life_stages) AS unnested
        WHERE life_stages IS NOT NULL
          AND array_length(life_stages, 1) > 0
        GROUP BY raw
        ORDER BY n DESC
        LIMIT 10
      ")
      
      # THE FIX: Convert integer64 to standard numeric for Plotly
      df1$n <- as.numeric(df1$n)

      p <- ggplot(df1, aes(x = reorder(raw, n), y = n, text = paste("Life Stage:", raw, "<br>Count:", n))) +
        geom_col(fill = bar_fill) +
        coord_flip() +
        labs(title = "Top 10 Life Stages", x = NULL, y = "Count") +
        theme_minimal() +
        theme(
          plot.title = element_text(size = 18, face = "bold", color = text_color),
          axis.text  = element_text(size = 12, color = text_color),
          axis.title = element_text(size = 14, color = text_color),
          panel.grid.major.x = element_blank()
        )
      
      ggplotly(p, tooltip = "text") %>% config(displayModeBar = FALSE)
    })

    # 4. Locations
    output$plot_locations <- renderPlotly({
      df1 <- dbGetQuery(pool, "
        SELECT TRIM(unnested) AS raw, COUNT(*) AS n
        FROM stressor_responses,
          LATERAL unnest(location_state_province) AS unnested
        WHERE location_state_province IS NOT NULL
          AND array_length(location_state_province, 1) > 0
        GROUP BY raw
        ORDER BY n DESC
        LIMIT 10
      ")
      
      # THE FIX: Convert integer64 to standard numeric for Plotly
      df1$n <- as.numeric(df1$n)

      p <- ggplot(df1, aes(x = reorder(raw, n), y = n, text = paste("Location:", raw, "<br>Count:", n))) +
        geom_col(fill = bar_fill) +
        coord_flip() +
        labs(title = "Top 10 States / Provinces", x = NULL, y = "Count") +
        theme_minimal() +
        theme(
          plot.title = element_text(size = 18, face = "bold", color = text_color),
          axis.text  = element_text(size = 12, color = text_color),
          axis.title = element_text(size = 14, color = text_color),
          panel.grid.major.x = element_blank()
        )
      
      ggplotly(p, tooltip = "text") %>% config(displayModeBar = FALSE)
    })

  })
}
# nolint end
