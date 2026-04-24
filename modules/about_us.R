# nolint start
about_us <- function(id) {
  ns <- NS(id)
  tagList(
    div(
      style = "max-width: 1200px; margin: 0 auto; padding: 20px;",
      
      # Hero Section
      div(
        style = "background: linear-gradient(135deg, #fdfbfb 0%, #ebedee 100%); 
                 padding: 40px 30px; border-radius: 15px; text-align: center; 
                 margin-bottom: 40px; box-shadow: 0 4px 12px rgba(0,0,0,0.05);",
        h2("About this Dashboard", style = "color: #2c3e50; font-weight: 700; margin-bottom: 20px;"),
        p("The Pacific Salmonid Stressor-Response eLibrary is an open-source, centralized resource designed to support researchers and modelers working with life cycle models (LCMs). It consolidates and organizes published quantitative relationships between environmental stressors and salmonid life stages, making it easier to access and apply relevant data.", 
          style = "font-size: 1.1rem; color: #444; max-width: 900px; margin: 0 auto 15px auto;"),
        p("This e-library serves as a decision-support tool, helping ensure that life cycle modeling efforts are built on a shared foundation of empirical data. While the provided relationships are drawn from peer-reviewed literature and vetted studies, users should critically assess the data’s applicability to their specific models and consider factors such as regional differences, study limitations, and context-specific variables.",
          style = "font-size: 1.1rem; color: #444; max-width: 900px; margin: 0 auto;")
      ),
      
      # Side-by-side Info Cards
      layout_columns(
        col_widths = c(6, 6),
        
        # Left Card: Conservation Efforts
        card(
          style = "border: none; box-shadow: 0 4px 12px rgba(0,0,0,0.05); border-top: 4px solid #2ecc71;",
          card_header(h4("How This Tool Supports Conservation", style = "margin: 0; color: #333; font-weight: 600;"), style = "background-color: white; border-bottom: none;"),
          card_body(
            tags$ul(
              style = "list-style-type: none; padding-left: 0;",
              tags$li(style = "margin-bottom: 15px;", bs_icon("check-circle-fill", class = "text-success", size = "1.5rem"), strong(" Improve Model Accuracy:"), " Ensuring researchers and decision-makers have access to consistent, high-quality data reduces uncertainty in life cycle modeling."),
              tags$li(style = "margin-bottom: 15px;", bs_icon("lightbulb-fill", class = "text-warning", size = "1.5rem"), strong(" Identify Knowledge Gaps:"), " Highlighting areas where data is lacking can guide future research and funding priorities."),
              tags$li(style = "margin-bottom: 15px;", bs_icon("bar-chart-fill", class = "text-info", size = "1.5rem"), strong(" Support Policy & Management:"), " Reliable data on stressor-response functions can inform habitat restoration, water management, and conservation policy."),
              tags$li(style = "margin-bottom: 15px;", bs_icon("globe", class = "text-primary", size = "1.5rem"), strong(" Encourage Open Science:"), " By making key data easily accessible, the e-library fosters collaboration and transparency within the life cycle modeling community.")
            )
          )
        ),
        
        # Right Card: Using the App & Credits
        card(
          style = "border: none; box-shadow: 0 4px 12px rgba(0,0,0,0.05); border-top: 4px solid #6082B6;",
          card_header(h4("Using the e-Library", style = "margin: 0; color: #333; font-weight: 600;"), style = "background-color: white; border-bottom: none;"),
          card_body(
            p("If relevant studies appear, review the metadata and study details to determine whether the findings align with your research needs."),
            p("If no studies are returned, this may indicate:"),
            tags$ul(
              tags$li("The topic has not yet been researched by our team, AND/OR"),
              tags$li("A gap exists in the scientific literature, highlighting an area for future study.")
            ),
            p("By providing a one-stop, transparent repository of stressor-response functions, this e-library supports informed decision-making and fosters an open-science approach within the LCM community."),
            hr(style = "margin: 20px 0;"),
            p(
              style = "font-size: 0.9rem; color: #666;",
              "This R/Shiny app was developed by a team of Seattle University data science students (see acknowledgements below). It was modeled after an existing Drupal app created by Matthew Bayly. We owe a great deal of gratitude to Matthew and his colleagues for generating the original app and for allowing us to emulate its function here. Matthew's app can be found ",
              tags$a(href = "https://mjbayly.com/stressor-response", "here.", target = "_blank")
            ),
            p(
              style = "font-size: 0.9rem; color: #666;",
              "This app is still under active development and we welcome feedback about the user experience (to aimee.fullerton at noaa dot gov). We will be adding additional relationships on a rolling basis over the next several years."
            )
          )
        )
      )
    )
  )
}
# nolint end
