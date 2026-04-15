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
      p("The library contains these main components:"),
      tags$ol(
        tags$li(strong("Metadata"), " - standardized fields describing the stressor-response function, its source, biological context, and supporting details."),
        tags$li(strong("Extracted data"), " - numerical values digitized or obtained from the article (or supplemental datasets), formatted for reuse, plotting, or integration into models."),
        tags$li(strong("Confidence Rankings"), " - qualitative assessments of uncertainty and support for each stressor-response function, based on the CEMPRA Stressor-Response Function Guidance.")
      ),
      hr(),
      h2("Metadata Fields"),
      p("Each entry has an identifier and descriptive metadata fields."),
      includeMarkdown("data/user_guide/metadata_fields.md"),
      h2("Extracted Data"),
      p("When you download an SR function as an Excel Spreadsheet, you receive:"),
      tags$ol(
        tags$li("Metadata (all fields above), and"),
        tags$li("Extracted data table - numerical data pulled from figures, tables, or supplementary files.")
      ),
      p("The extracted spreadsheet data have the following standardized columns:"),
      includeMarkdown("data/user_guide/extracted_data.md"),
      tags$div(
        style = "margin: 16px 0;",
        tags$a(
          href = "#", class = "link-primary",
          onclick = "document.querySelector('a[data-value=\"submit_relationship\"]').click(); return false;",
          "Suggest a Relationship — go to the submission form"
        )
      ),
      p(
        style = "font-style: italic;",
        "Note: All extracted data entries include numeric Stressor (x) and Response (y) values and are associated with a single stressor per SRF entry. Each entry is fully labeled with a Stressor Label, Response Label, and corresponding units to ensure interpretability. Where multiple curves are present for the same stressor, they are distinguished using a curve identifier and, when applicable, a stressor value describing the curve. Early entries contributed by Canadian partners (e.g., CEMPRA, Joe Model) reported the biological response as Mean System Capacity, which scaled response values from 0% to 100%. Since NOAA assumed responsibility for stewardship of the library and expanded its scope, response values have been retained in the original units and formats reported in each source study, rather than standardized across entries. Extracted data may originate from reported tables, supplemental datasets, or digitized figures. When data are digitized from figures, small uncertainties may be introduced; these are documented where possible."
      ),
      hr(),
      h2("Confidence Rankings"),
      p("Each stressor-response function in the e-library includes a set of confidence rankings that help users evaluate the strength, reliability, and applicability of the underlying relationship. These rankings identify five key areas where uncertainty may arise when deriving or applying a stressor-response function."),
      p(
        "For each of the five categories below, authors provide a qualitative ranking —",
        strong("Low"), ",", strong("Moderate"), ", or", strong("High"),
        "— along with an optional rationale. These rankings are intended to support transparency and help users determine how appropriate a given stressor-response function may be for their system, model, or decision context."
      ),
      h3("1. Data Source for Stressor-Response Function"),
      p("This ranking reflects how well the data used to derive the stressor-response function represent the stressor and response of interest."),
      tags$ul(
        tags$li("High confidence typically indicates that data were directly measured, collected using consistent methods, and represent the relevant species, life stage, and geographic context."),
        tags$li("Low confidence may arise when data are sparse, indirect, extrapolated, or compiled from heterogeneous sources."),
      ),
      h3("2. Shape of Stressor-Response Function"),
      p("This ranking describes how well-supported the functional form is (e.g., linear, threshold, dome-shaped)."),
      tags$ul(
        tags$li("High confidence suggests the curve shape is clearly supported by data patterns and model diagnostics."),
        tags$li("Low confidence reflects ambiguous patterns, multiple plausible curve shapes, or models sensitive to parameterization."),
      ),
      h3("3. Data Variance / Consistency"),
      p("This ranking summarizes the variability, noise, or inconsistency in the underlying dataset."),
      tags$ul(
        tags$li("High confidence reflects consistent results across studies, years, or sampling programs."),
        tags$li("Low confidence indicates high variance, conflicting trends, or limited replication."),
      ),
      h3("4. Applicability to System"),
      p("This ranking assesses how transferable the stressor-response function is to other populations, locations, or environmental contexts."),
      tags$ul(
        tags$li("High confidence means the function was derived under conditions similar to where it is applied (species, stock, habitat type, stressor regime)."),
        tags$li("Low confidence is appropriate when extrapolating across systems, regions, or biological differences."),
      ),
      h3("5. Potential Stressor Interactions"),
      p("This ranking considers whether the stressor-response function may be influenced by interactions with other environmental stressors (e.g., temperature × flow)."),
      tags$ul(
        tags$li("High confidence means the original study controlled for or examined relevant interacting stressors."),
        tags$li("Low confidence reflects missing covariates or systems where interactions are likely but unmeasured."),
      ),
      h3("How to Use These Rankings"),
      p("Confidence rankings are not intended to exclude stressor-response functions from use; instead, they help users:"),
      tags$ul(
        tags$li("Interpret model output appropriately,"),
        tags$li("Understand sources of uncertainty,"),
        tags$li("Compare functions when multiple relationships exist,"),
        tags$li("Identify where caution or system-specific calibration may be needed,"),
        tags$li("Recognize areas where further research would be valuable"),
      ),
      p("Users should consider these rankings together with stressor-response function metadata, extracted data, and any accompanying notes to determine how well a function fits their modeling or decision context."),
      hr(),
      h2("Attribution"),
      p("If you use data from this library, please cite the original research article(s)")
    )
  )
}
# nolint end
