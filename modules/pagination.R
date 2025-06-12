# nolint start
# modules/pagination.R

pagination_server <- function(input, output, session, filtered_data) {
  current_page <- reactiveVal(1)
  page_size <- reactiveVal(5)
  items_shown <- reactiveVal(5)
  load_more_mode <- reactiveVal(TRUE)

  observeEvent(input$page_size, {
    size <- as.numeric(input$page_size)
    page_size(size)
    current_page(1)
    items_shown(size)
  })

  observeEvent(input$load_more_mode, {
    load_more_mode(TRUE)
    items_shown(items_shown() + as.numeric(input$page_size))
  })

  observeEvent(input$prev_page, {
    load_more_mode(FALSE)
    if (input$page > 1) {
      updateNumericInput(session, "page", value = input$page - 1)
      items_shown(as.numeric(input$page_size))
      session$sendCustomMessage("scrollToTop", list())
    }
  })

  observeEvent(input$next_page, {
    load_more_mode(FALSE)
    total_pages <- ceiling(nrow(filtered_data()) / as.numeric(input$page_size))
    if (input$page < total_pages) {
      updateNumericInput(session, "page", value = input$page + 1)
      items_shown(as.numeric(input$page_size))
      session$sendCustomMessage("scrollToTop", list())
    }
  })

  paginated_data <- reactive({
    df <- filtered_data()
    if (nrow(df) == 0) return(df)

    if (load_more_mode()) {
      df[1:min(nrow(df), items_shown()), , drop = FALSE]
    } else {
      page <- input$page
      size <- as.numeric(input$page_size)
      start_idx <- (page - 1) * size + 1
      end_idx <- min(start_idx + size - 1, nrow(df))
      df[start_idx:end_idx, , drop = FALSE]
    }
  })

  page_info <- reactive({
    df <- filtered_data()
    total <- nrow(df)
    if (total == 0) return("0 results")

    if (load_more_mode()) {
      shown <- items_shown()
      paste("Showing 1 to", min(shown, total), "of", total, "results")
    } else {
      size <- as.numeric(input$page_size)
      page <- input$page
      start <- (page - 1) * size + 1
      end <- min(start + size - 1, total)
      paste("Showing", start, "to", end, "of", total, "results")
    }
  })

  return(list(paginated_data = paginated_data, page_info = page_info))
}


# nolint end