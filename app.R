# global settings, UI and Server components
source("global.R")
source("ui.R")
source("server.R")

# This line runs the app
shinyApp(ui = ui, server = server)

# Lauch app with: shiny::runApp("app.R")
