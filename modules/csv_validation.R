# nolint start

# CSV Validation Functions for Stressor Response Data
# This module provides comprehensive validation for CSV uploads

# Define required columns for SR curve data
# Column structure (flexible naming for first 2, fixed for remainder):
#   1. Stressor numeric values (any name, e.g., "Stressor (X)")
#   2. Response numeric values (any name, e.g., "response.y.incubdays")
#   3. SD - standard deviation (can be NA)
#   4. lower.limit - lower confidence limit (can be NA)
#   5. high.limit - upper confidence limit (can be NA)
#   6. treatment.label - describes the stressor (e.g., "temperature")
#   7. treatment.value - treatment details (e.g., "constant")
#   8. response.label - describes the response variable (optional, e.g., "incubation days")
REQUIRED_FIXED_COLUMNS <- c("sd", "lower.limit", "high.limit", "treatment.label", "treatment.value")
OPTIONAL_COLUMNS <- c("response.label")
EXPECTED_COLUMN_COUNT <- 8

# Maximum file size in bytes (2 MB)
MAX_FILE_SIZE_BYTES <- 2 * 1024 * 1024

#' Validate CSV File Exists and is Readable
#'
#' @param file_input Shiny file input object
#'
#' @return List with $valid (logical) and $message (character)
validate_csv_file_exists <- function(file_input) {
  if (is.null(file_input)) {
    return(list(
      valid = FALSE,
      message = "No CSV file selected. Please upload a CSV file containing your SR curve data."
    ))
  }

  file_path <- file_input$datapath
  if (!file.exists(file_path)) {
    return(list(
      valid = FALSE,
      message = "File does not exist. Please try uploading again."
    ))
  }

  # Check file size
  file_size <- file.info(file_path)$size
  if (file_size > MAX_FILE_SIZE_BYTES) {
    return(list(
      valid = FALSE,
      message = sprintf(
        "File size (%.2f MB) exceeds the 2 MB limit. Please reduce the file size and try again.",
        file_size / (1024 * 1024)
      )
    ))
  }

  list(valid = TRUE, message = "")
}

#' Validate CSV Format and Structure
#'
#' @param file_input Shiny file input object
#'
#' @return List with $valid (logical), $message (character), $data (data.frame if valid), and $col_map (list)
validate_csv_format <- function(file_input) {
  file_check <- validate_csv_file_exists(file_input)
  if (!file_check$valid) {
    return(list(valid = FALSE, message = file_check$message, data = NULL, col_map = NULL))
  }

  # Try to read CSV
  tryCatch(
    {
      df <- read.csv(file_input$datapath, stringsAsFactors = FALSE, strip.white = TRUE)

      # Check if empty
      if (nrow(df) == 0) {
        return(list(
          valid = FALSE,
          message = "CSV file is empty. Please include at least one data row.",
          data = NULL,
          col_map = NULL
        ))
      }

      # Check column names
      col_check <- validate_csv_columns(df)
      if (!col_check$valid) {
        return(list(valid = FALSE, message = col_check$message, data = NULL, col_map = NULL))
      }

      list(valid = TRUE, message = "", data = df, col_map = col_check$col_map)
    },
    error = function(e) {
      list(
        valid = FALSE,
        message = sprintf(
          "Failed to read CSV file: %s. Ensure the file is a valid CSV format with proper encoding.",
          conditionMessage(e)
        ),
        data = NULL,
        col_map = NULL
      )
    }
  )
}

#' Validate CSV Column Names
#'
#' @param df Data frame from CSV
#'
#' @return List with $valid (logical) and $message (character), and $col_map (list mapping column positions)
validate_csv_columns <- function(df) {
  col_names <- tolower(trimws(colnames(df)))
  required_fixed_lower <- tolower(REQUIRED_FIXED_COLUMNS)
  optional_lower <- tolower(OPTIONAL_COLUMNS)

  # Check that we have at least the expected number of columns (7 required + 1 optional = 8)
  # but also allow fewer if response.label is missing
  if (length(col_names) < EXPECTED_COLUMN_COUNT - 1 || length(col_names) > EXPECTED_COLUMN_COUNT) {
    return(list(
      valid = FALSE,
      message = sprintf(
        "Expected %d or %d columns but found %d. Expected: 2 columns (any names for stressor/response) + 5 fixed columns (%s) + 1 optional (%s)",
        EXPECTED_COLUMN_COUNT - 1, EXPECTED_COLUMN_COUNT, length(col_names),
        paste(REQUIRED_FIXED_COLUMNS, collapse = ", "),
        paste(OPTIONAL_COLUMNS, collapse = ", ")
      ),
      col_map = NULL
    ))
  }

  # Check for the required fixed columns in positions 3-7
  actual_fixed <- col_names[3:7]
  missing_cols <- setdiff(required_fixed_lower, actual_fixed)
  if (length(missing_cols) > 0) {
    return(list(
      valid = FALSE,
      message = sprintf(
        "Missing required columns in positions 3-7: %s. Expected: %s",
        paste(missing_cols, collapse = ", "),
        paste(REQUIRED_FIXED_COLUMNS, collapse = ", ")
      ),
      col_map = NULL
    ))
  }

  # Check for optional response.label column in position 8
  has_response_label <- FALSE
  if (length(col_names) == EXPECTED_COLUMN_COUNT) {
    has_response_label <- col_names[8] %in% optional_lower
    if (!has_response_label) {
      return(list(
        valid = FALSE,
        message = sprintf(
          "Column 8 should be '%s' but found '%s'",
          OPTIONAL_COLUMNS[1], col_names[8]
        ),
        col_map = NULL
      ))
    }
  }

  # Create a column mapping for flexible access
  col_map <- list(
    stressor_col = col_names[1],
    response_col = col_names[2],
    sd_col = col_names[3],
    lower_limit_col = col_names[4],
    upper_limit_col = col_names[5],
    treatment_label_col = col_names[6],
    treatment_value_col = col_names[7],
    response_label_col = if (has_response_label) col_names[8] else NA
  )

  list(valid = TRUE, message = "", col_map = col_map)
}

#' Validate CSV Data Types and Values
#'
#' @param df Data frame from CSV
#' @param col_map List mapping column positions to names
#'
#' @return List with $valid (logical), $message (character), and $issues (list of specific issues)
validate_csv_data <- function(df, col_map) {
  issues <- list()
  col_names_lower <- tolower(trimws(colnames(df)))

  # Normalize column names to lowercase for processing
  df_normalized <- df
  colnames(df_normalized) <- col_names_lower

  # Use the column mapping to access the correct columns
  stressor_col_name <- col_map$stressor_col
  response_col_name <- col_map$response_col
  sd_col_name <- col_map$sd_col
  lower_limit_col_name <- col_map$lower_limit_col
  upper_limit_col_name <- col_map$upper_limit_col
  treatment_label_col_name <- col_map$treatment_label_col
  treatment_value_col_name <- col_map$treatment_value_col

  # Check stressor column (required, numeric)
  stressor_check <- validate_numeric_column(df_normalized[[stressor_col_name]], stressor_col_name)
  if (!stressor_check$valid) {
    issues <- c(issues, stressor_check$issues)
  }

  # Check response column (required, numeric)
  response_check <- validate_numeric_column(df_normalized[[response_col_name]], response_col_name)
  if (!response_check$valid) {
    issues <- c(issues, response_check$issues)
  }

  # Check sd column (optional - can be NA, numeric when present)
  sd_check <- validate_numeric_column(df_normalized[[sd_col_name]], sd_col_name, allow_zero = TRUE, allow_na = TRUE)
  if (!sd_check$valid) {
    issues <- c(issues, sd_check$issues)
  }

  # Check limit columns (optional - can be NA)
  limit_check <- validate_limit_columns(df_normalized, col_map)
  if (!limit_check$valid) {
    issues <- c(issues, limit_check$issues)
  }

  # Check treatment.label column (required, character/categorical)
  if (any(!is.na(df_normalized[[treatment_label_col_name]]) & df_normalized[[treatment_label_col_name]] == "")) {
    issues[[length(issues) + 1]] <- sprintf(
      "Column '%s' contains empty values",
      treatment_label_col_name
    )
  }

  # Check treatment.value column (required, character/categorical)
  if (any(!is.na(df_normalized[[treatment_value_col_name]]) & df_normalized[[treatment_value_col_name]] == "")) {
    issues[[length(issues) + 1]] <- sprintf(
      "Column '%s' contains empty values",
      treatment_value_col_name
    )
  }

  # Check for inconsistent response values
  response_range_check <- validate_response_range(df_normalized[[response_col_name]])
  if (!response_range_check$valid) {
    issues <- c(issues, response_range_check$issues)
  }

  # Check for duplicate stressor values
  dup_check <- check_duplicate_stressor_values(df_normalized[[stressor_col_name]])
  if (!dup_check$valid) {
    issues <- c(issues, dup_check$issues)
  }

  if (length(issues) > 0) {
    return(list(
      valid = FALSE,
      message = sprintf("Data validation failed with %d issue(s)", length(issues)),
      issues = issues
    ))
  }

  list(valid = TRUE, message = "", issues = list())
}

#' Validate Numeric Column
#'
#' @param col Vector to validate
#' @param col_name Column name for messaging
#' @param allow_zero Whether to allow zero values
#' @param allow_na Whether to allow NA/empty values
#'
#' @return List with $valid (logical) and $issues (list)
validate_numeric_column <- function(col, col_name, allow_zero = FALSE, allow_na = FALSE) {
  issues <- list()

  # Check for empty values
  empty_count <- sum(is.na(col) | col == "")
  if (empty_count > 0 && !allow_na) {
    issues[[length(issues) + 1]] <- sprintf(
      "Column '%s' has %d empty or missing values",
      col_name, empty_count
    )
  }

  # Try to convert to numeric
  suppressWarnings({
    numeric_col <- as.numeric(col)
  })

  # Check for non-numeric values (excluding NA if allow_na is TRUE)
  if (allow_na) {
    non_numeric_indices <- which(is.na(numeric_col) & !is.na(col) & col != "")
  } else {
    non_numeric_indices <- which(is.na(numeric_col) & !is.na(col))
  }

  if (length(non_numeric_indices) > 0) {
    non_numeric_values <- col[non_numeric_indices]
    issues[[length(issues) + 1]] <- sprintf(
      "Column '%s' contains non-numeric values: %s (rows %s)",
      col_name,
      paste(unique(non_numeric_values), collapse = ", "),
      paste(non_numeric_indices, collapse = ", ")
    )
  }

  list(valid = length(issues) == 0, issues = issues)
}

#' Validate Limit Columns (lower.limit and high.limit)
#'
#' @param df_normalized Data frame with lowercase column names
#' @param col_map List mapping column positions to names
#'
#' @return List with $valid (logical) and $issues (list)
validate_limit_columns <- function(df_normalized, col_map) {
  issues <- list()

  lower_limit_col_name <- col_map$lower_limit_col
  upper_limit_col_name <- col_map$upper_limit_col

  # Check lower.limit column (can be NA)
  lower_limit_check <- validate_numeric_column(df_normalized[[lower_limit_col_name]], lower_limit_col_name, allow_zero = TRUE, allow_na = TRUE)
  if (!lower_limit_check$valid) {
    issues <- c(issues, lower_limit_check$issues)
  }

  # Check high.limit column (can be NA)
  upper_limit_check <- validate_numeric_column(df_normalized[[upper_limit_col_name]], upper_limit_col_name, allow_zero = TRUE, allow_na = TRUE)
  if (!upper_limit_check$valid) {
    issues <- c(issues, upper_limit_check$issues)
  }

  # Check logical relationship: lower.limit <= high.limit (only when both are not NA)
  suppressWarnings({
    lower_limits <- as.numeric(df_normalized[[lower_limit_col_name]])
    upper_limits <- as.numeric(df_normalized[[upper_limit_col_name]])
  })

  invalid_limit_rows <- which(!is.na(lower_limits) & !is.na(upper_limits) & lower_limits > upper_limits)
  if (length(invalid_limit_rows) > 0) {
    issues[[length(issues) + 1]] <- sprintf(
      "%s exceeds %s in rows: %s",
      lower_limit_col_name, upper_limit_col_name, paste(invalid_limit_rows, collapse = ", ")
    )
  }

  list(valid = length(issues) == 0, issues = issues)
}

#' Validate Response Values are Within Reasonable Range
#'
#' @param response_col Response column values
#'
#' @return List with $valid (logical) and $issues (list)
validate_response_range <- function(response_col) {
  issues <- list()

  suppressWarnings({
    response_numeric <- as.numeric(response_col)
  })

  valid_responses <- response_numeric[!is.na(response_numeric)]

  if (length(valid_responses) == 0) {
    return(list(valid = FALSE, issues = list("No valid response values found")))
  }

  # Check if all values are the same
  if (length(unique(valid_responses)) == 1) {
    issues[[length(issues) + 1]] <- sprintf(
      "All response values are identical (%.2f). SR functions should show variation.",
      unique(valid_responses)[1]
    )
  }

  list(valid = length(issues) == 0, issues = issues)
}

#' Check for Duplicate Stressor Values
#'
#' @param stressor_col Stressor column values
#'
#' @return List with $valid (logical) and $issues (list)
check_duplicate_stressor_values <- function(stressor_col) {
  issues <- list()

  suppressWarnings({
    stressor_numeric <- as.numeric(stressor_col)
  })

  valid_stressors <- stressor_numeric[!is.na(stressor_numeric)]

  # Check for exact duplicates
  dup_values <- valid_stressors[duplicated(valid_stressors)]
  if (length(dup_values) > 0) {
    issues[[length(issues) + 1]] <- sprintf(
      "Duplicate stressor values found: %s",
      paste(unique(dup_values), collapse = ", ")
    )
  }

  # Check for near-duplicates (within 0.01 tolerance)
  if (length(valid_stressors) > 1) {
    sorted <- sort(valid_stressors)
    diffs <- diff(sorted)
    near_dups <- which(diffs < 0.01 & diffs > 0)
    if (length(near_dups) > 0) {
      issues[[length(issues) + 1]] <- sprintf(
        "Warning: Near-duplicate stressor values detected (difference < 0.01). These may affect curve fitting."
      )
    }
  }

  list(valid = length(issues) == 0, issues = issues)
}

#' Comprehensive CSV Validation
#'
#' @param file_input Shiny file input object
#'
#' @return List with $valid (logical), $message (character), $data (data.frame if valid), $col_map (list), and $all_issues (list)
validate_csv_upload <- function(file_input) {
  # Step 1: Check file exists and is readable
  file_check <- validate_csv_file_exists(file_input)
  if (!file_check$valid) {
    return(list(
      valid = FALSE,
      message = file_check$message,
      data = NULL,
      col_map = NULL,
      all_issues = list(file_check$message)
    ))
  }

  # Step 2: Check format and structure
  format_check <- validate_csv_format(file_input)
  if (!format_check$valid) {
    return(list(
      valid = FALSE,
      message = format_check$message,
      data = NULL,
      col_map = NULL,
      all_issues = list(format_check$message)
    ))
  }

  df <- format_check$data
  col_map <- format_check$col_map

  # Step 3: Validate data types and values
  data_check <- validate_csv_data(df, col_map)

  return(list(
    valid = data_check$valid,
    message = data_check$message,
    data = df,
    col_map = col_map,
    all_issues = data_check$issues
  ))
}

#' Format Validation Issues for Display
#'
#' @param issues List of issue strings
#'
#' @return Formatted HTML string for display
format_validation_issues <- function(issues) {
  if (length(issues) == 0) {
    return("")
  }

  issue_html <- paste(
    sprintf("<li>%s</li>", issues),
    collapse = "\n"
  )

  sprintf(
    "<div class='alert alert-warning'><strong>Validation Issues Found:</strong><ul>%s</ul></div>",
    issue_html
  )
}

# nolint end
