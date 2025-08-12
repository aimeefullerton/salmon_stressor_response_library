# nolint start

library(shinyjs)
library(shiny)
library(shinyWidgets)

# Source all necessary modules
source("modules/upload.R", local = TRUE)
source("modules/manage_categories.R", local = TRUE)
source("modules/about_us.R", local = TRUE)
source("modules/acknowledgement.R", local = TRUE)
source("modules/eda.R", local = TRUE)

#* Static resource for team images
addResourcePath("teamimg", "modules/images")

#* UI
ui <- navbarPage(
  id = "main_navbar",
  title = "Salmon Stressor-Response eLibrary",
  selected = "dashboard",

  #* Welcome Tab
  tabPanel(
    title = "Welcome",
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

          // Enhanced navigation and filter management
          var filterManagement = {
            // Track filter state in browser memory as backup
            filterState: {},

            // Save current filter values
            saveFilters: function() {
              this.filterState = {
                stressor: $('#stressor').val() || [],
                stressor_metric: $('#stressor_metric').val() || [],
                species: $('#species').val() || [],
                geography: $('#geography').val() || [],
                life_stage: $('#life_stage').val() || [],
                activity: $('#activity').val() || [],
                genus_latin: $('#genus_latin').val() || [],
                species_latin: $('#species_latin').val() || [],
                research_article_type: $('#research_article_type').val() || [],
                location_country: $('#location_country').val() || [],
                location_state_province: $('#location_state_province').val() || [],
                location_watershed_lab: $('#location_watershed_lab').val() || [],
                location_river_creek: $('#location_river_creek').val() || [],
                broad_stressor_name: $('#broad_stressor_name').val() || []
              };
              console.log('Filters saved to JavaScript:', this.filterState);
            },

            // Navigate back to dashboard
            backToDashboard: function() {
              // Clean URL (remove main_id parameter)
              var url = new URL(window.location);
              url.searchParams.delete('main_id');

              // Update browser URL without page reload
              window.history.pushState({}, '', url.toString());

              // Notify Shiny of URL change
              Shiny.setInputValue('url_changed', Date.now(), {priority: 'event'});

              // Trigger filter restoration after a delay
              setTimeout(function() {
                Shiny.setInputValue('trigger_filter_restore', Date.now(), {priority: 'event'});
              }, 300);
            }
          };

          // Save filters before navigating to article
          $(document).on('click', 'a[onclick*=\"showArticle\"], .card-link', function() {
            filterManagement.saveFilters();
          });

          // Monitor URL changes (browser back/forward)
          window.addEventListener('popstate', function(event) {
            // Trigger filter restoration when using browser navigation
            if (!window.location.search.includes('main_id')) {
              setTimeout(function() {
                Shiny.setInputValue('trigger_filter_restore', Date.now(), {priority: 'event'});
              }, 200);
            }
          });

          // Debug: Monitor filter changes
          $(document).on('shiny:inputchanged', function(event) {
            if (event.name && (event.name.includes('stressor') || event.name.includes('species') || event.name.includes('geography'))
                && !window.location.search.includes('main_id')) {
              console.log('Filter updated in dashboard:', event.name, event.value);
            }
          });
        "))
      ),
      h1("Welcome to the Salmon Stressor-Response eLibrary"),
      tags$div(
        h2("About Us"),
        about_us("about_us")
      ),
      tags$hr(),
      tags$div(
        acknowledgement_ui("acknowledgement", n = 20)
      )
    )
  ),

  #* Dashboard Tab
  tabPanel("Analyze Data", edaUI("eda")),
  tabPanel(
    title = "SRF Dashboard",
    value = "dashboard",
    fluidPage(
      useShinyjs(),
      conditionalPanel(
        condition = "!window.location.search.includes('main_id')",
        fluidRow(
          column(8, textInput("search", "Search All Text", placeholder = "Type keywords...")),
          column(4, actionButton("toggle_filters", "Show Filters", icon = icon("filter")))
        ),
        # shinyjs::hidden(
        #   fluidRow(
        #     column(6, numericInput("page", NULL, value = 1, min = 1)),
        #     column(6, numericInput("page_size", NULL, value = 10, min = 1))
        #   )
        # ),
        conditionalPanel(
          condition = "input.toggle_filters % 2 == 1 || input.stressor.length > 0 || input.stressor_metric.length > 0 || input.species.length > 0 || input.geography.length > 0 || input.life_stage.length > 0 || input.activity.length > 0 || input.genus_latin.length > 0 || input.species_latin.length > 0 || input.research_article_type.length > 0 || input.location_country.length > 0 || input.location_state_province.length > 0 || input.location_watershed_lab.length > 0 || input.location_river_creek.length > 0 || input.broad_stressor_name.length > 0",
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
            column(3, pickerInput("geography", "Geography (Region)",
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
            )),
            column(3, pickerInput("broad_stressor_name", "Broad Stressor Name",
              choices = list(), multiple = TRUE,
              options = list("actions-box" = TRUE, "live-search" = TRUE)
            ))
          ),
          fluidRow(
            column(12, div(
              style = "text-align: right;",
              actionButton("reset_filters_btn", "Reset Filters",
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
              "All Records" = "all",
              "Filtered Records" = "filtered",
              "Selected Records" = "selected"
            ),
            selected = "all"
          ),

          # Wrapped Confirm Download button with proper styling
          div(
            style = "width: 100%;",
            downloadButton("download_csv", "Confirm Download", class = "btn btn-success text-white btn-block")
          )
        ),
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
      conditionalPanel(
        condition = "window.location.search.includes('main_id')",
        fluidRow(
          column(8, offset = 2, uiOutput("article_content"))
        )
      )
    )
  ),

  #* Upload Tab
  tabPanel(
    title = "Upload Data",
    value = "upload_data",
    upload_ui("upload")
  ),

  #* Admin Tab
  tabPanel(
    title = "Admin",
    value = "manage_categories",
    uiOutput("categories_auth_ui")
  )
)

# nolint end
