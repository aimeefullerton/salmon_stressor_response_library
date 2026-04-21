# nolint start
acknowledgement_ui <- function(id, n) {
  ns <- NS(id)

  tagList(
    div(
      style = "max-width: 1200px; margin: 0 auto; padding: 20px;",
      
      fluidRow(
        column(12, h3("Photos", style = "text-align: center; color: #2c3e50; font-weight: 600; margin-top: 20px; margin-bottom: 30px;"))
      ),

      # Dynamic Pictures Section (Modernized Grid)
      fluidRow(
        style = "display: flex; justify-content: center; flex-wrap: wrap; gap: 15px; margin-top: 10px;",
        lapply(1:n, function(i) {
          tags$div(
            style = "width: 180px; height: 180px; overflow: hidden; border-radius: 12px; box-shadow: 0 4px 10px rgba(0,0,0,0.15); transition: transform 0.2s;",
            tags$img(
              src = paste0("teamimg/highlight/pic", i, ".jpg"),
              style = "width: 100%; height: 100%; object-fit: cover;"
            )
          )
        })
      ),
      
      hr(style = "margin: 50px 0; border-top: 1px solid #ddd;"),

      # Acknowledgement Heading
      fluidRow(
        column(12, h3("Acknowledgements", style = "text-align: center; color: #2c3e50; font-weight: 600; margin-bottom: 40px;"))
      ),

      # NOAA Team-Sponsors Heading
      fluidRow(
        column(12, h4("NOAA Team-Sponsors", style = "text-align: center; color: #555; margin-bottom: 25px;"))
      ),

      # Sponsors' Photos (Circular Avatars)
      fluidRow(
        style = "display: flex; justify-content: center; gap: 40px; flex-wrap: wrap; margin-bottom: 40px;",
        tags$div(
          style = "text-align: center; width: 160px;",
          tags$img(src = "teamimg/Aimee.jpg", style = "width: 130px; height: 130px; border-radius: 50%; object-fit: cover; box-shadow: 0 4px 10px rgba(0,0,0,0.15); border: 3px solid white; margin-bottom: 12px;"),
          tags$p("Aimee Fullerton", style = "font-weight: 600; font-size: 16px; margin: 0; color: #333;")
        ),
        tags$div(
          style = "text-align: center; width: 160px;",
          tags$img(src = "teamimg/paxton.jpg", style = "width: 130px; height: 130px; border-radius: 50%; object-fit: cover; box-shadow: 0 4px 10px rgba(0,0,0,0.15); border: 3px solid white; margin-bottom: 12px;"),
          tags$p("Paxton Calhoun", style = "font-weight: 600; font-size: 16px; margin: 0; color: #333;")
        ),
        tags$div(
          style = "text-align: center; width: 160px;",
          tags$img(src = "teamimg/Morgan.jpg", style = "width: 130px; height: 130px; border-radius: 50%; object-fit: cover; box-shadow: 0 4px 10px rgba(0,0,0,0.15); border: 3px solid white; margin-bottom: 12px;"),
          tags$p("Morgan Bond", style = "font-weight: 600; font-size: 16px; margin: 0; color: #333;")
        ),
        tags$div(
          style = "text-align: center; width: 160px;",
          tags$img(src = "teamimg/Danielle.jpg", style = "width: 130px; height: 130px; border-radius: 50%; object-fit: cover; box-shadow: 0 4px 10px rgba(0,0,0,0.15); border: 3px solid white; margin-bottom: 12px;"),
          tags$p("Danielle Andrews", style = "font-weight: 600; font-size: 16px; margin: 0; color: #333;")
        )
      ),

      # Original designers (Cleaned up list styling)
      fluidRow(
        column(
          12,
          tags$div(
            style = "background-color: #f8f9fa; border-radius: 10px; padding: 25px; max-width: 800px; margin: 0 auto 50px auto; text-align: center; box-shadow: 0 2px 8px rgba(0,0,0,0.05);",
            h5("The original design/layout for this e-library came from the following collaborators in Canada:", style = "color: #444; margin-bottom: 15px;"),
            tags$ul(
              style = "list-style-type: none; padding: 0; text-align: center; color: #555; line-height: 1.8;",
              tags$li("Sierra Sullivan (The University of British Columbia)"),
              tags$li("Jordan Rosenfeld (British Columbia Ministry of Environment)"),
              tags$li("Matthew Bayly (M.J. Bayly Analytics Ltd.)"),
              tags$li("Mathew Bakken (The University of British Columbia)"),
              tags$li("Alexandra Tekatch (ESSA Technologies Ltd.)")
            )
          )
        )
      ),

      # Team Photo Section
      fluidRow(
        column(12, h4("Student Team", style = "text-align: center; color: #555; margin-bottom: 25px;"))
      ),
      fluidRow(
        style = "display: flex; justify-content: center; align-items: flex-start; flex-wrap: wrap; gap: 50px; margin-bottom: 50px;",

        # Group Photo Block
        tags$div(
          style = "width: 350px; text-align: center;",
          tags$img(
            src = "teamimg/Team.jpg",
            style = "width: 100%; height: auto; border-radius: 12px; box-shadow: 0 6px 15px rgba(0,0,0,0.15);"
          ),
          tags$p("SU Student Development Team", style = "margin: 15px 0 0 0; font-weight: 600; font-size: 16px; color: #333;"),
          tags$p("From left to right: Maelice Yamdjieu, Garrett Ringler, Lavanya Bunadri, and Ruqhaiya Syeda", style = "font-size: 14px; font-style: italic; color: #666; margin-top: 5px;")
        ),

        # Individual Team Member Block
        tags$div(
          style = "width: 250px; text-align: center;",
          tags$img(
            src = "teamimg/Mendible.jpg",
            style = "width: 100%; height: auto; border-radius: 12px; box-shadow: 0 6px 15px rgba(0,0,0,0.15);"
          ),
          tags$p("Dr. Ariana Mendible", style = "font-weight: 600; font-size: 16px; margin: 15px 0 0 0; color: #333;"),
          tags$p("Professor of Mathematics at Seattle University", style = "font-size: 14px; color: #666; margin-top: 5px;")
        )
      ),

      hr(style = "margin: 40px 0; border-top: 1px solid #eee;"),

      # Additional Sources Section
      fluidRow(
        column(12, h5("Additional Sources", style = "text-align: left; color: #444; font-weight: 600;"))
      ),
      fluidRow(
        column(12,
          tags$ul(
            style = "list-style-type: none; padding: 0; display: flex; gap: 20px; font-size: 15px; margin-bottom: 40px;",
            tags$li(tags$a(href = "https://www.noaa.gov", "NOAA Official Website", target = "_blank", style = "color: #6082B6; text-decoration: none; font-weight: 500;")),
            tags$li(tags$a(href = "https://www.fisheries.noaa.gov/region/west-coast/northwest-science", "NOAA Fisheries", target = "_blank", style = "color: #6082B6; text-decoration: none; font-weight: 500;"))
          )
        )
      )
    )
  )
}
# nolint end
