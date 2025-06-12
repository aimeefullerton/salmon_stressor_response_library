# nolint start
library(shiny)
library(DBI)
library(RSQLite)

# Hardcoded path to database
db_path <- "data/stressor_responses.sqlite"

setup_download_csv <- function(output, paginated_data, db, input, session) {
  get_selected_rows <- function(df) {
    sapply(df$main_id, function(id) {
      inp <- paste0("select_article_", id)
      !is.null(input[[inp]]) && input[[inp]]
    })
  }
  
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
                   all = {
                     tryCatch({
                       conn <- dbConnect(SQLite(), db_path)
                       on.exit(dbDisconnect(conn), add = TRUE)
                       dbReadTable(conn, "stressor_responses")
                     }, error = function(e) {
                       showNotification("Failed to read from database.", type = "error")
                       return(data.frame())
                     })
                   },
                   filtered = paginated_data(),
                   selected = {
                     sel <- get_selected_rows(paginated_data())
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
