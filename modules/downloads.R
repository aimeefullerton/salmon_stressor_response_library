# nolint start
library(shiny)
library(DBI)
library(RPostgres)
library(pool)

setup_download_csv <- function(output, paginated_data, db_path, input, session) {

  # Flatten list columns (text[]) into comma-separated strings for CSV export
  flatten_for_export <- function(df) {
    list_cols <- names(df)[sapply(df, is.list)]
    df[list_cols] <- lapply(df[list_cols], function(col) {
      vapply(col, function(x) {
        if (length(x) == 0 || all(is.na(x))) NA_character_
        else paste(x[!is.na(x)], collapse = ", ")
      }, character(1))
    })
    df
  }

  # Identify which rows are selected
  get_selected_rows <- reactive({
    df <- paginated_data()
    if (nrow(df) == 0) return(logical(0))
    sapply(df$article_id, function(id) {
      isTRUE(input[[paste0("select_article_", id)]])
    })
  })

  observeEvent(get_selected_rows(), {
    if (any(get_selected_rows())) {
      updateRadioButtons(session = session, inputId = "download_option", selected = "selected")
    } else {
      updateRadioButtons(session = session, inputId = "download_option", selected = "filtered")
    }
  })

  output$download_csv <- downloadHandler(
    filename = function() {
      prefix <- switch(input$download_option,
        all      = "all_stressor_responses",
        filtered = "filtered_stressor_responses",
        selected = "selected_stressor_responses",
        "download"
      )
      paste0(prefix, "_", Sys.Date(), ".csv")
    },
    contentType = "text/csv",
    content = function(file) {
      df <- switch(input$download_option,
        all = tryCatch(
          dbReadTable(pool, "stressor_responses"),
          error = function(e) {
            showNotification("Failed to read from database.", type = "error")
            data.frame()
          }
        ),
        filtered = paginated_data(),
        selected = {
          sel <- get_selected_rows()
          paginated_data()[sel, , drop = FALSE]
        },
        data.frame()
      )

      if (nrow(df) == 0) {
        showNotification("No data available for download. Writing empty CSV.", type = "warning")
        write.csv(data.frame(), file, row.names = FALSE)
        return()
      }

      write.csv(flatten_for_export(df), file, row.names = FALSE)
    }
  )
}

# nolint end
