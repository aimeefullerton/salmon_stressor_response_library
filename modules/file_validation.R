# Basic PDF validation helper
# Checks extension, MIME type, and size

MAX_PDF_SIZE_BYTES <- 5 * 1024 * 1024 # 5 MB

validate_pdf_upload <- function(file_input) {
  if (is.null(file_input)) {
    return(list(valid = TRUE, message = "", issues = list()))
  }

  # file_input is a Shiny file input object
  fname <- file_input$name
  fpath <- file_input$datapath
  ftype <- file_input$type

  issues <- list()

  # Extension check
  ext <- tolower(tools::file_ext(fname))
  if (ext != "pdf") {
    issues <- c(issues, "File extension must be .pdf")
  }

  # MIME type check (best-effort)
  if (!is.null(ftype) && ftype != "application/pdf") {
    # Some browsers/clients may send a different MIME; warn but not strictly fail
    issues <- c(issues, sprintf("Unexpected MIME type: %s", ftype))
  }

  # Size check
  if (!file.exists(fpath)) {
    issues <- c(issues, "Uploaded file not found on disk")
  } else {
    sz <- file.info(fpath)$size
    if (!is.na(sz) && sz > MAX_PDF_SIZE_BYTES) {
      issues <- c(issues, sprintf("PDF exceeds maximum allowed size (%d bytes)", MAX_PDF_SIZE_BYTES))
    }
  }

  list(valid = length(issues) == 0, message = paste(issues, collapse = "; "), issues = issues)
}
