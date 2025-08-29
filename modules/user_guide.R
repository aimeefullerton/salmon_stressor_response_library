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
      p(
        style = "font-style: italic;",
        "Note: All entries in the extracted dataset include a Stressor (x) and Response (y) value, while Treatment Label and Treatment Value are only present when applicable. Early entries contributed by Canadian partners (CEMPRA, Joe Model) reported the biological response as “Mean System Capacity”, which scales response values from 0% to 100%. Since NOAA assumed responsibility for the library and expanded its scope, response values have been retained in the original units and formats presented in each paper, rather than standardized. Extracted data may come from digitized figures, reported tables, or supplemental datasets. Small uncertainties may exist in digitized data, which are noted where possible."
      ),
      hr(),
      h2("Attribution"),
      p("If you use data from this library, please cite the original research article(s)")
    )
  )
}
# nolint end
