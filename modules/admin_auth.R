# nolint start
library(shiny)

# UI: shows a password box + login button
adminAuthUI <- function(id) {
  ns <- NS(id)
  tagList(
    passwordInput(ns("pwd"), "Admin password:"),
    actionButton(ns("login"), "Login", class = "btn btn-primary"),
    tags$script(HTML(sprintf("
      $(document).on('keypress', '#%s', function(e) {
        if (e.which == 13) {
          $('#%s').click();
        }
      });
    ", ns("pwd"), ns("login")))),
    tags$hr()
  )
}


# Server: checks against a hard-coded password
# Returns a reactiveVal(TRUE/FALSE) for login status
adminAuthServer <- function(id, correct_pw = "secret123", updateStatus = reactiveVal()) {
  moduleServer(id, function(input, output, session) {
    logged_in <- reactiveVal(FALSE)

    observeEvent(input$login, {
      req(input$pwd)
      if (input$pwd == correct_pw) {
        logged_in(TRUE)
        updateStatus(TRUE)
        showNotification("🔓 Admin unlocked", type = "message")
      } else {
        showNotification("❌ Wrong password", type = "error")
      }
    })

    return(logged_in)
  })

}


# nolint end
