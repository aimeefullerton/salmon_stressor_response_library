# nolint start

library(DBI)
library(RSQLite)
library(jsonlite)
library(ggplot2)
library(zoo)
library(plotly)

render_article_server <- function(input, output, session, paper_id, db) {
  
  # Ensure database connection is provided
  if (missing(db)) {
    stop("Database connection (db) is missing!")
  }
  
  # Fetch article data from SQLite
  paper <- dbGetQuery(db,
                      "SELECT * FROM stressor_responses WHERE main_id = ?",
                      params = list(paper_id)
  )
  
  
  # Check if article data exists
  if (nrow(paper) == 0) {
    return(NULL)
  }
  
  paper <- paper[1, ]  # Ensure single-row data
  
  output$article_title <- renderText({
    # if you want a fallback when title is missing:
    if (is.na(paper$title) || paper$title == "") "Untitled Article"
    else paper$title
  })

  # vector of all section div IDs
  all_ids <- c(
    "metadata_section", "description_section", "citations_section",
    "images_section", "csv_section", "plot_section", "interactive_plot_section"
  )
  
  # expand all
  
  # a named vector of base labels:
  base_labels <- c(
    toggle_metadata       = "Article Metadata",
    toggle_description    = "Description & Function Details",
    toggle_citations      = "Citation(s)",
    toggle_images         = "Images",
    toggle_csv            = "Stressor Response Data",
    toggle_plot           = "Stressor Response Chart",
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
  
  ##  End expand/collapse code

  
  # Function to safely parse JSON fields
  safe_fromJSON <- function(x) {
    # bail early on NULL, NA, empty, or literal "NULL"/"[]"
    if (is.null(x) ||
        (length(x)==1 && is.na(x)) ||
        !nzchar(x) ||
        x %in% c("NULL", "[]")) {
      return(NULL)
    }
    # else try to parse
    parsed <- tryCatch(jsonlite::fromJSON(x), error = function(e) NULL)
    # if it ends up being atomic, wrap as list
    if (!is.null(parsed) && !is.list(parsed)) {
      parsed <- list(parsed)
    }
    parsed
  }
  
  
  paper$citations <- safe_fromJSON(paper$citations_citation_text)
  paper$citation_links <- safe_fromJSON(paper$citations_citation_links)
  paper$images <- safe_fromJSON(paper$images)
  
  safe_get <- function(df, col) {
    if (col %in% names(df)) return(ifelse(is.na(df[[col]]), "Not provided", df[[col]]))
    return("Not provided")
  }
  
  smart_round <- function(col) {
    col <- suppressWarnings(as.numeric(col))
    if (all(col %% 1 == 0, na.rm = TRUE)) return(as.integer(col))
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
  
  # Render images
  output$article_images <- renderUI({
    cat("\n image raw:\n")
    print(paper$images)

    image_url <- NULL

    if (is.list(paper$images) && !is.null(paper$images$image_url)) {
      image_url <- paper$images$image_url
    } else if (is.character(paper$images) && nzchar(paper$images)) {
      image_url <- paper$images
    }

    if (!is.null(image_url) && nzchar(image_url)) {
      tags$figure(
        tags$img(src = image_url, width = "60%", alt = "Article Image"),
        tags$figcaption("Figure extracted from the database.")
      )
    } else {
      tags$p("No images available.")
  }
})

  
  # # Fetch stressor response data from csv_numeric + csv_meta
  # stressor_data <- dbGetQuery(db,
  #                             "SELECT n.*, m.article_stressor_label, m.scaled_response_label
  #    FROM csv_numeric n
  #    JOIN csv_meta    m ON n.csv_id = m.csv_id
  #   WHERE m.main_id = ?",
  #                             params = list(paper_id)
  # )  

  # Parse stressor response data directly from JSON column
  csv_data <- safe_fromJSON(paper$csv_data_json)
  if (!is.null(csv_data)) {
    df <- as.data.frame(csv_data, stringsAsFactors = FALSE)
    names(df) <- make.names(names(df))  # Make names syntactically valid
    df[] <- lapply(df, function(x) suppressWarnings(as.numeric(x)))
    df <- df[complete.cases(df), ]
    df <- df[order(df[[1]]), ]  # Sort by X
  } else {
    df <- data.frame()
  }

  # Table
  output$csv_table <- renderTable({
  if (nrow(df) == 0) return(data.frame(Message = "No data available for this article"))

  colnames(df) <- gsub("\\.", " ", colnames(df))  # Replace dots with spaces
  colnames(df)[1] <- safe_get(paper, "stressor_name")
  df
})


  # Static Plot
  output$stressor_plot <- renderPlot({
  if (nrow(df) == 0) {
    plot(1, type = "n", axes = FALSE, xlab = "", ylab = "")
    text(1, 1, "No data available for this article", col = "black", cex = 1.5, font = 2)
    return()
  }

  plot(
    df[[1]], df[[2]],
    type = "o", col = "blue", pch = 16, lwd = 2,
    xlab = safe_get(paper, "stressor_name"),
    ylab = gsub("\\.", " ", names(df)[2]),
    main = paste("Stressor Response for", safe_get(paper, "stressor_name"))
  )
})


  # Interactive Plot
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

  plot_ly(df, x = ~df[[1]], y = ~df[[2]],
          type = "scatter", mode = "lines+markers",
          line = list(color = "blue"), marker = list(size = 6)) %>%
    layout(
      title = paste("Interactive Plot for", safe_get(paper, "stressor_name")),
      xaxis = list(title = safe_get(paper, "stressor_name")),
      yaxis = list(title = gsub("\\.", " ", names(df)[2]))
    )
})

}

# nolint end
