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

  observeEvent(input$expand_all, {
    lapply(all_ids, show)
    for (id in names(base_labels)) {
      updateActionLink(
        session, id,
        label = paste0(base_labels[id], " ▲")
      )
    }
  })

  observeEvent(input$collapse_all, {
    lapply(all_ids, hide)
    for (id in names(base_labels)) {
      updateActionLink(
        session, id,
        label = paste0(base_labels[id], " ▼")
      )
    }
  })

  # Function to safely parse JSON fields
  safe_fromJSON <- function(x) {
    # bail early on NULL, NA, empty, or literal "NULL"/"[]"
    if (is.null(x) ||
      (length(x) == 1 && is.na(x)) ||
      !nzchar(x) ||
      x %in% c("NULL", "[]")) {
      return(NULL)
    }
    # else try to parse
    parsed <- tryCatch(jsonlite::fromJSON(x), error = function(e) NULL)

    # Handle double-encoded JSON where the DB stored a JSON string literal
    # (e.g., '"[{...}]"') — jsonlite::fromJSON will return an atomic
    # character scalar containing the JSON; detect that and parse again.
    if (!is.null(parsed) && is.character(parsed) && length(parsed) == 1) {
      trimmed <- trimws(parsed)
      if (nzchar(trimmed) && (startsWith(trimmed, "[") || startsWith(trimmed, "{"))) {
        parsed2 <- tryCatch(jsonlite::fromJSON(trimmed), error = function(e) NULL)
        if (!is.null(parsed2)) parsed <- parsed2
      }
    }

    # if it ends up being atomic, wrap as list
    if (!is.null(parsed) && !is.list(parsed)) {
      parsed <- list(parsed)
    }

    parsed
  }

  paper$citations <- safe_fromJSON(paper$citations_citation_text)
  paper$citation_links <- safe_fromJSON(paper$citations_citation_links)

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
  output$specific_stressor_metric <- renderText(safe_get(paper, "specific_stressor_metric"))
  output$stressor_units <- renderText(safe_get(paper, "stressor_units"))
  output$life_stage <- renderText(safe_get(paper, "life_stages"))
  output$description_overview <- renderText(safe_get(paper, "description_overview"))
  output$function_derivation <- renderText(safe_get(paper, "description_function_derivation"))

  # Render citations
  output$citations <- renderUI({
    citation_texts <- safe_get(paper, "citations_citation_text")
    if (!is.null(citation_texts) && is.character(citation_texts) && nzchar(citation_texts)) {
      citation_texts <- unlist(strsplit(citation_texts, "\\\r\\\n\\\r\\\n"))
    } else {
      citation_texts <- NULL
    }
    citation_links_raw <- safe_get(paper, "citations_citation_links")
    citation_links <- safe_fromJSON(citation_links_raw)
    if (!is.list(citation_links) || length(citation_links) == 0) {
      citation_links <- vector("list", length(citation_texts))
    }
    tagList(
      if (!is.null(citation_texts) && length(citation_texts) > 0) {
        lapply(seq_along(citation_texts), function(i) {
          citation_text <- citation_texts[i]
          link <- if (i <= length(citation_links) && is.list(citation_links[[i]]) && "url" %in% names(citation_links[[i]])) {
            citation_links[[i]]$url
          } else {
            NULL
          }
          tags$div(
            tags$p(citation_text),
            if (!is.null(link) && nzchar(link)) {
              tags$a(href = link, "Read More", target = "_blank", class = "btn btn-primary btn-sm")
            }
          )
        })
      } else {
        tags$p("No citations available.")
      }
    )
  })

  # ===========================================================
  # PARSE CSV DATA
  # ===========================================================
  csv_data_raw <- safe_fromJSON(paper$csv_data_json)

  if (!is.null(csv_data_raw)) {
    # Check if this is the NEW format with column metadata
    # Must be a list, have both 'columns' and 'data' fields, and 'data' should not be NULL
    if (is.list(csv_data_raw) &&
      !is.null(csv_data_raw$columns) &&
      !is.null(csv_data_raw$data) &&
      "columns" %in% names(csv_data_raw) &&
      "data" %in% names(csv_data_raw)) {
      # NEW FORMAT: Extract data and preserve original column order
      csv_data <- csv_data_raw$data
      original_column_order <- csv_data_raw$columns

      # Convert to dataframe
      df_raw <- as.data.frame(csv_data, stringsAsFactors = FALSE)

      # Apply the preserved column order if valid
      if (!is.null(original_column_order) &&
        is.character(original_column_order) &&
        length(original_column_order) > 0 &&
        all(original_column_order %in% names(df_raw))) {
        df_raw <- df_raw[, original_column_order, drop = FALSE]
      }
    } else {
      # OLD FORMAT: Data is directly in csv_data_raw (backwards compatible)
      # This handles both data frames and lists that can be converted to data frames
      df_raw <- as.data.frame(csv_data_raw, stringsAsFactors = FALSE)
    }
    # preserve original names but make them safe for R indexing
    names(df_raw) <- make.names(names(df_raw))

    # Define canonical required/optional column names (lowercase)
    required_cols <- c("curve.id", "stressor.label", "stressor.x", "units.x", "response.label", "response.y", "units.y")
    optional_cols <- c("stressor.value", "lower.limit", "upper.limit", "sd")

    nm_lower <- tolower(names(df_raw))

    # If this looks like a 'new' csv (contains at least one required canonical name),
    # normalize to the canonical order and ensure optional columns exist.
    if (any(required_cols %in% nm_lower)) {
      # Build mapping of canonical -> actual column name (if present)
      col_order <- c()
      for (rc in required_cols) {
        match_idx <- which(nm_lower == rc)
        if (length(match_idx) == 1) {
          col_order <- c(col_order, names(df_raw)[match_idx])
        }
      }
      for (oc in optional_cols) {
        match_idx <- which(nm_lower == oc)
        if (length(match_idx) == 1) {
          col_order <- c(col_order, names(df_raw)[match_idx])
        } else {
          # Add NA column for missing optional column
          df_raw[[oc]] <- NA
          col_order <- c(col_order, oc)
        }
      }

      # Reorder dataframe to canonical order (only include columns we have)
      existing_cols <- intersect(col_order, names(df_raw))
      df <- df_raw[, existing_cols, drop = FALSE]

      # Convert stressor.x and response.y to numeric (if present by canonical names)
      nm_lower_df <- tolower(names(df))
      if ("stressor.x" %in% nm_lower_df) {
        df[[which(nm_lower_df == "stressor.x")]] <- suppressWarnings(as.numeric(df[[which(nm_lower_df == "stressor.x")]]))
      }
      if ("response.y" %in% nm_lower_df) {
        df[[which(nm_lower_df == "response.y")]] <- suppressWarnings(as.numeric(df[[which(nm_lower_df == "response.y")]]))
      }

      # Keep rows where both X and Y are numeric (if both exist)
      if ("stressor.x" %in% nm_lower_df && "response.y" %in% nm_lower_df) {
        x_i <- which(nm_lower_df == "stressor.x")
        y_i <- which(nm_lower_df == "response.y")
        keep_rows <- !is.na(df[[x_i]]) & !is.na(df[[y_i]])
        df <- df[keep_rows, , drop = FALSE]

        # Sort by curve.id first, then by stressor.x, within each curve
        # This ensures each curve's points are in the correct order for plotting
        if ("curve.id" %in% nm_lower_df) {
          curve_i <- which(nm_lower_df == "curve.id")
          # Use order() with two columns to sort by curve.id, then stressor.x
          df <- df[order(df[[curve_i]], df[[x_i]]), , drop = FALSE]
        } else {
          # Single curve case: just sort by stressor.x
          df <- df[order(df[[x_i]]), , drop = FALSE]
        }
      }
    } else {
      # Fallback historical behavior: find the two most-numeric columns and use them as X/Y
      df <- df_raw
      numeric_counts <- sapply(df, function(col) sum(!is.na(suppressWarnings(as.numeric(col)))))
      if (length(numeric_counts) < 2 || max(numeric_counts) == 0) {
        # Cannot proceed - no numeric data
        df <- data.frame(
          Error = "CSV data does not contain sufficient numeric columns for plotting."
        )
      } else {
        # Sort by descending numeric content
        top2_idx <- order(numeric_counts, decreasing = TRUE)[1:2]
        x_idx <- top2_idx[1]
        y_idx <- top2_idx[2]

        df[[x_idx]] <- suppressWarnings(as.numeric(df[[x_idx]]))
        df[[y_idx]] <- suppressWarnings(as.numeric(df[[y_idx]]))

        # Remove rows with NA in either column
        keep_rows <- !is.na(df[[x_idx]]) & !is.na(df[[y_idx]])
        df <- df[keep_rows, , drop = FALSE]

        # Sort by X values
        df <- df[order(df[[x_idx]]), , drop = FALSE]

        # Rename top2 columns to standard names
        colnames(df)[x_idx] <- "stressor.x"
        colnames(df)[y_idx] <- "response.y"
      }
    }
  } else {
    # No CSV data
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
    # Step 1: Find columns to hide
    nm_lower <- tolower(names(display_df))
    cols_to_hide <- c(
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
