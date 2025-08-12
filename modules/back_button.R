# nolint start

create_back_button <- function() {
  div(
    style = "margin-bottom: 20px;",
    actionButton(
      "back_to_dashboard",
      "← Back to Dashboard",
      onclick = "filterManagement.backToDashboard();",
      class = "btn btn-primary btn-lg"
    )
  )
}

# nolint end
