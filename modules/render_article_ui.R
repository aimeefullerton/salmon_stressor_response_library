# nolint start

library(shinyjs)
library(dygraphs)

render_article_ui <- function(output, session) {
  output$article_content <- renderUI({
    
    tagList(
      tags$head(
        includeCSS("www/custom.css")
      ),
      useShinyjs(),  # Enabling JavaScript for toggling sections
      
      
      # Back button to return to dashboard
      tags$a(
        href = "?",
        tags$div(id = "customArrow", class = "arrow-container")
      ),
      tags$style(HTML("
        .arrow-container {
          width: 30px;
          height: 30px;
          display: flex;
          align-items: center;
          justify-content: center;
          cursor: pointer;
        }
        
        .arrow-container::before {
          content: '\\2190'; /* Unicode for left arrow */
          font-size: 35px;
          color: #2C3E50;
        }
      ")),
      
      # ===== Article title =====
      fluidRow(
        column(12, align = "center",
               tags$h3(textOutput("article_title"),
                       style = "margin-top: 20px; margin-bottom: 10px;")
        )
      ),
      
      # ===== Expand / Collapse =====
      fluidRow(
        column(12, align = "center",
               actionButton("expand_all",   "Expand All",
                            class = "btn-sm",
                            style = "padding: 8px 16px; margin-right: 8px;"),
               actionButton("collapse_all", "Collapse All",
                            class = "btn-sm",
                            style = "padding: 8px 16px;")
        )
      ),
      
      
      # Article Metadata Section 
      div(style = "border: 1px solid #ddd; padding: 15px; margin-bottom: 10px; background-color: #f8f9fa; border-radius: 8px;",
          actionLink("toggle_metadata", "Article Metadata ▼", class = "section-title"),
          hidden(
            div(id = "metadata_section",
                style = "font-size:1.1em;",    
                fluidRow(
                  column(4, strong("Species Common Name:")),
                  column(8, textOutput("species_name"))
                ),
                fluidRow(
                  column(4, strong("Latin Name (Genus species):")),
                  column(8, em(textOutput("genus_latin")))
                ),
                fluidRow(
                  column(4, strong("Stressor Name:")),
                  column(8, textOutput("stressor_name"))
                ),
                fluidRow(
                  column(4, strong("Specific Stressor Metric:")),
                  column(8, textOutput("specific_stressor_metric"))
                ),
                fluidRow(
                  column(4, strong("Stressor Units:")),
                  column(8, textOutput("stressor_units"))
                ),
                fluidRow(
                  column(4, strong("Vital Rate (Process):")),
                  column(8, textOutput("vital_rate"))
                ),
                fluidRow(
                  column(4, strong("Life Stage:")),
                  column(8, textOutput("life_stage"))
                )
            )
          )
      ),

      # Description & Function Details 
      div(style = "border: 1px solid #ddd; padding: 15px; margin-bottom: 10px; background-color: #ffffff; border-radius: 8px;",
          actionLink("toggle_description", "Description & Function Details ▼", class = "section-title"),
          hidden(div(id = "description_section",
                     style = "font-size:1.1em;", 
              strong("Detailed SR Function Description"), br(), textOutput("description_overview"), br(), br(),
              strong("Function Derivation"), br(), textOutput("function_derivation")
          ))
      ),

      # Citations Section 
      div(style = "border: 1px solid #ddd; padding: 15px; margin-bottom: 10px; background-color: #ffffff; border-radius: 8px;",
          actionLink("toggle_citations", "Citation(s) ▼", class = "section-title"),
          hidden(div(id = "citations_section",  style = "font-size:1.1em;",  uiOutput("citations")))
      ),

      # Images Section 
      div(style = "border: 1px solid #ddd; padding: 15px; margin-bottom: 10px; background-color: #ffffff; border-radius: 8px;",
          actionLink("toggle_images", "Images ▼", class = "section-title"),
          hidden(div(id = "images_section",  style = "font-size:1.1em;", uiOutput("article_images")))
      ),

      # CSV Data Table 
      div(style = "border: 1px solid #ddd; padding: 15px; margin-bottom: 10px; background-color: #ffffff; border-radius: 8px;",
          actionLink("toggle_csv", "Stressor Response Data ▼", class = "section-title"),
          hidden(div(id = "csv_section",  style = "font-size:1.1em;", tableOutput("csv_table")))
      ),

      # Stressor Response Plot 
      #div(style = "border: 1px solid #ddd; padding: 15px; margin-bottom: 10px; background-color: #ffffff; border-radius: 8px;",
         # actionLink("toggle_plot", "Stressor Response Chart ▼", class = "section-title"),
          #hidden(div(id = "plot_section",  style = "font-size:1.1em;", plotOutput("stressor_plot")))
    #  ),
      
      # Interactive Plot Section using dygraphs
      # Interactive Plot Section using Plotly
      div(
        style = "border: 1px solid #ddd; padding: 15px; margin-bottom: 10px; background-color: #ffffff; border-radius: 8px;",
        actionLink("toggle_interactive_plot", "Stressor Response Chart ▼", class = "section-title"),
        hidden(div(id = "interactive_plot_section",  style = "font-size:1.1em;", plotlyOutput("interactive_plot")))
      )
    )
  })
}

# nolint end
