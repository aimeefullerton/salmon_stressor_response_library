# nolint start

source("modules/csv_validation.R", local = TRUE)
source("modules/error_handling.R", local = TRUE)
source("modules/about_us.R", local = TRUE)
source("modules/acknowledgement.R", local = TRUE)
source("modules/filters.R", local = TRUE)
source("modules/pagination.R", local = TRUE)
source("modules/render_papers.R", local = TRUE)
source("modules/update_filters_server.R", local = TRUE)
source("modules/toggle_filters.R", local = TRUE)
source("modules/reset_filters.R", local = TRUE)
source("modules/render_article_ui.R", local = TRUE)
source("modules/render_article_server.R", local = TRUE)
source("modules/downloads.R", local = TRUE)
source("modules/upload.R", local = TRUE)
source("modules/eda.R", local = TRUE)
source("modules/submit_relationship.R", local = TRUE)

server <- function(input, output, session) {
  db <- pool

  # ── Initial data load ──────────────────────────────────────────────────────
  table_exists <- dbExistsTable(db, Id(schema = db_config$schema, table = "stressor_responses"))

  if (!table_exists) {
    warning("Table `stressor_responses` does not exist in the database.")
    data <- data.frame()
  } else {
    # UPDATED: Added LEFT JOIN to pull the user's name from the users table
    data <- dbGetQuery(db, "
      SELECT 
        sr.*, 
        u.name AS contributor_name 
      FROM stressor_responses sr
      LEFT JOIN users u ON sr.user_id = u.user_id 
      ORDER BY sr.article_id ASC
    ")

# Parse Postgres text[] columns into R character vectors AND collapse into strings
    pq_array_cols <- names(data)[sapply(data, inherits, "pq__text")]
    data[pq_array_cols] <- lapply(data[pq_array_cols], function(col) {
      sapply(col, function(x) {
        # Return true NA instead of "N/A"
        if (is.null(x) || is.na(x) || !nzchar(x)) return(NA_character_)
        x <- gsub("^\\{|\\}$", "", x)
        parts <- strsplit(x, ",(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)", perl = TRUE)[[1]]
        parts <- gsub('^"|"$', "", trimws(parts))
        valid_parts <- parts[parts != "NULL" & nzchar(parts)]
        # If the array was empty (e.g., {""}), return true NA
        if (length(valid_parts) == 0) return(NA_character_)
        # Collapse valid items
        return(paste(valid_parts, collapse = ", "))
      })
    })
}
  
  # ── Filtered & paginated data ──────────────────────────────────────────────
  filtered_data <- filter_data_server(input, data, session)
  pagination <- pagination_server(input, output, session, filtered_data)
  paginated_data <- pagination$paginated_data
  
  # Wire the text outputs to the new Top and Bottom UI elements
  output$page_info_top <- renderText(pagination$page_info())
  output$page_info_bottom <- renderText(pagination$page_info())

  # ── Modules ────────────────────────────────────────────────────────────────
  update_filters_server(input, output, session, data, db)
  toggle_filters_server(input, session)
  reset_filters_server(input, session)
  submit_relationship_server("submit_relationship")
  edaServer("eda")
  render_papers_server(output, paginated_data, input, session)
  setup_download_csv(output, filtered_data, paginated_data, db, input, session)
  
# ── Admin Upload Tab (Protected by Posit Connect) ────────────────────────
  admin_users <- c("aimee.fullerton", "paxton.calhoun", "morgan.bond") 

  observe({
    req(session$user) 
    
    # Check if the viewer is on the admin list
    if (session$user %in% admin_users) {
      
      insertTab(
        inputId = "main_navbar", 
        target = "submit_relationship", # Matches the 'value' of the tab in ui.R
        position = "after",
        tabPanel(
          title = "Admin Upload",
          value = "admin_upload_tab",
          icon = icon("lock"),
          upload_ui("secure_admin_upload") 
        )
      )
      
      upload_server("secure_admin_upload", db_conn = db, current_user = session$user)
    }
  })

  # ── Article modal ──────────────────────────────────────────────────────────
  # Track which articles have had render_article_server called to avoid
  # registering duplicate output renderers on repeated modal opens.
  initialized_articles <- character(0)

  observe({
    ids <- paginated_data()$article_id

    lapply(ids, function(mid) {
      mid_str <- as.character(mid)

      # ── Open modal ──────────────────────────────────────────────────────────
      observeEvent(input[[paste0("view_article_", mid)]],
        {
          paper_row <- paginated_data()[paginated_data()$article_id == mid, , drop = FALSE]

            showModal(modalDialog(
            title     = paste("Article", mid),
            withMathJax(render_article_ui(mid, paginated_data())),
            tags$script(HTML("if (window.MathJax) MathJax.Hub.Queue(['Typeset', MathJax.Hub]);")), # <--- Forces MathJax to re-scan!
            easyClose = TRUE,
            size      = "l"
          ))

          if (!mid_str %in% initialized_articles) {
            render_article_server(input, output, session, mid, paper_row, db)

            # ── Expand all ────────────────────────────────────────────────────
            observeEvent(input[[paste0("expand_all_", mid)]],
              {
                shinyjs::show(paste0("metadata_section_", mid))
                shinyjs::show(paste0("description_section_", mid))
                shinyjs::show(paste0("confidence_section_", mid))
                shinyjs::show(paste0("citations_section_", mid))
                shinyjs::show(paste0("csv_section_", mid))
                shinyjs::show(paste0("interactive_plot_section_", mid))
              },
              ignoreInit = TRUE
            )

            # ── Collapse all ──────────────────────────────────────────────────
            observeEvent(input[[paste0("collapse_all_", mid)]],
              {
                shinyjs::hide(paste0("metadata_section_", mid))
                shinyjs::hide(paste0("description_section_", mid))
                shinyjs::hide(paste0("confidence_section_", mid))
                shinyjs::hide(paste0("citations_section_", mid))
                shinyjs::hide(paste0("csv_section_", mid))
                shinyjs::hide(paste0("interactive_plot_section_", mid))
              },
              ignoreInit = TRUE
            )

            # ── Section toggles ───────────────────────────────────────────────
            for (section in c("metadata", "description", "confidence", "citations", "csv", "interactive_plot")) {
              local({
                s <- section
                m <- mid
                observeEvent(input[[paste0("toggle_", s, "_", m)]],
                  {
                    shinyjs::toggle(paste0(s, "_section_", m))
                  },
                  ignoreInit = TRUE
                )
              })
            }

            initialized_articles <<- c(initialized_articles, mid_str)
          }
        },
        ignoreInit = TRUE
      )
    })
  })
}

# nolint end
