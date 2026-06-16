# nolint start

library(DBI)
library(jsonlite)
library(ggplot2)
library(zoo)
library(plotly)
library(RPostgres)
library(pool)

render_article_server <- function(input, output, session, paper_id, paper_row, db) {
  # ── Get article data from server.R ────────────────────────────────────────────

  if (missing(paper_row) || is.null(paper_row) || nrow(paper_row) == 0) {
    return(NULL)
  }

  paper <- paper_row

  # Collapse pre-parsed text[] list columns into display strings
  list_cols <- names(paper)[sapply(paper, is.list)]
  paper[list_cols] <- lapply(paper[list_cols], function(col) {
    vapply(col, function(x) {
      if (length(x) == 0 || all(is.na(x))) NA_character_
      else paste(x[!is.na(x)], collapse = ", ")
    }, character(1))
  })

  paper <- paper[1, , drop = FALSE]

  # ── Toggle button labels ───────────────────────────────────────────────────
  # Used by updateActionLink in server.R's expand/collapse handlers
  # to keep the ▲/▼ arrow in sync with section visibility.
  base_labels <- setNames(
    c(
      "Article Metadata",
      "Description & Function Details",
      "Confidence Rankings & Uncertainty",
      "Citation(s)",
      "Stressor Response Data",
      "Stressor Response Chart"
    ),
    c(
      paste0("toggle_metadata_", paper_id),
      paste0("toggle_description_", paper_id),
      paste0("toggle_confidence_", paper_id),
      paste0("toggle_citations_", paper_id),
      paste0("toggle_csv_", paper_id),
      paste0("toggle_interactive_plot_", paper_id)
    )
  )

  # Track visibility state for each section (all start hidden)
  section_visible <- setNames(
    lapply(names(base_labels), function(x) FALSE),
    names(base_labels)
  )

  # Helper: flip arrow label based on current visibility
  update_arrow <- function(toggle_id, visible) {
    arrow <- if (visible) " ▲" else " ▼"
    updateActionLink(session, toggle_id, label = paste0(base_labels[[toggle_id]], arrow))
  }

  # Expand all — show all sections and update all arrows to ▲
  observeEvent(input[[paste0("expand_all_", paper_id)]],
    {
      for (id in names(base_labels)) {
        section_visible[[id]] <<- TRUE
        update_arrow(id, TRUE)
      }
    },
    ignoreInit = TRUE
  )

  # Collapse all — hide all sections and update all arrows to ▼
  observeEvent(input[[paste0("collapse_all_", paper_id)]],
    {
      for (id in names(base_labels)) {
        section_visible[[id]] <<- FALSE
        update_arrow(id, FALSE)
      }
    },
    ignoreInit = TRUE
  )

  # Individual section toggles — flip state and update arrow
  # Note: shinyjs::toggle() is called in server.R; here we only sync the label
  for (toggle_id in names(base_labels)) {
    local({
      tid <- toggle_id # capture for closure
      observeEvent(input[[tid]],
        {
          section_visible[[tid]] <<- !section_visible[[tid]]
          update_arrow(tid, section_visible[[tid]])
        },
        ignoreInit = TRUE
      )
    })
  }

  # ── Helper functions ───────────────────────────────────────────────────────
  parse_jsonb <- function(x) {
    if (is.null(x) || length(x) == 0 || is.na(x) || !nzchar(trimws(x)) || x == "[]") {
      return(NULL)
    }
    parsed <- tryCatch(jsonlite::fromJSON(x, simplifyDataFrame = FALSE), error = function(e) NULL)
    if (is.null(parsed) || length(parsed) == 0) {
      return(NULL)
    }
    if (is.data.frame(parsed)) {
      parsed <- lapply(seq_len(nrow(parsed)), function(i) as.list(parsed[i, ]))
    }
    parsed
  }

  safe_get <- function(df, col) {
    if (col %in% names(df)) {
      return(ifelse(is.na(df[[col]]), "Not provided", df[[col]]))
    }
    return("Not provided")
  }

  smart_round <- function(col) {
    col <- suppressWarnings(as.numeric(col))
    if (all(col %% 1 == 0, na.rm = TRUE)) {
      return(as.integer(col))
    }
    return(round(col, 2))
  }

  # ── Parse citations ────────────────────────────────────────────────────────
  citations_data <- parse_jsonb(paper$citations)

  # ── Render metadata ────────────────────────────────────────────────────────
  output[[paste0("article_title_", paper_id)]] <- renderText({
    if (is.na(paper$title) || paper$title == "") "Untitled Article" else paper$title
  })
  output[[paste0("species_name_", paper_id)]] <- renderText(safe_get(paper, "species_common_name"))
  output[[paste0("latin_name_", paper_id)]] <- renderText(safe_get(paper, "latin_name"))
  output[[paste0("stressor_name_", paper_id)]] <- renderText(safe_get(paper, "stressor_name"))
  output[[paste0("specific_stressor_metric_", paper_id)]] <- renderText(safe_get(paper, "specific_stressor_metric"))
  output[[paste0("response_", paper_id)]] <- renderText(safe_get(paper, "response"))
  output[[paste0("life_stage_", paper_id)]] <- renderText(safe_get(paper, "life_stages"))
  output[[paste0("overview_", paper_id)]] <- renderText(safe_get(paper, "overview"))
  output[[paste0("function_derivation_", paper_id)]] <- renderText(safe_get(paper, "function_derivation"))
# ── Conditional: Location Country ──
  output[[paste0("location_country_ui_", paper_id)]] <- renderUI({
    val <- safe_get(paper, "location_country")
    if (is.null(val) || length(val) == 0 || is.na(val) || val == "" || val == "NA" || val == "N/A" || val == "Not provided") {
      return(NULL)
    }
    fluidRow(column(4, strong("Country:")), column(8, val))
  })
# ── Conditional: Location State/Province ──
  output[[paste0("location_state_province_ui_", paper_id)]] <- renderUI({
    val <- safe_get(paper, "location_state_province")
    if (is.null(val) || length(val) == 0 || is.na(val) || val == "" || val == "NA" || val == "N/A" || val == "Not provided") {
      return(NULL)
    }
    fluidRow(column(4, strong("State/Province:")), column(8, val))
  })
# ── Conditional: Location Watershed/Lab ──
  output[[paste0("location_watershed_lab_ui_", paper_id)]] <- renderUI({
    val <- safe_get(paper, "location_watershed_lab")
    if (is.null(val) || length(val) == 0 || is.na(val) || val == "" || val == "NA" || val == "N/A" || val == "Not provided") {
      return(NULL)
    }
    fluidRow(column(4, strong("Watershed/Lab:")), column(8, val))
  })
# ── Conditional: Location River/Creek ──
  output[[paste0("location_river_creek_ui_", paper_id)]] <- renderUI({
    val <- safe_get(paper, "location_river_creek")
    if (is.null(val) || length(val) == 0 || is.na(val) || val == "" || val == "NA" || val == "N/A" || val == "Not provided") {
      return(NULL)
    }
    fluidRow(column(4, strong("River/Creek:")), column(8, val))
  })
# ── Conditional: Transferability of Function ──
  output[[paste0("transferability_ui_", paper_id)]] <- renderUI({
    val <- safe_get(paper, "transferability_of_function")
    # Check if null, NA, or empty
    if (is.null(val) || length(val) == 0 || is.na(val) || val == "" || val == "NA" || val == "N/A") {
      return(NULL) 
    }
    tagList(
      br(), br(),
      strong("Transferability of Function"), br(), 
      div(val)
    )
  })
# ── Conditional: Source of Stressor Data ──
  output[[paste0("source_of_stressor_data_ui_", paper_id)]] <- renderUI({
    val <- safe_get(paper, "source_of_stressor_data")
    
    # Check if null, NA, empty, or caught by safe_get's fallback
    if (is.null(val) || length(val) == 0 || is.na(val) || val == "" || val == "NA" || val == "N/A" || val == "Not provided") {
      return(NULL) 
    }
    
    tagList(
      br(), br(),
      strong("Source of Stressor Data"), br(), 
      div(val)
    )
  })

  # ── Conditional: SRF Formula ──
  output[[paste0("srf_formula_ui_", paper_id)]] <- renderUI({
    val <- safe_get(paper, "srf_formula")
    # Check if null, NA, or empty
    if (is.null(val) || length(val) == 0 || is.na(val) || val == "" || val == "NA" || val == "N/A") {
      return(NULL) 
    }
    tagList(
      br(), br(),
      strong("SRF Formula"), br(), 
      withMathJax(div(val))
    )
  })
  # ── Render confidence rankings ────────────────────────────────────────────────
  output[[paste0("confidence_table_", paper_id)]] <- renderTable({
    conf_cols <- c(
      "Source"       = "conf_source",
      "Shape"        = "conf_shape",
      "Variance"     = "conf_variance",
      "Applicability"= "conf_applicability",
      "Interactions" = "conf_interactions"
    )

    # All fields are optional — show "Not provided" for any that are missing or NA
    vals <- sapply(conf_cols, function(col) {
      if (!col %in% names(paper)) return("Not provided")
      v <- paper[[col]]
      if (is.null(v) || is.na(v) || !nzchar(trimws(v))) "Not provided" else trimws(v)
    })

    data.frame(
      Category = names(conf_cols),
      Rating   = unname(vals),
      stringsAsFactors = FALSE
    )
  }, striped = TRUE, hover = TRUE, bordered = TRUE)

  # ── Render citations ───────────────────────────────────────────────────────
  output[[paste0("citations_", paper_id)]] <- renderUI({
    citations <- citations_data

    if (is.null(citations) || length(citations) == 0) {
      return(tags$p("No citations available."))
    }

    tagList(
      lapply(citations, function(cite) {
        text <- cite[["text"]]
        url <- cite[["url"]]
        title <- cite[["title"]]

        link_label <- if (!is.null(title) && nzchar(trimws(title))) trimws(title) else "Read More"

        tags$div(
          class = "citation-entry",
          if (!is.null(text) && nzchar(trimws(text))) tags$p(trimws(text)),
          if (!is.null(url) && nzchar(trimws(url))) {
            tags$a(
              href   = trimws(url),
              link_label,
              target = "_blank",
              class  = "btn btn-primary btn-sm"
            )
          }
        )
      })
    )
  })

  # ── Fetch CSV data from csv_data table ─────────────────────────────────────
  # UPDATED: Added plot_type to the SELECT statement
  csv_rows <- dbGetQuery(db,
    "SELECT
       row_index, curve_id, stressor_label, stressor_x, units_x,
       response_label, response_y, units_y, stressor_value,
       lower_limit, upper_limit, sd, plot_type
     FROM csv_data
     WHERE article_id = $1
     ORDER BY row_index ASC",
    params = list(paper_id)
  )

  if (nrow(csv_rows) > 0) {
    df <- csv_rows
    # Normalize to dot-separated names so plotting/table logic is consistent
    names(df) <- gsub("_", ".", names(df))
    df$stressor.x <- suppressWarnings(as.numeric(df$stressor.x))
    df$response.y <- suppressWarnings(as.numeric(df$response.y))
    df <- df[!is.na(df$stressor.x) & !is.na(df$response.y), , drop = FALSE]
  } else {
    df <- data.frame(Message = "No CSV data available for this article")
  }

  # ── Extract axis labels and units from CSV ─────────────────────────────────
  stressor_name <- safe_get(paper, "stressor_name")
  response_name <- "Mean System Capacity"
  stressor_label <- stressor_name
  response_label <- response_name
  units_x <- ""
  units_y <- ""

  if (nrow(df) > 0 && !"Message" %in% names(df)) {
    nm_lower <- tolower(names(df))

    extract_first <- function(col_name) {
      idx <- which(nm_lower == col_name)
      if (length(idx) != 1) {
        return(NULL)
      }
      vals <- unique(df[[idx]])
      vals <- vals[!is.na(vals) & nzchar(vals)]
      if (length(vals) > 0) {
        return(vals[1])
      } else {
        return(NULL)
      }
    }

    if (!is.null(val <- extract_first("stressor.label"))) {
      stressor_name <- val
      stressor_label <- val
    }
    if (!is.null(val <- extract_first("response.label"))) {
      response_name <- val
      response_label <- val
    }
    if (!is.null(val <- extract_first("units.x"))) units_x <- val
    if (!is.null(val <- extract_first("units.y"))) units_y <- val

    if (nzchar(units_x)) stressor_label <- paste0(stressor_label, " (", units_x, ")")
    if (nzchar(units_y)) response_label <- paste0(response_label, " (", units_y, ")")
  }

  # ── Multi-curve detection ──────────────────────────────────────────────────
  has_multiple_curves <- FALSE
  curve_info <- NULL

  if (nrow(df) > 0 && !"Message" %in% names(df)) {
    nm_lower <- tolower(names(df))
    curve_id_idx <- which(nm_lower == "curve.id")
    stressor_value_idx <- which(nm_lower == "stressor.value")

    curve_ids_in_order <- if (length(curve_id_idx) == 1) {
      ids <- df[[curve_id_idx]]
      unique(ids[!is.na(ids) & nzchar(ids)])
    } else {
      "default"
    }

    has_multiple_curves <- length(curve_ids_in_order) > 1

    curve_info <- data.frame(curve.id = curve_ids_in_order, stringsAsFactors = FALSE)

    curve_info$label <- if (length(stressor_value_idx) == 1) {
      vapply(curve_info$curve.id, function(cid) {
        rows <- df[[curve_id_idx]] == cid
        vals <- df[[stressor_value_idx]][rows]
        vals <- vals[!is.na(vals) & nzchar(vals)]
        if (length(vals) > 0) paste0(cid, " (", vals[1], ")") else as.character(cid)
      }, character(1))
    } else {
      as.character(curve_info$curve.id)
    }
  }

  # ── Render table ───────────────────────────────────────────────────────────
  output[[paste0("csv_table_", paper_id)]] <- renderTable({
    if (nrow(df) == 0 || "Message" %in% names(df)) {
      return(data.frame(Message = "No data available for this article"))
    }

    display_df <- df
    nm_lower <- tolower(names(display_df))

    cols_to_hide <- c(
      which(nm_lower == "row.index"),
      which(nm_lower == "stressor.label"),
      which(nm_lower == "response.label"),
      which(nm_lower == "units.x"),
      which(nm_lower == "units.y")
    )
    if (length(cols_to_hide) > 0) display_df <- display_df[, -cols_to_hide, drop = FALSE]

    colnames(display_df) <- gsub("\\.", " ", colnames(display_df))
    nm_display <- tolower(names(display_df))

    x_idx <- which(nm_display == "stressor x")
    y_idx <- which(nm_display == "response y")
    if (length(x_idx) == 1) colnames(display_df)[x_idx] <- stressor_label
    if (length(y_idx) == 1) colnames(display_df)[y_idx] <- response_label

    non_empty <- sapply(display_df, function(col) any(!is.na(col) & nzchar(as.character(col))))
    display_df[, non_empty, drop = FALSE]
  }, striped = TRUE, hover = TRUE, bordered = TRUE)

# ── Interactive plot ───────────────────────────────────────────────────────
  output[[paste0("interactive_plot_", paper_id)]] <- renderPlotly({
    empty_plot <- function(msg, color = "black") {
      plot_ly(type = "scatter", mode = "markers", height = 200) %>%
        layout(
          margin = list(t = 20, b = 20),
          xaxis = list(visible = FALSE),
          yaxis = list(visible = FALSE),
          annotations = list(list(
            text = msg, xref = "paper", yref = "paper",
            x = 0.5, y = 0.5, showarrow = FALSE,
            font = list(size = 16, color = color)
          ))
        )
    }

    if (nrow(df) == 0 || "Message" %in% names(df)) {
      return(empty_plot("No data available for this article"))
    }

    nm_lower <- tolower(names(df))
    x_idx <- grep("^stressor\\.x$", nm_lower)
    y_idx <- grep("^response\\.y$", nm_lower)
    if (length(x_idx) == 0 || length(y_idx) == 0) {
      return(empty_plot("Invalid data structure", "red"))
    }

    # Always sort the entire dataframe by X right away to prevent spaghetti lines
    df <- df[order(df[[x_idx]]), ]

    # HELPER FUNCTION: Returns 'type' and 'mode' based on explicit metadata or fallback
    get_plot_settings <- function(data_subset, x_values) {
      plot_idx <- grep("^plot[._]type$", nm_lower)

      if (length(plot_idx) > 0) {
        ptype_vals <- na.omit(data_subset[[plot_idx[1]]])
        if (length(ptype_vals) > 0) {
          ptype <- tolower(trimws(as.character(ptype_vals[1])))
          if (ptype == "scatter") return(list(type = "scatter", mode = "markers"))
          if (ptype == "curve") return(list(type = "scatter", mode = "lines+markers"))
          if (ptype == "bar") return(list(type = "bar", mode = NULL))
        }
      }
      
      is_scatter <- length(x_values) != length(unique(x_values))
      if (is_scatter) return(list(type = "scatter", mode = "markers"))
      return(list(type = "scatter", mode = "lines+markers"))
    }

    # HELPER FUNCTION: Generates asymmetric error_y lists if limit columns are present
    build_error_bars <- function(sub_df, y_vals) {
      # Safely find columns mapping to lower/upper bounds
      low_col <- grep("^lower\\.limit$", colnames(sub_df), ignore.case = TRUE)
      upp_col <- grep("^upper\\.limit$", colnames(sub_df), ignore.case = TRUE)
      
      if (length(low_col) == 1 && length(upp_col) == 1) {
        low_vals <- suppressWarnings(as.numeric(sub_df[[low_col]]))
        upp_vals <- suppressWarnings(as.numeric(sub_df[[upp_col]]))
        
        # Check if we have non-NA values to render
        if (any(!is.na(low_vals)) && any(!is.na(upp_vals))) {
          return(list(
            type = "data",
            symmetric = FALSE,
            array = upp_vals - y_vals,
            arrayminus = y_vals - low_vals,
            visible = TRUE,
            color = "rgba(100,100,100,0.5)",
            thickness = 1.5
          ))
        }
      }
      return(NULL) # No error metrics available
    }

    if (has_multiple_curves && !is.null(curve_info)) {
      curve_id_idx <- which(nm_lower == "curve.id")
      p <- plot_ly()

      for (i in seq_len(nrow(curve_info))) {
        cid <- curve_info$curve.id[i]
        curve_rows <- df[[curve_id_idx]] == cid
        
        subset_df <- df[curve_rows, ]
        x_curve <- subset_df[[x_idx]]
        y_curve <- subset_df[[y_idx]]

        settings <- get_plot_settings(subset_df, x_curve)
        err_settings <- build_error_bars(subset_df, y_curve)

        if (settings$type == "bar") {
          p <- p %>% add_trace(
            x = x_curve, y = y_curve,
            type = "bar",
            name = curve_info$label[i],
            error_y = err_settings
          )
        } else {
          p <- p %>% add_trace(
            x = x_curve, y = y_curve,
            type = "scatter",
            mode = settings$mode, 
            name = curve_info$label[i],
            marker = list(size = 6),
            line = if(settings$mode == "lines+markers") list(width = 2) else NULL,
            error_y = err_settings
          )
        }
      }

      p <- p %>% layout(
        title = paste("Interactive Plot for", response_name, "vs", stressor_name),
        xaxis = list(title = stressor_label),
        yaxis = list(title = response_label),
        hovermode = "closest",
        barmode = "group"
      )
    } else {
      x_vals <- df[[x_idx]]
      y_vals <- df[[y_idx]]
      
      settings <- get_plot_settings(df, x_vals)
      err_settings <- build_error_bars(df, y_vals)

      if (settings$type == "bar") {
        plot_ly(
          x = x_vals, y = y_vals,
          type = "bar",
          error_y = err_settings
        ) %>%
          layout(
            title = paste("Interactive Plot for", response_name, "vs", stressor_name),
            xaxis = list(title = stressor_label),
            yaxis = list(title = response_label)
          )
      } else {
        plot_ly(
          x = x_vals, y = y_vals,
          type = "scatter", mode = settings$mode,
          line = if(settings$mode == "lines+markers") list(color = "blue", width = 2) else NULL, 
          marker = list(size = 6),
          error_y = err_settings
        ) %>%
          layout(
            title = paste("Interactive Plot for", response_name, "vs", stressor_name),
            xaxis = list(title = stressor_label),
            yaxis = list(title = response_label)
          )
      }
    }
  })
}

# nolint end
