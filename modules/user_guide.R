# nolint start
userGuideUI <- function(id) {
  ns <- NS(id)
  tagList(
    div(
      class = "page-container",
      h1("User Guide"),
      h2("Stressor Response Metadata and Data Documentation"),
      p("This e-library is designed to support life cycle modelers, resource managers, and scientists by making stressor-response (SR) functions discoverable, transparent, and reusable. Each SR function describes the quantitative relationship between a stressor (e.g., temperature, flow, harvest, contaminants) and a biological response (e.g., survival, growth, migration timing, capacity, productivity)."),
      hr(),
      p("The library contains two main components:"),
      tags$ol(
        tags$li(strong("Metadata"), " - standardized fields describing the SR function, its source, and context"),
        tags$li(strong("Extracted data"), " - numerical data extracted from the article (or supplemental datasets) that has been formatted for reuse and analysis")
      ),
      hr(),
      h2("Metadata Fields"),
      p("Each entry has an identifier and descriptive metadata fields."),
      includeMarkdown("data/user_guide/metadata_fields.md"),
      h2("Extracted Data"),
      p("When you download an SR function as a CSV, you receive:"),
      tags$ol(
        tags$li("Metadata (all fields above), and"),
        tags$li("Extracted data table - numerical data pulled from figures, tables, or supplementary files.")
      ),
      p("The extracted CSV data have two to four standardized columns:"),
      includeMarkdown("data/user_guide/extracted_data.md"),
      tags$div(style = "margin-top:10px;",
        tags$a(href = "#", class = "link-primary",
          onclick = "document.querySelector('a[data-value=\"submit_relationship\"]').click(); return false;",
          "Suggest a Relationship — open the submission form"
        )
      ),
      p(
        style = "font-style: italic;",
        "Note: All extracted data entries include numeric Stressor (x) and Response (y) values and are associated with a single stressor per SRF entry. Each entry is fully labeled with a Stressor Label, Response Label, and corresponding units to ensure interpretability. Where multiple curves are present for the same stressor, they are distinguished using a curve identifier and, when applicable, a stressor value describing the curve. Early entries contributed by Canadian partners (e.g., CEMPRA, Joe Model) reported the biological response as Mean System Capacity, which scaled response values from 0% to 100%. Since NOAA assumed responsibility for stewardship of the library and expanded its scope, response values have been retained in the original units and formats reported in each source study, rather than standardized across entries. Extracted data may originate from reported tables, supplemental datasets, or digitized figures. When data are digitized from figures, small uncertainties may be introduced; these are documented where possible."
      ),
      hr(),
      h2("Attribution"),
      p("If you use data from this library, please cite the original research article(s)")
    )
  )
}
# nolint end
