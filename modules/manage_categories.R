# nolint start

library(shiny)
library(DBI)
library(shinyWidgets)

# UI function for Manage Categories module
manageCategoriesUI <- function(id) {
  ns <- NS(id)
  
  cat_choices <- list(
    "Stressor Name"        = "stressor_names",
    "Stressor Metric"      = "stressor_metrics",
    "Species Common Name"  = "species_common_names",
    "Geography"            = "geographies",
    "Life Stage"           = "life_stages",
    "Activity"             = "activities",
    "Genus Latin"          = "genus_latins",
    "Species Latin"        = "species_latins"
  )
  
  tagList(
    # — Category panels —
    fluidRow(
      column(6,
             wellPanel(
               h4("Add Category"),
               selectInput(ns("new_cat_type"),  "Category Type", choices = cat_choices),
               textInput(  ns("new_cat_name"),  "Category Name"),
               actionButton(ns("add_cat"),      "Add Category", class = "btn-primary")
             )
      ),
      column(6,
             wellPanel(
               h4("Delete Category"),
               selectInput(ns("del_cat_type"),  "Category Type", choices = cat_choices),
               pickerInput(ns("del_cat_items"), "Select to Remove",
                           choices = NULL, multiple = TRUE,
                           options = list(`actions-box` = TRUE, `live-search` = TRUE)),
               actionButton(ns("del_cat_btn"),  "Delete Selected", class = "btn-danger")
             )
      )
    ),
    tags$hr(),
    
    # — Article Deletion Panel —
    fluidRow(
      column(12,
             wellPanel(
               h4("Delete Entire Article"),
               fluidRow(
                 column(4,
                        numericInput(ns("del_article_id"),    "Main ID",     value = NA, min = 1)
                 ),
                 column(4,
                        textInput(  ns("del_article_title"), "Title Contains", placeholder = "Search by title")
                 ),
                 column(4,
                        actionButton(ns("search_article"),   "Search", icon = icon("search"))
                 )
               ),
               fluidRow(
                 column(8,
                        pickerInput(ns("del_article_sel"), "Select Article to Delete",
                                    choices = NULL, multiple = FALSE,
                                    options = list(`live-search` = TRUE))
                 ),
                 column(4,
                        actionButton(ns("del_article_btn"), "Delete Article", class = "btn-danger")
                 )
               )
             )
      )
    )
  )
}

# Server function for Manage Categories module
manageCategoriesServer <- function(id, db, onUpdate = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    #
    # 1) —— ADD CATEGORY —— 
    #
    observeEvent(input$add_cat, {
      req(input$new_cat_name)
      tbl  <- input$new_cat_type
      name <- trimws(input$new_cat_name)
      tryCatch({
        dbExecute(db,
                  sprintf("INSERT OR IGNORE INTO %s(name) VALUES (?)", tbl),
                  params = list(name)
        )
        showNotification(sprintf("✅ Added \"%s\"", name), type = "message")
        updateTextInput(session, "new_cat_name", value = "")
        if (!is.null(onUpdate)) onUpdate(runif(1))  # signal lookup update
      }, error = function(e) {
        showNotification(e$message, type = "error")
      })
    })

    #
    # 2) —— DELETE CATEGORY —— 
    #
    observeEvent(input$del_cat_type, {
      names <- dbGetQuery(db,
                          sprintf("SELECT name FROM %s ORDER BY name", input$del_cat_type)
      )$name
      updatePickerInput(session, "del_cat_items", choices = names, selected = NULL)
    }, ignoreInit = TRUE)

    observeEvent(input$del_cat_btn, {
      req(input$del_cat_type, input$del_cat_items)
      tbl       <- input$del_cat_type
      to_delete <- input$del_cat_items
      placeholders <- paste(rep("?", length(to_delete)), collapse = ",")
      sql <- sprintf("DELETE FROM %s WHERE name IN (%s)", tbl, placeholders)
      tryCatch({
        dbExecute(db, sql, params = as.list(to_delete))
        showNotification(
          sprintf("🗑 Deleted %d from %s", length(to_delete), tbl),
          type = "warning"
        )
        updatePickerInput(session, "del_cat_items", choices = character(0))
        if (!is.null(onUpdate)) onUpdate(runif(1))  # signal lookup update
      }, error = function(e) {
        showNotification(e$message, type = "error")
      })
    })

    #
    # 3) —— SEARCH ARTICLES —— 
    #
    observeEvent(input$search_article, {
      query  <- "SELECT main_id, title FROM stressor_responses WHERE 1=1"
      params <- list()

      if (!is.na(input$del_article_id)) {
        query <- paste0(query, " AND main_id = ?")
        params <- c(params, input$del_article_id)
      }

      if (nzchar(input$del_article_title)) {
        query <- paste0(query, " AND title LIKE ?")
        params <- c(params, paste0("%", input$del_article_title, "%"))
      }

      df <- dbGetQuery(db, query, params = params)
      if (nrow(df) == 0) {
        showNotification("No matching articles found.", type = "warning")
        updatePickerInput(session, "del_article_sel", choices = NULL)
      } else {
        choices <- setNames(df$main_id, paste0(df$main_id, ": ", df$title))
        updatePickerInput(session, "del_article_sel", choices = choices, selected = NULL)
      }
    })

    #
    # 4) —— DELETE ARTICLE —— 
    #
    observeEvent(input$del_article_btn, {
      req(input$del_article_sel)
      mid <- input$del_article_sel
      tryCatch({
        dbExecute(db,
                  "DELETE FROM stressor_responses WHERE main_id = ?",
                  params = list(mid)
        )
        showNotification(paste0("🗑 Article ", mid, " deleted"), type = "message")
        updatePickerInput(session, "del_article_sel", choices = NULL)
        if (!is.null(onUpdate)) onUpdate(runif(1))  # optional: signal refresh
      }, error = function(e) {
        showNotification(e$message, type = "error")
      })
    })

    observeEvent(input$main_navbar, {
      if (input$main_navbar == "manage_categories") {
        tbl <- input$del_cat_type
        if (!is.null(tbl)) {
          names <- dbGetQuery(db, sprintf("SELECT name FROM %s ORDER BY name", tbl))$name
          updatePickerInput(session, "del_cat_items", choices = names, selected = NULL)
        }
      }
    }, ignoreInit = TRUE)

  })

}
# nolint end 