# nolint start

create_back_button <- function() {
  tagList(
    # Back button to return to dashboard
    tags$a(
      href = "?",
      tags$div(id = "backButtonArrow", class = "arrow-container")
    ),
    tags$style(HTML("
      .arrow-container {
        width: 30px;
        height: 30px;
        display: flex;
        align-items: center;
        justify-content: center;
        cursor: pointer;
      }

      .arrow-container::before {
        content: '\\2190'; /* Unicode for left arrow */
        font-size: 35px;
        color: #2C3E50;
      }
    "))
  )
}

# nolint end
