# nolint start

library(shinyjs)
library(dygraphs)

render_article_ui <- function(article_id, data) {
  article <- data[data$article_id == article_id, ]
  if (nrow(article) == 0) {
    return(tags$p("Article not found."))
  }

  # All IDs scoped to article_id to avoid conflicts between articles
  expand_id <- paste0("expand_all_", article_id)
  collapse_id <- paste0("collapse_all_", article_id)
  meta_id <- paste0("metadata_section_", article_id)
  desc_id <- paste0("description_section_", article_id)
  conf_id <- paste0("confidence_section_", article_id)
  cite_id <- paste0("citations_section_", article_id)
  csv_id <- paste0("csv_section_", article_id)
  plot_id <- paste0("interactive_plot_section_", article_id)

  tagList(
    # ── Title ──────────────────────────────────────────────────────────────
    fluidRow(
      column(12,
        align = "center",
        tags$h3(article$title, style = "margin-top: 20px; margin-bottom: 10px;")
      )
    ),

    # ── Expand / Collapse ──────────────────────────────────────────────────
    fluidRow(
      column(12,
        align = "center",
        actionButton(expand_id, "Expand All",
          class = "btn-sm",
          style = "padding: 8px 16px; margin-right: 8px;"
        ),
        actionButton(collapse_id, "Collapse All",
          class = "btn-sm",
          style = "padding: 8px 16px;"
        )
      )
    ),

    # ── Article Metadata ───────────────────────────────────────────────────
    div(
      style = "border: 1px solid #ddd; padding: 15px; margin-bottom: 10px; background-color: #f8f9fa; border-radius: 8px;",
      actionLink(paste0("toggle_metadata_", article_id), "Article Metadata ▼", class = "section-title"),
      hidden(div(
        id    = meta_id,
        style = "font-size:1.1em;",
        fluidRow(column(4, strong("Species Common Name:")), column(8, textOutput(paste0("species_name_", article_id)))),
        fluidRow(column(4, strong("Latin Name (Genus species):")), column(8, em(textOutput(paste0("latin_name_", article_id))))),
        fluidRow(column(4, strong("Stressor Name:")), column(8, textOutput(paste0("stressor_name_", article_id)))),
        fluidRow(column(4, strong("Specific Stressor Metric:")), column(8, textOutput(paste0("specific_stressor_metric_", article_id)))),
        fluidRow(column(4, strong("Response:")), column(8, textOutput(paste0("response_", article_id)))),
        fluidRow(column(4, strong("Life Stage:")), column(8, textOutput(paste0("life_stage_", article_id)))),
    # NEW: Dynamic UI placeholders for conditional location fields
        uiOutput(paste0("location_country_ui_", article_id)),
        uiOutput(paste0("location_state_province_ui_", article_id)),
        uiOutput(paste0("location_watershed_lab_ui_", article_id)),
        uiOutput(paste0("location_river_creek_ui_", article_id))
      ))
    ),

    # ── Description & Function Details ─────────────────────────────────────
    div(
      style = "border: 1px solid #ddd; padding: 15px; margin-bottom: 10px; background-color: #ffffff; border-radius: 8px;",
      actionLink(paste0("toggle_description_", article_id), "Description & Function Details ▼", class = "section-title"),
      hidden(div(
        id = desc_id,
        style = "font-size:1.1em;",
        strong("Detailed SR Function Description"), br(), textOutput(paste0("overview_", article_id)), br(), br(),
        strong("Function Derivation"), br(), textOutput(paste0("function_derivation_", article_id)),
        # Dynamic UI placeholders for conditional fields
        uiOutput(paste0("transferability_ui_", article_id)),
        withMathJax(uiOutput(paste0("srf_formula_ui_", article_id)))
      ))
    ),

    # ── Confidence Rankings ────────────────────────────────────────────────
    div(
      style = "border: 1px solid #ddd; padding: 15px; margin-bottom: 10px; background-color: #ffffff; border-radius: 8px;",
      actionLink(paste0("toggle_confidence_", article_id), "Confidence Rankings & Uncertainty ▼", class = "section-title"),
      hidden(div(
        id    = conf_id,
        style = "font-size:1.1em;",
        tableOutput(paste0("confidence_table_", article_id))
      ))
    ),

    # ── Citations ──────────────────────────────────────────────────────────
    div(
      style = "border: 1px solid #ddd; padding: 15px; margin-bottom: 10px; background-color: #ffffff; border-radius: 8px;",
      actionLink(paste0("toggle_citations_", article_id), "Citation(s) ▼", class = "section-title"),
      hidden(div(
        id    = cite_id,
        style = "font-size:1.1em;",
        uiOutput(paste0("citations_", article_id))
      ))
    ),

    # ── CSV Data Table ─────────────────────────────────────────────────────
    div(
      style = "border: 1px solid #ddd; padding: 15px; margin-bottom: 10px; background-color: #ffffff; border-radius: 8px;",
      actionLink(paste0("toggle_csv_", article_id), "Stressor Response Data ▼", class = "section-title"),
      hidden(div(
        id    = csv_id,
        style = "font-size:1.1em;",
        tableOutput(paste0("csv_table_", article_id))
      ))
    ),

    # ── Interactive Plot ───────────────────────────────────────────────────
    div(
      style = "border: 1px solid #ddd; padding: 15px; margin-bottom: 10px; background-color: #ffffff; border-radius: 8px;",
      actionLink(paste0("toggle_interactive_plot_", article_id), "Stressor Response Chart ▼", class = "section-title"),
      hidden(div(
        id    = plot_id,
        style = "font-size:1.1em;",
        plotlyOutput(paste0("interactive_plot_", article_id))
      ))
    )
  )
}

# nolint end
