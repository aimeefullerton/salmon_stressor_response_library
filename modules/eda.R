# modules/eda.R
library(shiny)
library(DBI)
library(RSQLite)
library(dplyr)
library(ggplot2)

# UI for EDA module
edaUI <- function(id) {
  ns <- NS(id)
  tagList(
    fluidPage(
      h3("Exploratory Data Analysis", style = "color: #0077b6; text-align: center;"),
      tabsetPanel(
        tabPanel("Stressor Distribution", plotOutput(ns("plot_stressor"))),
        tabPanel("Life Stages",           plotOutput(ns("plot_lifestage")))
      )
    )
  )
}

# Server for EDA module

edaServer <- function(id, db_path = "data/stressor_responses.sqlite") {
  moduleServer(id, function(input, output, session) {
    # Shared colors
    bar_fill   <- "#F49D5C"
    text_color <- "#005f5f"
    
    # Helper to pull top N counts for any column
    top_n_counts <- function(tbl, col, n = 10) {
      db <- dbConnect(SQLite(), db_path); on.exit(dbDisconnect(db), add = TRUE)
      df <- dbGetQuery(db, sprintf("
        SELECT %s AS value, COUNT(*) AS n
        FROM stressor_responses
        WHERE %s IS NOT NULL AND TRIM(%s) <> ''
        GROUP BY %s
        ORDER BY n DESC
        LIMIT %d", col, col, col, col, n))
      df
    }
    
    # 1) Stressor names
    output$plot_stressor <- renderPlot({
      df <- top_n_counts("stressor_responses", "stressor_name", 10)
      ggplot(df, aes(x = reorder(value, n), y = n)) +
        geom_col(fill = bar_fill) +
        coord_flip() +
        labs(
          title = "Top 10 Stressor Names",
          x     = NULL, y = "Count"
        ) +
        theme_minimal() +
        theme(
          plot.title      = element_text(size = 18, face = "bold", color = text_color),
          axis.text       = element_text(size = 12, color = text_color),
          axis.title      = element_text(size = 14, color = text_color),
          panel.grid.major.x = element_blank()
        )
    })

    
    # 3) Life‐stages (explode comma‐separated)
    output$plot_lifestage <- renderPlot({
      db  <- dbConnect(SQLite(), db_path); on.exit(dbDisconnect(db), add = TRUE)
      df0 <- dbGetQuery(db, "
        SELECT life_stages
        FROM stressor_responses
        WHERE life_stages IS NOT NULL AND TRIM(life_stages) <> ''
      ")
      # split & count
      df1 <- tibble::tibble(raw = df0$life_stages) %>%
        tidyr::separate_rows(raw, sep = ",\\s*") %>%
        mutate(raw = trimws(gsub('[\\[\\]\"]', '', raw))) %>%
        filter(raw != "") %>%
        count(raw, name = "n") %>%
        arrange(desc(n)) %>%
        slice_head(n = 10)
      
      ggplot(df1, aes(x = reorder(raw, n), y = n)) +
        geom_col(fill = bar_fill) +
        coord_flip() +
        labs(
          title = "Top 10 Life Stages",
          x     = NULL, y = "Count"
        ) +
        theme_minimal() +
        theme(
          plot.title      = element_text(size = 18, face = "bold", color = text_color),
          axis.text       = element_text(size = 12, color = text_color),
          axis.title      = element_text(size = 14, color = text_color),
          panel.grid.major.x = element_blank()
        )
    })
  })
}
