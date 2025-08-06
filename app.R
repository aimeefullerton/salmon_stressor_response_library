# global settings, UI and Server components
source("global.R")
source("ui.R")
source("server.R")

# This line runs the app
shinyApp(ui = ui, server = server)

# to test locally,
# open the R Interactive terminal and
# run the app with: shiny::runApp(launch.browser = TRUE)
