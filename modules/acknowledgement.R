acknowledgement_ui <- function(id, n) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      column(12, h4("Photos", style = "text-align: left; margin-top: 30px; margin-bottom: 10px;"))
    ),
    
    # Dynamic Pictures Section (n pictures)
    fluidRow(
      style = "display: flex; justify-content: flex-start; flex-wrap: wrap; gap: 15px; margin-top: 10px;",
      lapply(1:n, function(i) {
        tags$div(
          style = "width: 200px; height: 200px; overflow: hidden; border: 2px solid #ddd; border-radius: 10px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);",
          tags$img(
            src = paste0("teamimg/highlight/pic", i, ".jpg"),
            style = "width: 100%; height: 100%; object-fit: cover;"
          )
        )
      })
    ),
    
    # Acknowledgement Heading
    fluidRow(
      column(12, h3("Acknowledgement", style = "text-align: left; margin-top: 40px;"))
    ),
    
    # NOAA Team-Sponsors Heading
    fluidRow(
      column(12, h4("NOAA Team-Sponsors", style = "text-align: center; margin-top: 20px;"))
    ),
    
    # Sponsors' Photos
    fluidRow(
      style = "display: flex; justify-content: center; gap: 20px; flex-wrap: wrap; margin-top: 20px;",
      tags$div(
        tags$img(src = "teamimg/Aimee.jpg", height = "150px"),
        tags$p("Aimee Fullerton", class = "text-center", style = "font-size: 16px;")
      ),
      tags$div(
        tags$img(src = "teamimg/paxton.jpg", height = "150px"),
        tags$p("Paxton Calhoun", class = "text-center", style = "font-size: 16px;")
      ),
      tags$div(
        tags$img(src = "teamimg/Morgan.jpg", height = "150px"),
        tags$p("Morgan Bond", class = "text-center", style = "font-size: 16px;")
      ),
      tags$div(
        tags$img(src = "teamimg/Danielle.jpg", height = "150px"),
        tags$p("Danielle Andrews", class = "text-center", style = "font-size: 16px;")
      )
    ),
    
    # Team Photo Section (Formatted Group Photo + Individual Team Members)
    fluidRow(
      column(12, h3("Team", style = "text-align: center; margin-top: 30px; margin-bottom: 30px;"))
    ),
    fluidRow(
      style = "display: flex; justify-content: center; align-items: flex-start; flex-wrap: wrap; gap: 40px;",
      
      # Group Photo Block
      tags$div(
        style = "width: 300px; text-align: center;",
        tags$img(
          src = "teamimg/Team.jpg",
          class = "img-fluid img-thumbnail",
          style = "width: 100%; height: auto; border-radius: 10px; box-shadow: 0 4px 10px rgba(0,0,0,0.2);"
        ),
        tags$p("SU Student Development Team", style = "margin-top: 10px; font-size: 16px;")
      ),
      
      # Individual Team Member Block
      tags$div(
        style = "width: 230px; text-align: center;",
        tags$img(
          src = "teamimg/Mendible.jpg",
          style = "width: 100%; height: auto; border-radius: 10px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);"
        ),
        tags$p("Dr. Mendible", style = "margin-top: 10px; font-size: 16px;")
      )
    
    
    ),
    
    # Additional Sources Section
    fluidRow(
      column(12, h4("Additional Sources", style = "text-align: left; margin-top: 50px;"))
    ),
    fluidRow(
      column(12,
             tags$ul(
               tags$li(tags$a(href = "https://www.noaa.gov", "NOAA Official Website", target = "_blank")),
               tags$li(tags$a(href = "https://www.fisheries.noaa.gov/region/west-coast/northwest-science", "NOAA Fisheries", target = "_blank"))
             ),
             style = "text-align: left; font-size: 16px; margin-bottom: 40px;"
      )
    )
  )
}
