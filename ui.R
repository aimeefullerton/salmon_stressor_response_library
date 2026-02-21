# nolint start
library(shinyjs)
library(shiny)
library(shinyWidgets)

# Source all necessary modules
source("modules/upload.R", local = TRUE)
source("modules/about_us.R", local = TRUE)
source("modules/acknowledgement.R", local = TRUE)
source("modules/eda.R", local = TRUE)
source("modules/user_guide.R", local = TRUE)
source("modules/submit_relationship.R", local = TRUE)

# Static resource for team images
addResourcePath("teamimg", "modules/images")

# UI
ui <- navbarPage(
  id = "main_navbar",
  title = "Salmon Stressor-Response eLibrary",
  selected = "dashboard",
  # use Bootstrap 5 for better styling and responsiveness
  # https://bootswatch.com/5/ for themes if desired
  theme = bslib::bs_theme(version = 4), # can add a default bootstrap theme via bootswatch if desired, e.g., bootswatch = "flatly"

  # About Tab
  tabPanel(
    title = "About",
    value = "NOAA info",
    fluidPage(
      useShinyjs(),
      tags$head(
        includeCSS("www/custom.css"),
        tags$style(HTML("
    #back_to_top_fab {
      position: fixed;
      bottom: 30px;
      right: 30px;
      z-index: 9999;
    }
    .dropdown-menu {
      padding: 20px;
    }
    .radio label {
      font-size: 16px;
      font-weight: 500;
    }
  ")),
        tags$script(HTML("
    Shiny.addCustomMessageHandler('download_csv', function(data) {
      document.getElementById(data.id).click();
    });
  "))
      ),
      h1("Welcome to the Salmon Stressor-Response eLibrary"),
      tags$div(
        about_us("about_us")
      ),
      tags$hr(),
      tags$div(
        acknowledgement_ui("acknowledgement", n = 20)
      )
    )
  ),

  # User Guide Tab
  tabPanel("User Guide", userGuideUI("user_guide")),

  # Analyze Data Tab
  tabPanel("Analyze Data", edaUI("eda")),

  # Dashboard Tab
  tabPanel(
    title = "SRF Dashboard",
    value = "dashboard",
    fluidPage(
      useShinyjs(),
      conditionalPanel(
        condition = "!window.location.search.includes('article_id')",
        fluidRow(
          column(8, textInput("search", "Search All Text", placeholder = "Type keywords...")),
          column(4, actionButton("toggle_filters", "Show Filters", icon = icon("filter")))
        ),
        shinyjs::hidden(
          fluidRow(
            column(6, numericInput("page", NULL, value = 1, min = 1)),
            column(6, numericInput("page_size", NULL, value = 10, min = 1))
          )
        ),
        conditionalPanel(
          condition = "input.toggle_filters % 2 == 1",
          fluidRow(
            column(3, pickerInput("stressor", "Stressor Name",
              choices = list(), multiple = TRUE,
              options = list("actions-box" = TRUE, "live-search" = TRUE)
            )),
            column(3, pickerInput("stressor_metric", "Stressor Metric",
              choices = list(), multiple = TRUE,
              options = list("actions-box" = TRUE, "live-search" = TRUE)
            )),
            column(3, pickerInput("species", "Species Common Name",
              choices = list(), multiple = TRUE,
              options = list("actions-box" = TRUE, "live-search" = TRUE)
            )),
            column(3, pickerInput("broad_stressor_name", "Broad Stressor Name",
              choices = list(), multiple = TRUE,
              options = list("actions-box" = TRUE, "live-search" = TRUE)
            ))
          ),
          fluidRow(
            column(3, pickerInput("life_stage", "Life Stage",
              choices = life_stages, multiple = TRUE,
              options = list("actions-box" = TRUE, "live-search" = TRUE)
            )),
            column(3, pickerInput("activity", "Activity",
              choices = list(), multiple = TRUE,
              options = list("actions-box" = TRUE, "live-search" = TRUE)
            )),
            column(3, pickerInput("genus_latin", "Genus Latin",
              choices = list(), multiple = TRUE,
              options = list("actions-box" = TRUE, "live-search" = TRUE)
            )),
            column(3, pickerInput("species_latin", "Species Latin",
              choices = list(), multiple = TRUE,
              options = list("actions-box" = TRUE, "live-search" = TRUE)
            ))
          ),
          fluidRow(
            column(3, pickerInput("research_article_type", "Research Article Type",
              choices = list(), multiple = TRUE,
              options = list("actions-box" = TRUE, "live-search" = TRUE)
            )),
            column(3, pickerInput("location_country", "Country",
              choices = list(), multiple = TRUE,
              options = list("actions-box" = TRUE, "live-search" = TRUE)
            )),
            column(3, pickerInput("location_state_province", "State / Province",
              choices = list(), multiple = TRUE,
              options = list("actions-box" = TRUE, "live-search" = TRUE)
            )),
            column(3, pickerInput("location_watershed_lab", "Watershed / Lab",
              choices = list(), multiple = TRUE,
              options = list("actions-box" = TRUE, "live-search" = TRUE)
            ))
          ),
          fluidRow(
            column(3, pickerInput("location_river_creek", "River / Creek",
              choices = list(), multiple = TRUE,
              options = list("actions-box" = TRUE, "live-search" = TRUE)
            ))
          ),
          fluidRow(
            column(12, div(
              style = "text-align: right;",
              actionLink("reset_filters", "Reset Filters",
                style = "color: #0073e6; font-size: 14px; text-decoration: none; margin-right: 10px;"
              )
            ))
          )
        ),
        fluidRow(
          column(
            12,
            div(
              style = "text-align: center; margin-bottom: 10px;",
              actionButton("prev_page", "<< Previous", class = "btn btn-sm"),
              span(textOutput("page_info", inline = TRUE), style = "margin: 0 10px; font-size: 13px;"),
              actionButton("next_page", "Next >>", class = "btn btn-sm")
            )
          )
        ),
        dropdownButton(
          circle = FALSE,
          status = "primary",
          label = "Download",
          icon = icon("download"),
          tooltip = tooltipOptions(title = "Choose what to download"),

          # Download type selector
          radioButtons("download_option",
            label = NULL,
            choices = c(
              "Filtered records" = "filtered",
              "Selected records" = "selected",
              "Entire database" = "all"
            ),
            selected = "filtered"
          ),

          # Wrapped Confirm Download button with proper styling
          div(
            style = "width: 100%;",
            downloadButton("download_csv", "Confirm Download", class = "btn btn-success text-white btn-block")
          )
        ),

        # component for displaying the papers, displays all papers if no filters are applied
        fluidRow(
          column(6, offset = 3, uiOutput("paper_cards"))
        ),
        br(), br(),
        fluidRow(
          column(12,
            align = "center",
            actionButton("load_more_mode", "Load More", icon = icon("plus")),
            tags$br(), tags$br()
          )
        ),

        # Back to Top floating button
        tags$div(
          id = "back_to_top_fab",
          actionButton(
            inputId = "back_to_top",
            label = NULL,
            icon = icon("arrow-up"),
            class = "btn btn-outline-secondary rounded-circle",
            style = "width: 50px; height: 50px; font-size: 24px;"
          )
        ),
        tags$script(HTML("
            $(document).on('click', '#back_to_top', function() {
              $('html, body').animate({ scrollTop: 0 }, 'slow');
            });
          ")),
        tags$script(HTML("
          $(document).on('click', '#next_page, #prev_page', function() {
            $('html, body').animate({ scrollTop: 0 }, 'smooth');
          });
        "))
      ),
    )
  ),

  # Submit a Relationship Tab
  tabPanel(
    title = "Submit a Relationship",
    value = "submit_relationship",
    submit_relationship_ui("submit_relationship")
  )
)
# nolint end
