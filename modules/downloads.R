# nolint start
library(shiny)
library(DBI)
library(RSQLite)

# Hardcoded path to database
db_path <- "data/stressor_responses.sqlite"

setup_download_csv <- function(output, paginated_data, db_path, input, session) {
  
  # Identify which rows are selected
  get_selected_rows <- reactive({
    df <- paginated_data()
    # Safely handle the case where the dataframe is empty
    if (nrow(df) == 0) {
      return(logical(0))
    }
    
    sapply(df$main_id, function(id) {
      inp <- paste0("select_article_", id)
      # Check if the input exists and is TRUE
      isTRUE(input[[inp]]) # was: !is.null(input[[inp]]) && input[[inp]]
    })
  })
  
  # Use observeEvent to trigger a change in the radio buttons when the selected rows change
  observeEvent(get_selected_rows(), {
    if (any(get_selected_rows())) {
      updateRadioButtons(session = session, inputId = "download_option", selected = "selected")
    } else {
      updateRadioButtons(session = session, inputId = "download_option", selected = "filtered")
    }
  })
  

  # Assign data to be downloaded
  output$download_csv <- downloadHandler(
    filename = function() {
      prefix <- switch(input$download_option,
                       all = "all_stressor_responses",
                       filtered = "filtered_stressor_responses",
                       selected = "selected_stressor_responses",
                       "download")
      paste0(prefix, "_", Sys.Date(), ".csv")
    },
    contentType = "text/csv",
    content = function(file) {
      df <- switch(input$download_option,
                   all = 
                     #{
                     # tryCatch({
                     #   conn <- dbConnect(SQLite(), db_path)
                     #   on.exit(dbDisconnect(conn), add = TRUE)
                     #   dbReadTable(conn, "stressor_responses")
                     # }, error = function(e) {
                     #   showNotification("Failed to read from database; returning cached copy.", type = "error")
                     #   return(data.frame())
                     # })
                     #}
                     data,
                   filtered = paginated_data(),
                   selected = {
                     sel <- get_selected_rows() # Call the reactive expression
                     paginated_data()[sel, , drop = FALSE]
                   },
                   data.frame()
      )
      
      if (nrow(df) == 0) {
        showNotification("No data available for download. Writing empty CSV.", type = "warning")
        write.csv(data.frame(), file, row.names = FALSE)
        return()
      }
      
      write.csv(df, file, row.names = FALSE)
    }
  )
}

# nolint end
