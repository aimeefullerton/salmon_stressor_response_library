# nolint start

# Error Handling and User Messaging Functions
# This module provides consistent error, warning, and success messages

#' Show Error Modal to User
#'
#' @param session Shiny session object
#' @param title Modal title
#' @param message Error message (can be HTML)
#' @param details Optional additional details/issues
#'
#' @return NULL (invisibly)
show_error_modal <- function(session, title, message, details = NULL) {
  detail_text <- ""
  if (!is.null(details) && length(details) > 0) {
    detail_items <- paste(sprintf("<li>%s</li>", details), collapse = "\n")
    detail_text <- sprintf(
      "<div style='margin-top: 15px; padding: 10px; background-color: #f8f9fa; border-left: 3px solid #dc3545; border-radius: 3px;'>
       <strong>Details:</strong>
       <ul style='margin: 5px 0; padding-left: 20px;'>%s</ul>
       </div>",
      detail_items
    )
  }

  showModal(modalDialog(
    title = title,
    HTML(sprintf("%s%s", message, detail_text)),
    easyClose = TRUE,
    footer = modalButton("Close"),
    size = "m"
  ))

  invisible(NULL)
}

#' Show Success Modal to User
#'
#' @param session Shiny session object
#' @param title Modal title
#' @param message Success message
#'
#' @return NULL (invisibly)
show_success_modal <- function(session, title, message) {
  showModal(modalDialog(
    title = title,
    HTML(sprintf(
      "<div style='color: #155724; background-color: #d4edda; padding: 12px; border-radius: 4px;'>%s</div>",
      message
    )),
    easyClose = TRUE,
    footer = modalButton("Close"),
    size = "m"
  ))

  invisible(NULL)
}

#' Show Warning Modal to User
#'
#' @param session Shiny session object
#' @param title Modal title
#' @param message Warning message
#' @param details Optional additional details
#'
#' @return NULL (invisibly)
show_warning_modal <- function(session, title, message, details = NULL) {
  detail_text <- ""
  if (!is.null(details) && length(details) > 0) {
    detail_items <- paste(sprintf("<li>%s</li>", details), collapse = "\n")
    detail_text <- sprintf(
      "<div style='margin-top: 15px; padding: 10px; background-color: #f8f9fa; border-left: 3px solid #ffc107; border-radius: 3px;'>
       <strong>Details:</strong>
       <ul style='margin: 5px 0; padding-left: 20px;'>%s</ul>
       </div>",
      detail_items
    )
  }

  showModal(modalDialog(
    title = title,
    HTML(sprintf("%s%s", message, detail_text)),
    easyClose = TRUE,
    footer = modalButton("Close"),
    size = "m"
  ))

  invisible(NULL)
}

#' Create HTML Alert Message (for inline display)
#'
#' @param type Alert type: "error", "warning", "success", "info"
#' @param message Alert message
#' @param details Optional list of detail items
#'
#' @return HTML string
create_alert_html <- function(type = "info", message, details = NULL) {
  type_map <- list(
    error = list(
      bg = "#f8d7da",
      border = "#f5c6cb",
      text = "#721c24",
      icon = "⚠️"
    ),
    warning = list(
      bg = "#fff3cd",
      border = "#ffeeba",
      text = "#856404",
      icon = "⚡"
    ),
    success = list(
      bg = "#d4edda",
      border = "#c3e6cb",
      text = "#155724",
      icon = "✓"
    ),
    info = list(
      bg = "#d1ecf1",
      border = "#bee5eb",
      text = "#0c5460",
      icon = "ℹ️"
    )
  )

  style_info <- type_map[[type]] %||% type_map$info

  detail_html <- ""
  if (!is.null(details) && length(details) > 0) {
    detail_items <- paste(sprintf("<li>%s</li>", details), collapse = "\n")
    detail_html <- sprintf(
      "<ul style='margin-top: 10px; margin-bottom: 0; padding-left: 20px;'>%s</ul>",
      detail_items
    )
  }

  sprintf(
    "<div style='padding: 12px 15px; background-color: %s; border: 1px solid %s; border-radius: 4px; color: %s; margin: 10px 0;'>
     <strong>%s %s</strong>
     %s
     </div>",
    style_info$bg, style_info$border, style_info$text, style_info$icon, message, detail_html
  )
}

#' Get User-Friendly Error Message for CSV Upload
#'
#' @param validation_result Result from validate_csv_upload()
#'
#' @return List with $title and $message for display
get_csv_error_message <- function(validation_result) {
  if (validation_result$valid) {
    return(list(title = "Success", message = "CSV validation passed"))
  }

  message <- validation_result$message
  issues <- validation_result$all_issues %||% list()

  # Create helpful guidance based on issue
  guidance <- ""
  if (length(issues) > 0) {
    if (any(grepl("Missing required columns", issues, ignore.case = TRUE))) {
      guidance <- "\n\n<strong>How to fix:</strong> Ensure your CSV file has exactly these columns: stressor, response, sd, low_limit, up_limit"
    } else if (any(grepl("non-numeric", issues, ignore.case = TRUE))) {
      guidance <- "\n\n<strong>How to fix:</strong> Check that all numeric columns contain only numbers (no text, letters, or special characters except decimals)"
    } else if (any(grepl("empty", issues, ignore.case = TRUE))) {
      guidance <- "\n\n<strong>How to fix:</strong> Fill in all required fields with valid data"
    } else if (any(grepl("duplicate", issues, ignore.case = TRUE))) {
      guidance <- "\n\n<strong>How to fix:</strong> Remove or consolidate duplicate stressor values"
    }
  }

  list(
    title = "❌ CSV Upload Validation Failed",
    message = paste0(message, guidance),
    issues = issues
  )
}

#' Log Error for Debugging
#'
#' @param context Context of the error (e.g., "CSV Upload", "Database Insert")
#' @param error_msg Error message
#' @param additional_info Optional list of additional information
#'
#' @return NULL (invisibly)
log_error <- function(context, error_msg, additional_info = NULL) {
  timestamp <- Sys.time()
  log_entry <- sprintf(
    "[%s] %s: %s",
    timestamp, context, error_msg
  )

  if (!is.null(additional_info) && length(additional_info) > 0) {
    info_str <- paste(
      sprintf("%s: %s", names(additional_info), additional_info),
      collapse = "; "
    )
    log_entry <- sprintf("%s | %s", log_entry, info_str)
  }

  message(log_entry)
  invisible(NULL)
}

#' Check for Title Duplication
#'
#' @param title Title to check
#' @param db_conn Database connection
#'
#' @return List with $duplicate (logical) and $message (character)
check_title_duplicate <- function(title, db_conn) {
  if (is.null(title) || title == "") {
    return(list(duplicate = FALSE, message = "No title provided"))
  }

  tryCatch(
    {
      existing_title <- dbGetQuery(db_conn,
        "SELECT 1 FROM stressor_responses WHERE LOWER(TRIM(title)) = LOWER(TRIM($1)) LIMIT 1",
        params = list(title)
      )

      if (nrow(existing_title) > 0) {
        return(list(
          duplicate = TRUE,
          message = sprintf(
            "A stressor response with the title '%s' already exists in the database. Please use a different title to avoid duplication.",
            title
          )
        ))
      }

      list(duplicate = FALSE, message = "")
    },
    error = function(e) {
      log_error("Title Duplicate Check", conditionMessage(e))
      list(
        duplicate = FALSE,
        message = sprintf("Could not verify title uniqueness: %s", conditionMessage(e))
      )
    }
  )
}

#' Check for Data Conflicts
#'
#' Checks if the same stressor-species-geography combination already exists
#'
#' @param stressor Stressor name(s)
#' @param species Species name(s)
#' @param geography Geography value(s)
#' @param db_conn Database connection
#'
#' @return List with $conflict (logical) and $message (character)
check_data_conflict <- function(stressor, species, geography, db_conn) {
  if (is.null(stressor) || is.null(species) || is.null(geography)) {
    return(list(conflict = FALSE, message = ""))
  }

  stressor_str <- paste(stressor, collapse = ", ")
  species_str <- paste(species, collapse = ", ")
  geography_str <- paste(geography, collapse = ", ")

  tryCatch(
    {
      similar <- dbGetQuery(db_conn,
        "SELECT title, stressor_name, species_common_name, geography
         FROM stressor_responses
         WHERE stressor_name = $1 AND species_common_name = $2 AND geography = $3
         LIMIT 5",
        params = list(stressor_str, species_str, geography_str)
      )

      if (nrow(similar) > 0) {
        titles <- paste(sprintf("• %s", similar$title), collapse = "\n")
        return(list(
          conflict = TRUE,
          message = sprintf(
            "Warning: The combination of stressor '%s', species '%s', and geography '%s' already exists in these records:\n\n%s\n\nYou can still proceed if this is a different study or updated data.",
            stressor_str, species_str, geography_str, titles
          )
        ))
      }

      list(conflict = FALSE, message = "")
    },
    error = function(e) {
      log_error("Data Conflict Check", conditionMessage(e))
      list(conflict = FALSE, message = "")
    }
  )
}

# nolint end
