# nolint start
library(shiny)
library(DBI)
library(RPostgres)
library(pool)

# add access to db_config
source("global.R")

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
        "download"
      )
      paste0(prefix, "_", Sys.Date(), ".csv")
    },
    contentType = "text/csv",
    content = function(file) {
      df <- switch(input$download_option,
        all = {
          tryCatch(
            {
              # use pool db connection from global.R
              dbReadTable(pool, "stressor_responses")
            },
            error = function(e) {
              showNotification("Failed to read from database.", type = "error")
              return(data.frame())
            }
          )
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
