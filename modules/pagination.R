# nolint start
# modules/pagination.R

pagination_server <- function(input, output, session, filtered_data) {
  
  # ── 1. Pagination State ────────────────────────────────────────────────────
  current_page <- reactiveVal(1)

  # Reset to page 1 ANY TIME the user changes the filters or the page size
  observeEvent(filtered_data(), { current_page(1) })
  observeEvent(input$page_size, { current_page(1) })

  # Calculate total pages dynamically
  total_pages <- reactive({
    df <- filtered_data()
    size <- as.numeric(input$page_size)
    if (nrow(df) == 0 || is.na(size) || size <= 0) return(1)
    ceiling(nrow(df) / size)
  })

  # ── 2. Button Observers (Top and Bottom) ───────────────────────────────────
  navigate_prev <- function() {
    if (current_page() > 1) {
      current_page(current_page() - 1)
    }
  }

  navigate_next <- function() {
    if (current_page() < total_pages()) {
      current_page(current_page() + 1)
    }
  }

  # Listen to both sets of buttons
  observeEvent(input$prev_page_top, { navigate_prev() })
  observeEvent(input$prev_page_bottom, { navigate_prev() })
  
  observeEvent(input$next_page_top, { navigate_next() })
  observeEvent(input$next_page_bottom, { navigate_next() })

  # ── 3. UI State Management (Disable buttons at the ends) ───────────────────
  observe({
    can_prev <- current_page() > 1
    can_next <- current_page() < total_pages() && total_pages() > 0
    
    shinyjs::toggleState("prev_page_top", condition = can_prev)
    shinyjs::toggleState("prev_page_bottom", condition = can_prev)
    
    shinyjs::toggleState("next_page_top", condition = can_next)
    shinyjs::toggleState("next_page_bottom", condition = can_next)
  })

  # ── 4. The Paginated Data Slicer ───────────────────────────────────────────
  paginated_data <- reactive({
    df <- filtered_data()
    if (nrow(df) == 0) return(df)

    size <- as.numeric(input$page_size)
    start_idx <- (current_page() - 1) * size + 1
    end_idx <- min(start_idx + size - 1, nrow(df))

    df[start_idx:end_idx, , drop = FALSE]
  })

  # ── 5. Page Info Text ──────────────────────────────────────────────────────
  page_info <- reactive({
    df <- filtered_data()
    total <- nrow(df)
    if (total == 0) return("0 results")

    size <- as.numeric(input$page_size)
    start <- (current_page() - 1) * size + 1
    end <- min(start + size - 1, total)

    paste("Showing", start, "to", end, "of", total, "results")
  })

  # Return exactly what the main app expects
  return(list(
    paginated_data = paginated_data, 
    page_info = page_info
  ))
}
# nolint end
