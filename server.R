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
source("modules/overlay_plot.R", local = TRUE)
source("modules/edit_article.R", local = TRUE)

server <- function(input, output, session) {
  db <- pool

# Hide the filter panel on load so pickerInputs have time to initialize
  shinyjs::hide("filter_panel")

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

  # ── Multi-Select State Tracking ────────────────────────────────────────────
  selected_articles <- reactiveVal(character(0))
  
  # Listen to all checkboxes dynamically as they are rendered
  observe({
    req(paginated_data())
    current_ids <- paginated_data()$article_id
    
    lapply(current_ids, function(id) {
      observeEvent(input[[paste0("select_article_", id)]], {
        current_selection <- selected_articles()
        if (input[[paste0("select_article_", id)]]) {
          # Add ID to list if checked
          selected_articles(unique(c(current_selection, as.character(id))))
        } else {
          # Remove ID from list if unchecked
          selected_articles(setdiff(current_selection, as.character(id)))
        }
      }, ignoreInit = TRUE)
    })
  })
  
# Render the Action Bar permanently (always visible)
  output$selection_action_bar <- renderUI({
    num_selected <- length(selected_articles())
    
    div(
      style = "background-color: #f8f9fa; padding: 15px; border-radius: 8px; margin-bottom: 20px; border: 1px solid #ced4da; display: flex; align-items: center; justify-content: space-between; box-shadow: 0 2px 4px rgba(0,0,0,0.05);",
      
      div(
        style = "font-size: 1.1em; color: #2c3e50;",
        icon("check-square", style = "color: if(num_selected > 0) '#28a745' else '#888'; margin-right: 8px;"),
        strong(sprintf("%d Profiles Selected", num_selected))
      ),
      
      div(
        # The button is visible, but grayed out/disabled if 0 items are selected
        actionButton(
          "btn_overlay_plots", 
          "Overlay Plots", 
          class = "btn-primary", 
          icon = icon("chart-line"), 
          style = "margin-left: 10px; background-color: #2c6e49; border-color: #2c6e49;",
          disabled = if (num_selected == 0) "disabled" else NULL
        ),
        actionButton(
          "btn_clear_selection", 
          "Clear All", 
          class = "btn-default", 
          style = "margin-left: 10px;",
          disabled = if (num_selected == 0) "disabled" else NULL
        )
      )
    )
  })

# ── Clear All Button Logic ────────────────────────────────────────────────
  observeEvent(input$btn_clear_selection, {
    
    # 1. Wipe the server's memory of selected profiles
    selected_articles(character(0))
    
    # 2. Visually uncheck the boxes currently rendered on the active page
    current_visible_ids <- paginated_data()$article_id
    for (id in current_visible_ids) {
      updateCheckboxInput(session, paste0("select_article_", id), value = FALSE)
    }
    
    # 3. Uncheck the master "Select All" box if it is checked
    updateCheckboxInput(session, "select_all", value = FALSE)
    
  }, ignoreInit = TRUE)

# ── Trigger the Overlay Modal ──────────────────────────────────────────────
  observeEvent(input$btn_overlay_plots, {
    showModal(modalDialog(
      title = "Compare Stressor-Response Profiles",
      size = "xl", 
      easyClose = TRUE,
      footer = modalButton("Close"),
      
      # INJECTED CSS: Forces the modal to bypass Bootstrap limits and take up 95% of the screen width
      tags$style(HTML("
        .modal-xl {
          width: 95vw !important;
          max-width: 95vw !important;
        }
      ")),
      
      # Call the UI from the module
      overlay_plot_ui("overlay_module")
    ))
  })
  
  # Initialize the module server, passing it the reactive IDs, database, and all metadata
  overlay_plot_server(
    id = "overlay_module", 
    selected_ids_reactive = selected_articles, 
    db_conn = db, 
    full_metadata_reactive = filtered_data # Pass filtered_data so we have the metadata for the cards
  )
  
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

          # DYNAMIC FOOTER: Check if current user is an admin to show the Edit button
          modal_footer <- tags$div(
            style = "display: flex; justify-content: space-between; width: 100%; align-items: center;",
            tags$div(
              if (!is.null(session$user) && session$user %in% admin_users) {
                actionButton(
                  paste0("edit_article_", mid), 
                  "✏️ Edit Profile", 
                  class = "btn-warning", 
                  style = "background-color: #f0ad4e; border-color: #eea236; color: white;"
                )
              } else {
                NULL
              }
            ),
            modalButton("Close")
          )

          showModal(modalDialog(
            title     = paste("Article", mid),
            withMathJax(render_article_ui(mid, paginated_data())),
            tags$script(HTML("if (window.MathJax) MathJax.Hub.Queue(['Typeset', MathJax.Hub]);")),
            easyClose = TRUE,
            size      = "l",
            footer    = modal_footer # <--- WIRED DYNAMIC FOOTER HERE
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
            
            # ── Edit Profile Modal Trigger ────────────────────────────────────
            observeEvent(input[[paste0("edit_article_", mid)]], {
              # Fetch the most up-to-date data for this row
              paper_to_edit <- data[data$article_id == mid, , drop = FALSE]
              
              showModal(modalDialog(
                title = paste("Editing Article", mid, "-", paper_to_edit$title),
                size = "xl",
                easyClose = FALSE,
                
                # Load the pre-filled UI
                edit_article_ui(paste0("edit_module_", mid), paper_to_edit),
                
                footer = tagList(
                  modalButton("Cancel"),
                  actionButton(
                    paste0("save_edit_", mid), 
                    "💾 Save Changes", 
                    class = "btn-success"
                  )
                )
              ))
              
              # Initialize the server logic for the edit form
              edit_article_server(paste0("edit_module_", mid), paper_to_edit, db, session)
            }, ignoreInit = TRUE)

            initialized_articles <<- c(initialized_articles, mid_str)
          }
        },
        ignoreInit = TRUE
      )
    })
  })
}

# nolint end
