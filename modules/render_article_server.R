# nolint start

library(DBI)
library(jsonlite)
library(ggplot2)
library(zoo)
library(plotly)
library(RPostgres)
library(pool)

render_article_server <- function(input, output, session, paper_id, db) {
  # Ensure database connection is provided
  if (missing(db)) {
    stop("Database connection (db) is missing!")
  }

  # Fetch article data from db
  paper <- dbGetQuery(db,
    "SELECT * FROM stressor_responses WHERE article_id = $1",
    params = list(paper_id)
  )

  # Check if article data exists
  if (nrow(paper) == 0) {
    return(NULL)
  }

  paper <- paper[1, ] # Ensure single-row data

  output$article_title <- renderText({
    # if you want a fallback when title is missing:
    if (is.na(paper$title) || paper$title == "") {
      "Untitled Article"
    } else {
      paper$title
    }
  })

  # vector of all section div IDs
  all_ids <- c(
    "metadata_section", "description_section", "citations_section",
    "csv_section", "plot_section", "interactive_plot_section"
  )

  # expand all

  # a named vector of base labels:
  base_labels <- c(
    toggle_metadata = "Article Metadata",
    toggle_description = "Description & Function Details",
    toggle_citations = "Citation(s)",
    toggle_csv = "Stressor Response Data",
    toggle_plot = "Stressor Response Chart",
    toggle_interactive_plot = "Interactive Plot"
  )

  observeEvent(input[[paste0("expand_all_", paper_id)]], {
    lapply(all_ids, show)
    for (id in names(base_labels)) {
      updateActionLink(
        session, id,
        label = paste0(base_labels[id], " ▲")
      )
    }
  })

  observeEvent(input[[paste0("collapse_all_", paper_id)]], {
    lapply(all_ids, hide)
    for (id in names(base_labels)) {
      updateActionLink(
        session, id,
        label = paste0(base_labels[id], " ▼")
      )
    }
  })

  # Function to safely parse JSONB fields
  parse_jsonb <- function(x) {
    # Bail on empty/null values
    if (is.null(x) || length(x) == 0 || is.na(x) || !nzchar(trimws(x)) || x == "[]") {
      return(NULL)
    }

    parsed <- tryCatch(jsonlite::fromJSON(x, simplifyDataFrame = FALSE), error = function(e) NULL)

    if (is.null(parsed) || length(parsed) == 0) {
      return(NULL)
    }

    # Ensure it's always a list of objects, never a data frame
    if (is.data.frame(parsed)) {
      parsed <- lapply(seq_len(nrow(parsed)), function(i) as.list(parsed[i, ]))
    }

    parsed
  }

  paper$citations <- parse_jsonb(paper$citations)

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

  # Render metadata fields
  output$species_name <- renderText(safe_get(paper, "species_common_name"))
  output$genus_latin <- renderText(safe_get(paper, "genus_latin"))
  output$stressor_name <- renderText(safe_get(paper, "stressor_name"))
  output$response <- renderText(safe_get(paper, "response"))
  output$specific_stressor_metric <- renderText(safe_get(paper, "specific_stressor_metric"))
  output$stressor_units <- renderText(safe_get(paper, "stressor_units"))
  output$life_stage <- renderText(safe_get(paper, "life_stages"))
  output$overview <- renderText(safe_get(paper, "overview"))
  output$function_derivation <- renderText(safe_get(paper, "function_derivation"))

  # Render citations
  output$citations <- renderUI({
    citations <- paper$citations # already parsed by parse_jsonb() above

    if (is.null(citations) || length(citations) == 0) {
      return(tags$p("No citations available."))
    }

    tagList(
      lapply(citations, function(cite) {
        text <- cite[["text"]]
        url <- cite[["url"]]
        title <- cite[["title"]]

        # Use title as button label if available, otherwise fall back to "Read More"
        link_label <- if (!is.null(title) && nzchar(trimws(title))) trimws(title) else "Read More"

        tags$div(
          class = "citation-entry",
          if (!is.null(text) && nzchar(trimws(text))) tags$p(trimws(text)),
          if (!is.null(url) && nzchar(trimws(url))) {
            tags$a(
              href = trimws(url),
              link_label,
              target = "_blank",
              class = "btn btn-primary btn-sm"
            )
          }
        )
      })
    )
  })

  # ===========================================================
  # FETCH CSV DATA FROM csv_data TABLE
  # ===========================================================
  csv_rows <- dbGetQuery(db,
    "SELECT
      row_index, curve_id, stressor_label, stressor_x, units_x,
      response_label, response_y, units_y, stressor_value,
      lower_limit, upper_limit, sd
    FROM csv_data
    WHERE article_id = $1
    ORDER BY row_index ASC",
    params = list(paper_id)
  )

  if (nrow(csv_rows) > 0) {
    df <- csv_rows

    # Normalize column names for the rest of the code (dots instead of underscores)
    # so the plotting/table logic below doesn't need to change
    names(df) <- gsub("_", ".", names(df))

    # Ensure numeric types (should already be correct from DB, but be safe)
    df$stressor.x <- suppressWarnings(as.numeric(df$stressor.x))
    df$response.y <- suppressWarnings(as.numeric(df$response.y))

    # Drop rows where X or Y are missing
    df <- df[!is.na(df$stressor.x) & !is.na(df$response.y), , drop = FALSE]
  } else {
    df <- data.frame(Message = "No CSV data available for this article")
  }

  # ===========================================================
  # EXTRACT METADATA FROM CSV
  # ===========================================================
  stressor_name <- safe_get(paper, "stressor_name")
  response_name <- "Mean System Capacity"

  # Initialize label variables
  stressor_label <- stressor_name
  response_label <- response_name
  units_x <- ""
  units_y <- ""

  # Extract labels from CSV if available
  if (nrow(df) > 0 && !"Message" %in% names(df) && !"Error" %in% names(df)) {
    nm_lower <- tolower(names(df))

    # stressor.label
    stressor_label_idx <- which(nm_lower == "stressor.label")
    if (length(stressor_label_idx) == 1) {
      unique_vals <- unique(df[[stressor_label_idx]])
      unique_vals <- unique_vals[!is.na(unique_vals) & nzchar(unique_vals)]
      if (length(unique_vals) > 0) {
        stressor_name <- unique_vals[1]
        stressor_label <- unique_vals[1]
      }
    }

    # response.label
    response_label_idx <- which(nm_lower == "response.label")
    if (length(response_label_idx) == 1) {
      unique_vals <- unique(df[[response_label_idx]])
      unique_vals <- unique_vals[!is.na(unique_vals) & nzchar(unique_vals)]
      if (length(unique_vals) > 0) {
        response_name <- unique_vals[1]
        response_label <- unique_vals[1]
      }
    }

    # units.x
    units_x_idx <- which(nm_lower == "units.x")
    if (length(units_x_idx) == 1) {
      unique_vals <- unique(df[[units_x_idx]])
      unique_vals <- unique_vals[!is.na(unique_vals) & nzchar(unique_vals)]
      if (length(unique_vals) > 0) {
        units_x <- unique_vals[1]
      }
    }

    # units.y
    units_y_idx <- which(nm_lower == "units.y")
    if (length(units_y_idx) == 1) {
      unique_vals <- unique(df[[units_y_idx]])
      unique_vals <- unique_vals[!is.na(unique_vals) & nzchar(unique_vals)]
      if (length(unique_vals) > 0) {
        units_y <- unique_vals[1]
      }
    }

    # Append units to labels
    if (nzchar(units_x)) {
      stressor_label <- paste0(stressor_label, " (", units_x, ")")
    }
    if (nzchar(units_y)) {
      response_label <- paste0(response_label, " (", units_y, ")")
    }
  }

  # ===========================================================
  # MULTI-CURVE DETECTION & CURVE INFO
  # ===========================================================
  has_multiple_curves <- FALSE
  curve_info <- NULL

  if (nrow(df) > 0 && !"Message" %in% names(df) && !"Error" %in% names(df)) {
    nm_lower <- tolower(names(df))
    curve_id_idx <- which(nm_lower == "curve.id")
    stressor_value_idx <- which(nm_lower == "stressor.value")

    if (length(curve_id_idx) == 1) {
      curve_ids <- df[[curve_id_idx]]
      unique_curve_ids <- unique(curve_ids[!is.na(curve_ids) & nzchar(curve_ids)])

      if (length(unique_curve_ids) > 1) {
        has_multiple_curves <- TRUE
      }

      # Get curves in order of first appearance
      curve_ids_in_order <- unique(curve_ids[!is.na(curve_ids) & nzchar(curve_ids)])
    } else {
      curve_ids_in_order <- "default"
    }

    # Build curve info dataframe
    curve_info <- data.frame(
      curve.id = curve_ids_in_order,
      stringsAsFactors = FALSE
    )

    if (length(stressor_value_idx) == 1) {
      # Get stressor.value for each curve
      curve_info$label <- vapply(curve_info$curve.id, function(cid) {
        curve_rows <- df[[curve_id_idx]] == cid
        stressor_val <- df[[stressor_value_idx]][curve_rows]
        stressor_val <- stressor_val[!is.na(stressor_val) & nzchar(stressor_val)]

        if (length(stressor_val) > 0) {
          paste0(cid, " (", stressor_val[1], ")")
        } else {
          as.character(cid)
        }
      }, character(1))
    } else {
      curve_info$label <- as.character(curve_info$curve.id)
    }
  }

  # ======================================
  # RENDER TABLE - Stressor Response Data
  # ======================================
  output$csv_table <- renderTable({
    if (nrow(df) == 0) {
      return(data.frame(Message = "No data available for this article"))
    }

    display_df <- df

    # Hide stressor.label, response.label, units.x, and units.y columns since their values are extracted for labeling
    # Hide row.index since it's just the original row number from the CSV and not meaningful to users
    # Step 1: Find columns to hide
    nm_lower <- tolower(names(display_df))
    cols_to_hide <- c(
      which(nm_lower == "row.index"),
      which(nm_lower == "stressor.label"),
      which(nm_lower == "response.label"),
      which(nm_lower == "units.x"),
      which(nm_lower == "units.y")
    )

    # Step 2: Actually remove those columns
    if (length(cols_to_hide) > 0) {
      display_df <- display_df[, -cols_to_hide, drop = FALSE]
    }

    # Step 3: Replace dots with spaces
    colnames(display_df) <- gsub("\\.", " ", colnames(display_df))

    # Step 4: Rename stressor.x → actual stressor label
    nm_lower_display <- tolower(names(display_df))
    stressor_x_idx <- which(nm_lower_display == "stressor x")
    if (length(stressor_x_idx) == 1) {
      colnames(display_df)[stressor_x_idx] <- stressor_label
    }

    # Step 5: Rename response.y → actual response label
    response_y_idx <- which(nm_lower_display == "response y")
    if (length(response_y_idx) == 1) {
      colnames(display_df)[response_y_idx] <- response_label
    }

    # Hide columns that are entirely NA or empty
    non_empty_cols <- sapply(display_df, function(col) any(!is.na(col) & nzchar(as.character(col))))
    display_df <- display_df[, non_empty_cols, drop = FALSE]

    display_df
  })

  # Static Plot with Multi-Curve Support
  output$stressor_plot <- renderPlot({
    if (nrow(df) == 0) {
      plot(1, type = "n", axes = FALSE, xlab = "", ylab = "")
      text(1, 1, "No data available for this article", col = "black", cex = 1.5, font = 2)
      return()
    }

    nm_lower <- tolower(names(df))
    x_idx <- grep("^stressor\\.x$", nm_lower)
    y_idx <- grep("^response\\.y$", nm_lower)

    if (length(x_idx) == 0 || length(y_idx) == 0) {
      plot(1, type = "n", axes = FALSE, xlab = "", ylab = "")
      text(1, 1, "Invalid data structure", col = "red", cex = 1.5, font = 2)
      return()
    }

    x_vals <- df[[x_idx]]
    y_vals <- df[[y_idx]]

    # Set up plot with appropriate range
    plot(
      range(x_vals, na.rm = TRUE), range(y_vals, na.rm = TRUE),
      type = "n",
      xlab = stressor_label,
      ylab = response_label,
      main = paste("Stressor Response for", response_name, "vs", stressor_name)
    )

    # Plot each curve
    if (has_multiple_curves && !is.null(curve_info)) {
      # Multiple curves - use different colors
      colors <- rainbow(nrow(curve_info))
      curve_id_idx <- which(nm_lower == "curve.id")

      for (i in seq_len(nrow(curve_info))) {
        cid <- curve_info$curve.id[i]
        curve_rows <- df[[curve_id_idx]] == cid

        # Extract x and y values for this curve
        x_curve <- df[[x_idx]][curve_rows]
        y_curve <- df[[y_idx]][curve_rows]

        # Sort this curve's data by x values before plotting
        # This ensures the line connects points in the correct order
        sort_order <- order(x_curve)
        x_curve <- x_curve[sort_order]
        y_curve <- y_curve[sort_order]

        lines(
          x_curve,
          y_curve,
          type = "o",
          col = colors[i],
          pch = 16,
          lwd = 2
        )
      }

      # Add legend
      legend(
        "topright",
        legend = curve_info$label,
        col = colors,
        lwd = 2,
        pch = 16,
        bty = "n"
      )
    } else {
      # Single curve - use blue
      lines(x_vals, y_vals, type = "o", col = "blue", pch = 16, lwd = 2)
    }
  })

  # Interactive Plot with Multi-Curve Support
  output$interactive_plot <- renderPlotly({
    if (nrow(df) == 0) {
      return(plot_ly(type = "scatter", mode = "markers", height = 200) %>%
        layout(
          margin = list(t = 20, b = 20),
          xaxis = list(visible = FALSE), yaxis = list(visible = FALSE),
          annotations = list(list(
            text = "No data available for this article",
            xref = "paper", yref = "paper",
            x = 0.5, y = 0.5, showarrow = FALSE,
            font = list(size = 16, color = "black")
          ))
        ))
    }

    nm_lower <- tolower(names(df))
    x_idx <- grep("^stressor\\.x$", nm_lower)
    y_idx <- grep("^response\\.y$", nm_lower)

    if (length(x_idx) == 0 || length(y_idx) == 0) {
      return(plot_ly(type = "scatter", mode = "markers", height = 200) %>%
        layout(
          margin = list(t = 20, b = 20),
          xaxis = list(visible = FALSE), yaxis = list(visible = FALSE),
          annotations = list(list(
            text = "Invalid data structure",
            xref = "paper", yref = "paper",
            x = 0.5, y = 0.5, showarrow = FALSE,
            font = list(size = 16, color = "red")
          ))
        ))
    }

    # Create plotly figure
    if (has_multiple_curves && !is.null(curve_info)) {
      # Multiple curves - add each as a separate trace
      p <- plot_ly()
      curve_id_idx <- which(nm_lower == "curve.id")

      for (i in seq_len(nrow(curve_info))) {
        cid <- curve_info$curve.id[i]
        curve_rows <- df[[curve_id_idx]] == cid

        # Extract data for this curve
        x_curve <- df[[x_idx]][curve_rows]
        y_curve <- df[[y_idx]][curve_rows]

        # Sort this curve's data by x values before plotting
        sort_order <- order(x_curve)
        x_curve <- x_curve[sort_order]
        y_curve <- y_curve[sort_order]

        p <- p %>% add_trace(
          x = x_curve,
          y = y_curve,
          type = "scatter",
          mode = "lines+markers",
          name = curve_info$label[i],
          marker = list(size = 6),
          line = list(width = 2)
        )
      }

      p <- p %>% layout(
        title = paste("Interactive Plot for", response_name, "vs", stressor_name),
        xaxis = list(title = stressor_label),
        yaxis = list(title = response_label),
        hovermode = "closest"
      )

      return(p)
    } else {
      # Single curve
      return(
        plot_ly(df,
          x = ~ df[[x_idx]], y = ~ df[[y_idx]],
          type = "scatter", mode = "lines+markers",
          line = list(color = "blue"), marker = list(size = 6)
        ) %>%
          layout(
            title = paste("Interactive Plot for", response_name, "vs", stressor_name),
            xaxis = list(title = stressor_label),
            yaxis = list(title = response_label)
          )
      )
    }
  })
}

# nolint end
