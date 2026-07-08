# nolint start
library(shiny)
library(DBI)
library(jsonlite)
source("modules/csv_validation.R")
source("modules/error_handling.R")

# ── 1. The Edit Form UI ───────────────────────────────────────────────────────
edit_article_ui <- function(id, paper) {
  ns <- NS(id)
  
  # Helpers to safely extract data for pre-filling
  safe_val <- function(val) {
    if (is.null(val) || length(val) == 0 || is.na(val)) return("")
    if (is.list(val)) return(paste(unlist(val), collapse = ", "))
    return(as.character(val))
  }
  
  safe_array <- function(val) {
    if (is.null(val) || length(val) == 0 || is.na(val)) return(character(0))
    if (is.list(val)) return(unlist(val))
    # If it's a comma-separated string, split it
    parts <- trimws(strsplit(as.character(val), ",")[[1]])
    return(parts[parts != ""])
  }

  tagList(
    shinyjs::useShinyjs(),
    
    fluidRow(
      column(12, 
             h3(paste("Editing Article ID:", paper$article_id), style = "color: #d9534f; margin-bottom: 20px;"),
             p(em("Note: Leave the CSV upload blank unless you want to completely overwrite the existing data."))
      )
    ),
    
    # ── Core Metadata ──
    fluidRow(
      column(12, textInput(ns("title"), "Article Title *", value = safe_val(paper$title), width = "100%"))
    ),
    fluidRow(
      column(6, selectizeInput(ns("article_type"), "Article Type *", choices = safe_val(paper$article_type), selected = safe_val(paper$article_type), options = list(create = TRUE), width = "100%")),
      column(6, selectizeInput(ns("response"), "Response *", choices = safe_val(paper$response), selected = safe_val(paper$response), options = list(create = TRUE), width = "100%"))
    ),
    
    # ── CSV Replacement ──
    wellPanel(
      style = "background-color: #fff3f3; border-color: #d9534f; margin-bottom: 20px;",
      strong("Replace SR Curve Data CSV (Optional)", style = "color: #d9534f;"),
      p("Uploading a valid CSV here will permanently delete the old curve data for this article and replace it with the new file."),
      fileInput(ns("new_csv_file"), NULL, accept = ".csv", buttonLabel = "Upload Replacement CSV", width = "100%"),
      uiOutput(ns("csv_validation_status"))
    ),
    
    # ── Stressor Information ──
    fluidRow(
      column(4, selectizeInput(ns("stressor_name"), "Stressor Name *", choices = safe_val(paper$stressor_name), selected = safe_val(paper$stressor_name), options = list(create = TRUE), width = "100%")),
      column(4, selectizeInput(ns("broad_stressor_name"), "Broad Stressor Name *", choices = safe_val(paper$broad_stressor_name), selected = safe_val(paper$broad_stressor_name), options = list(create = TRUE), width = "100%")),
      column(4, selectizeInput(ns("specific_stressor_metric"), "Specific Stressor Metric *", choices = safe_val(paper$specific_stressor_metric), selected = safe_val(paper$specific_stressor_metric), options = list(create = TRUE), width = "100%"))
    ),
    
    # ── Species Info (Arrays) ──
    fluidRow(
      column(6, selectizeInput(ns("species_common_name"), "Species Common Name *", choices = safe_array(paper$species_common_name), selected = safe_array(paper$species_common_name), multiple = TRUE, options = list(create = TRUE), width = "100%")),
      column(6, selectizeInput(ns("latin_name"), "Latin Name *", choices = safe_array(paper$latin_name), selected = safe_array(paper$latin_name), multiple = TRUE, options = list(create = TRUE), width = "100%"))
    ),
    fluidRow(
      column(6, selectizeInput(ns("life_stages"), "Life Stages", choices = safe_array(paper$life_stages), selected = safe_array(paper$life_stages), multiple = TRUE, options = list(create = TRUE), width = "100%")),
      column(6, selectizeInput(ns("activity"), "Activity", choices = safe_array(paper$activity), selected = safe_array(paper$activity), multiple = TRUE, options = list(create = TRUE), width = "100%"))
    ),
    fluidRow(
      column(6, selectizeInput(ns("season"), "Season", choices = safe_array(paper$season), selected = safe_array(paper$season), multiple = TRUE, options = list(create = TRUE), width = "100%"))
    ),
    
    # ── Location Info (Arrays) ──
    fluidRow(
      column(6, selectizeInput(ns("location_country"), "Country *", choices = safe_array(paper$location_country), selected = safe_array(paper$location_country), multiple = TRUE, options = list(create = TRUE), width = "100%")),
      column(6, selectizeInput(ns("location_state_province"), "State / Province", choices = safe_array(paper$location_state_province), selected = safe_array(paper$location_state_province), multiple = TRUE, options = list(create = TRUE), width = "100%"))
    ),
    fluidRow(
      column(6, selectizeInput(ns("location_watershed_lab"), "Watershed / Lab", choices = safe_array(paper$location_watershed_lab), selected = safe_array(paper$location_watershed_lab), multiple = TRUE, options = list(create = TRUE), width = "100%")),
      column(6, selectizeInput(ns("location_river_creek"), "River / Creek", choices = safe_array(paper$location_river_creek), selected = safe_array(paper$location_river_creek), multiple = TRUE, options = list(create = TRUE), width = "100%"))
    ),
    
    # ── Descriptions & Formulas ──
    fluidRow(
      column(6, selectizeInput(ns("function_derivation"), "Function Derivation", choices = safe_array(paper$function_derivation), selected = safe_array(paper$function_derivation), multiple = TRUE, options = list(create = TRUE), width = "100%"))
    ),
    textAreaInput(ns("overview"), "Overview Description *", value = safe_val(paper$overview), height = "120px", width = "100%"),
    textAreaInput(ns("transferability_of_function"), "Transferability of Function", value = safe_val(paper$transferability_of_function), height = "80px", width = "100%"),
    textAreaInput(ns("srf_formula"), "SRF Formula (LaTeX)", value = safe_val(paper$srf_formula), height = "80px", width = "100%"),
    textAreaInput(ns("source_of_stressor_data"), "Source of Stressor Data", value = safe_val(paper$source_of_stressor_data), height = "80px", width = "100%"),
    
    # ── Confidence Rankings ──
    h4("Confidence Rankings", style = "margin-top: 20px; border-bottom: 1px solid #ddd; padding-bottom: 5px;"),
    fluidRow(
      column(6, textInput(ns("conf_source"), "Data Source", value = safe_val(paper$conf_source), width = "100%")),
      column(6, textInput(ns("conf_shape"), "Shape of SR Function", value = safe_val(paper$conf_shape), width = "100%"))
    ),
    fluidRow(
      column(6, textInput(ns("conf_variance"), "Data Variance/Consistency", value = safe_val(paper$conf_variance), width = "100%")),
      column(6, textInput(ns("conf_applicability"), "Applicability to System", value = safe_val(paper$conf_applicability), width = "100%"))
    ),
    fluidRow(
      column(6, textInput(ns("conf_interactions"), "Potential Stressor Interactions", value = safe_val(paper$conf_interactions), width = "100%"))
    ),
    
    # ── Dynamic Citations UI Container ──
    h4("Citations", style = "margin-top: 20px; border-bottom: 1px solid #ddd; padding-bottom: 5px;"),
    uiOutput(ns("citations_ui")),
    actionButton(ns("add_citation"), "Add Another Citation", icon = icon("plus"), class = "btn-sm", style = "margin-bottom: 30px;"),
    
    # ── Required Revision Log ──
    textAreaInput(ns("revision_log_msg"), "Revision Log Message *", placeholder = "Describe what you are changing and why...", height = "60px", width = "100%")
  )
}

# ── 2. The Edit Server ────────────────────────────────────────────────────────
edit_article_server <- function(id, paper, db_conn, parent_session) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # --- Parse existing citations and set up dynamic tracking ---
    parse_json_cits <- function(x) {
      if (is.null(x) || is.na(x) || x == "" || x == "[]") return(list())
      tryCatch({
        df <- jsonlite::fromJSON(x, simplifyDataFrame = FALSE)
        if (is.data.frame(df)) {
          lapply(seq_len(nrow(df)), function(i) as.list(df[i, ]))
        } else {
          df
        }
      }, error = function(e) list())
    }
    
    existing_cits <- parse_json_cits(paper$citations)
    if (length(existing_cits) == 0) {
      existing_cits <- list(list(text = "", title = "", url = ""))
    }
    
    # Reactive value to hold current citation state
    citations_data <- reactiveVal(existing_cits)
    
    # Render the citations UI dynamically
    output$citations_ui <- renderUI({
      cits <- citations_data()
      lapply(seq_along(cits), function(i) {
        div(
          style = "border: 1px solid #e3e3e3; padding: 15px; margin-bottom: 10px; border-radius: 5px; background-color: #fafafa;",
          textAreaInput(ns(paste0("cit_text_", i)), paste("Citation", i, "(Text)"), value = cits[[i]]$text, height = "70px", width = "100%"),
          fluidRow(
            column(6, textInput(ns(paste0("cit_title_", i)), "Link Title", value = cits[[i]]$title, width = "100%")),
            column(6, textInput(ns(paste0("cit_url_", i)), "URL", value = cits[[i]]$url, width = "100%"))
          )
        )
      })
    })
    
    # Add new citation block
    observeEvent(input$add_citation, {
      cits <- citations_data()
      # Before adding, save current typed values so they don't reset
      for(i in seq_along(cits)) {
        cits[[i]]$text <- input[[paste0("cit_text_", i)]]
        cits[[i]]$title <- input[[paste0("cit_title_", i)]]
        cits[[i]]$url <- input[[paste0("cit_url_", i)]]
      }
      cits[[length(cits) + 1]] <- list(text = "", title = "", url = "")
      citations_data(cits)
    })
    
    # --- CSV Replacement Logic ---
    observeEvent(input$new_csv_file, {
      req(input$new_csv_file)
      csv_res <- validate_csv_upload(input$new_csv_file)
      output$csv_validation_status <- renderUI({
        if (csv_res$valid) {
          HTML(create_alert_html("success", "Replacement CSV is valid and ready to submit", list(sprintf("Rows: %d", nrow(csv_res$data)))))
        } else {
          err <- get_csv_error_message(csv_res)
          HTML(create_alert_html("error", err$message, err$issues))
        }
      })
    })

    # --- Save Changes Logic ---
    observeEvent(parent_session$input[[paste0("save_edit_", paper$article_id)]], {
      req(input$title)
      
      if (trimws(input$revision_log_msg) == "") {
        showNotification("Please provide a Revision Log message explaining your edits.", type = "error")
        return()
      }
      
      # 1. Compile Citations
      final_cits <- list()
      for (i in seq_along(citations_data())) {
        c_text <- trimws(input[[paste0("cit_text_", i)]])
        c_title <- trimws(input[[paste0("cit_title_", i)]])
        c_url <- trimws(input[[paste0("cit_url_", i)]])
        
        if (length(c_text) > 0 && c_text != "") {
          final_cits[[length(final_cits) + 1]] <- list(
            text = c_text,
            title = if (length(c_title) > 0 && c_title != "") c_title else NA_character_,
            url = if (length(c_url) > 0 && c_url != "") c_url else NA_character_
          )
        }
      }
      citation_json <- if (length(final_cits) > 0) jsonlite::toJSON(final_cits, auto_unbox = TRUE, null = "null") else "[]"
      
      # 2. Compile Revision Log
      old_revs <- parse_json_cits(paper$revision_log)
      new_rev <- list(
        message = input$revision_log_msg,
        user = parent_session$user %||% "Admin",
        date = as.character(Sys.Date())
      )
      old_revs[[length(old_revs) + 1]] <- new_rev
      revision_json <- jsonlite::toJSON(old_revs, auto_unbox = TRUE)
      
      # Helpers for database updates
      get_conf <- function(val) if (is.null(val) || trimws(val) == "") NA_character_ else trimws(val)
      to_pg_array <- function(val) {
        if (is.null(val) || length(val) == 0) return(NA_character_)
        parts <- unlist(lapply(val, function(x) trimws(strsplit(x, ",")[[1]])))
        parts <- parts[parts != ""]
        if (length(parts) == 0) return(NA_character_)
        paste0("{", paste(sprintf('"%s"', gsub('"', '\\"', parts, fixed = TRUE)), collapse = ","), "}")
      }
      
      tryCatch({
        # 3. Update core metadata
        query <- "
          UPDATE stressor_responses SET
            article_type = $1, title = $2, stressor_name = $3, broad_stressor_name = $4,
            specific_stressor_metric = $5, response = $6, srf_formula = $7,
            species_common_name = $8, latin_name = $9, life_stages = $10, activity = $11, season = $12,
            location_country = $13, location_state_province = $14, location_watershed_lab = $15, location_river_creek = $16,
            overview = $17, function_derivation = $18, transferability_of_function = $19,
            conf_source = $20, conf_shape = $21, conf_variance = $22, conf_applicability = $23, conf_interactions = $24,
            source_of_stressor_data = $25, citations = $26::jsonb, revision_log = $27::jsonb
          WHERE article_id = $28
        "
        
        dbExecute(db_conn, query, params = list(
          input$article_type, input$title, input$stressor_name, input$broad_stressor_name,
          input$specific_stressor_metric, input$response, input$srf_formula,
          to_pg_array(input$species_common_name), to_pg_array(input$latin_name), to_pg_array(input$life_stages), 
          to_pg_array(input$activity), to_pg_array(input$season),
          to_pg_array(input$location_country), to_pg_array(input$location_state_province), 
          to_pg_array(input$location_watershed_lab), to_pg_array(input$location_river_creek),
          input$overview, to_pg_array(input$function_derivation), input$transferability_of_function,
          get_conf(input$conf_source), get_conf(input$conf_shape), get_conf(input$conf_variance), 
          get_conf(input$conf_applicability), get_conf(input$conf_interactions),
          input$source_of_stressor_data, citation_json, revision_json,
          paper$article_id
        ))
        
        # 4. Handle CSV Replacement if uploaded
        if (!is.null(input$new_csv_file)) {
          csv_res <- validate_csv_upload(input$new_csv_file)
          if (csv_res$valid) {
            # Delete old rows
            dbExecute(db_conn, "DELETE FROM csv_data WHERE article_id = $1", params = list(paper$article_id))
            
            # Insert new rows
            df_csv <- csv_res$data
            df_csv$article_id <- paper$article_id
            df_csv$row_index <- 1:nrow(df_csv)
            names(df_csv) <- gsub("\\.", "_", names(df_csv))
            dbAppendTable(db_conn, "csv_data", df_csv)
          } else {
            showNotification("Metadata saved, but new CSV was invalid and ignored.", type = "warning")
          }
        }
        
        removeModal()
        showNotification("✅ Article updated successfully! (Refresh the app to load new data)", type = "message", duration = 8)
        
      }, error = function(e) {
        showNotification(paste("❌ Error saving to database:", e$message), type = "error", duration = NULL)
      })
    })
  })
}
# nolint end
